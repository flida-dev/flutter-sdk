import 'dart:async';
import 'dart:developer' as dev;
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flida_auth_sdk_web/src/security.dart';
import 'package:web/web.dart' as web;

/// Response received from the authentication popup.
///
/// Contains the authorization code and state parameter returned
/// by the OAuth 2.0 authorization server.
class AuthResponse {
  /// Creates a new [AuthResponse] instance.
  ///
  /// [code] is the authorization code to exchange for tokens.
  /// [state] is the state parameter for CSRF protection verification.
  AuthResponse({required this.code, required this.state});

  /// The authorization code received from the server.
  ///
  /// This code should be exchanged for access and refresh tokens
  /// using the token endpoint.
  final String code;

  /// The state parameter for CSRF protection.
  ///
  /// This should match the state that was originally sent in the
  /// authorization request.
  final String state;
}

/// Handles popup-based OAuth 2.0 authentication flow.
///
/// Opens a popup window for user authentication and listens for
/// the authorization response via postMessage.
///
/// Example usage:
/// ```dart
/// final bridge = MessageBridge(security);
/// final response = await bridge.init('https://flida.dev/oauth?...');
/// print('Received code: ${response.code}');
/// ```
class MessageBridge {
  /// Creates a new [MessageBridge] instance.
  ///
  /// security is used to retrieve the expected state parameter
  /// for validating the response.
  MessageBridge(this._security);

  final Security _security;

  /// The expected origin for postMessage events.
  static const _idUrl = 'https://flida.dev';

  /// Opens a popup window and waits for the authentication response.
  ///
  /// [url] is the full authorization URL including query parameters.
  ///
  /// Returns an [AuthResponse] containing the authorization code and state.
  ///
  /// Throws an [Exception] if:
  /// - The popup fails to open (may be blocked by browser)
  /// - The user closes the popup before completing authentication
  /// - The authentication times out (10 minutes)
  Future<AuthResponse> init(String url) async {
    dev.log('Opening popup: $url', name: 'MessageBridge');

    // Open popup window centered on screen
    final popup = web.window.open(
      url,
      '_blank',
      'popup=true,width=500,height=600',
    );
    if (popup == null) {
      throw Exception('Failed to open popup');
    }

    final completer = Completer<AuthResponse>();
    final savedState = _security.getState();

    // Handler for postMessage events from the popup
    void onMessage(web.MessageEvent event) {
      dev.log('Received message from: ${event.origin}', name: 'MessageBridge');

      // Verify the message origin matches expected identity provider
      if (event.origin != _idUrl) return;

      final data = event.data;
      if (data == null) return;

      // Parse the message data
      final jsObject = data as JSObject;
      final action = (jsObject.getProperty('action'.toJS) as JSString?)?.toDart;

      // Verify the action matches expected format with our state
      if (action != 'oauth2_response_$savedState') return;

      final payload = jsObject.getProperty('payload'.toJS) as JSObject?;
      if (payload == null) return;

      // Extract authorization code and state from payload
      final code = (payload.getProperty('code'.toJS) as JSString?)?.toDart;
      final state = (payload.getProperty('state'.toJS) as JSString?)?.toDart;

      if (code != null && state != null) {
        dev.log('Received auth code: $code', name: 'MessageBridge');
        completer.complete(AuthResponse(code: code, state: state));
        popup.close();
      }
    }

    // Register message listener
    web.window.addEventListener(
      'message',
      onMessage.toJS,
    );

    // Monitor popup status - complete with error if user closes it
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (popup.closed) {
        timer.cancel();
        if (!completer.isCompleted) {
          completer.completeError(Exception('Popup closed by user'));
        }
      }
    });

    // Timeout after 10 minutes to prevent hanging
    Future.delayed(const Duration(minutes: 10), () {
      if (!completer.isCompleted) {
        popup.close();
        completer.completeError(Exception('Authentication timeout'));
      }
    });

    return completer.future;
  }
}
