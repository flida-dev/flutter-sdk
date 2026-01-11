import 'dart:async';
import 'dart:developer' as dev;

import 'package:flida_auth_sdk_platform_interface/flida_auth_sdk_platform_interface.dart';
import 'package:flida_auth_sdk_web/src/api.dart';
import 'package:flida_auth_sdk_web/src/message_bridge.dart';
import 'package:flida_auth_sdk_web/src/security.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:web/web.dart' as web;

/// The Web implementation of [FlidaAuthSdkPlatform].
///
/// Uses pure Dart implementation for authentication flow.
class FlidaAuthSdkWeb extends FlidaAuthSdkPlatform {
  /// Defines `FlidaAuthSdkWeb` as the platform implementation.
  static void registerWith(Registrar registrar) {
    FlidaAuthSdkPlatform.instance = FlidaAuthSdkWeb();
  }

  static const _accessTokenKey = 'flida_access_token';
  static const _refreshTokenKey = 'flida_refresh_token';

  Api? _api;
  Security? _security;
  MessageBridge? _messageBridge;
  String? _clientId;
  String? _apiEndpoint;

  @override
  Future<String?> getPlatformName() async => 'Web';

  /// Parses the flida-config meta tag in format "clientid.domain"
  void _parseConfig() {
    if (_clientId != null && _apiEndpoint != null) return;

    final meta = web.document.querySelector('meta[name="flida-config"]');
    if (meta == null) {
      throw Exception(
        'Flida config not found. Add <meta name="flida-config" '
        'content="clientid.domain"> to your index.html',
      );
    }

    final content = meta.getAttribute('content')!;
    final dotIndex = content.indexOf('.');
    if (dotIndex == -1) {
      throw Exception(
        'Invalid flida-config format. Expected "clientid.domain"',
      );
    }

    _clientId = content.substring(0, dotIndex);
    final domain = content.substring(dotIndex + 1);
    _apiEndpoint = 'https://api.$domain';
  }

  String get _requiredClientId {
    _parseConfig();
    return _clientId!;
  }

  String get _requiredApiEndpoint {
    _parseConfig();
    return _apiEndpoint!;
  }

  String get _requiredRedirectUri {
    final meta = web.document.querySelector('meta[name="flida-redirect-uri"]');
    if (meta != null) {
      return meta.getAttribute('content')!;
    }
    return '${web.window.location.protocol}//${web.window.location.host}/';
  }

  Api get _apiClient => _api ??= Api(_requiredApiEndpoint);
  Security get _securityClient => _security ??= Security();
  MessageBridge get _bridge =>
      _messageBridge ??= MessageBridge(_securityClient);

  final _eventsController = StreamController<FlidaEvent>.broadcast();

  @override
  Stream<FlidaEvent> get events => _eventsController.stream;

  @override
  Future<FlidaToken?> signIn({required List<String> scopes}) async {
    dev.log('Starting signIn with scopes: $scopes', name: 'FlidaAuthSdkWeb');

    try {
      final security = _securityClient;
      final state = security.getState();
      final codeChallenge = security.getCodeChallenge();
      final origin =
          '${web.window.location.protocol}//${web.window.location.host}';

      final params = {
        'client_id': _requiredClientId,
        'redirect_uri': _requiredRedirectUri,
        'scope': scopes.join(' '),
        'state': state,
        'code_challenge': codeChallenge,
        'response_type': 'code',
        'origin': origin,
      };

      final queryString = Uri(queryParameters: params).query;
      final authUrl = 'https://flida.dev/oauth?$queryString';

      // Open popup and wait for response
      final authResponse = await _bridge.init(authUrl);

      // Verify state
      security.verifyAndClearState(authResponse.state);

      // Exchange code for tokens
      final tokenResponse = await _apiClient.issueToken(
        clientId: _requiredClientId,
        authorizationCode: authResponse.code,
        codeVerifier: security.getCodeVerifier(),
        redirectUri: _requiredRedirectUri,
      );

      security.clearCodeVerifier();

      // Extract tokens (handle nested token object)
      final tokenData =
          tokenResponse['token'] as Map<String, dynamic>? ?? tokenResponse;
      final accessToken = tokenData['access_token'] as String;
      final refreshToken = tokenData['refresh_token'] as String;

      _saveTokens(accessToken, refreshToken);
      dev.log('Tokens saved successfully', name: 'FlidaAuthSdkWeb');

      final token = FlidaToken(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );

      _eventsController.add(
        FlidaEvent(type: FlidaEventType.signedIn, token: token),
      );

      return token;
    } catch (e) {
      dev.log('SignIn failed: $e', name: 'FlidaAuthSdkWeb', error: e);
      _eventsController.add(
        FlidaEvent(
          type: FlidaEventType.signInFailed,
          error: FlidaError(code: 'sign_in_failed', message: e.toString()),
        ),
      );
      throw Exception('SignIn failed: $e');
    }
  }

  @override
  Future<void> signOut() async {
    dev.log('Signing out', name: 'FlidaAuthSdkWeb');
    web.window.localStorage.removeItem(_accessTokenKey);
    web.window.localStorage.removeItem(_refreshTokenKey);

    _eventsController.add(
      FlidaEvent(
        type: FlidaEventType.loggedOut,
        logoutReason: FlidaLogoutReason.userInitiated,
      ),
    );
  }

  @override
  Future<FlidaToken?> loadToken() async {
    final access = web.window.localStorage.getItem(_accessTokenKey);
    final refresh = web.window.localStorage.getItem(_refreshTokenKey);

    if (access != null && refresh != null) {
      return FlidaToken(accessToken: access, refreshToken: refresh);
    }
    return null;
  }

  @override
  Future<FlidaToken?> refreshTokens({required String refreshToken}) async {
    dev.log('Refreshing tokens', name: 'FlidaAuthSdkWeb');

    try {
      final tokenResponse = await _apiClient.refreshToken(
        clientId: _requiredClientId,
        refreshToken: refreshToken,
      );

      final tokenData =
          tokenResponse['token'] as Map<String, dynamic>? ?? tokenResponse;
      final newAccess = tokenData['access_token'] as String;
      final newRefresh = tokenData['refresh_token'] as String;

      _saveTokens(newAccess, newRefresh);

      final token = FlidaToken(
        accessToken: newAccess,
        refreshToken: newRefresh,
      );

      _eventsController.add(
        FlidaEvent(type: FlidaEventType.tokensRefreshed, token: token),
      );

      return token;
    } catch (e) {
      dev.log('Token refresh failed: $e', name: 'FlidaAuthSdkWeb', error: e);
      _eventsController.add(
        FlidaEvent(
          type: FlidaEventType.tokenRefreshFailed,
          error: FlidaError(code: 'refresh_failed', message: e.toString()),
        ),
      );
      rethrow;
    }
  }

  @override
  Future<FlidaUser?> getUserInfo({required String accessToken}) async {
    dev.log('Getting user info', name: 'FlidaAuthSdkWeb');

    try {
      final userInfo = await _apiClient.getUserInfo(accessToken: accessToken);

      // API returns e_mail_addresses and phone_numbers as arrays
      final emailAddresses = userInfo['e_mail_addresses'] as List<dynamic>?;
      final phoneNumbers = userInfo['phone_numbers'] as List<dynamic>?;

      final user = FlidaUser(
        id: userInfo['id'] as String,
        name:
            userInfo['name'] as String? ??
            userInfo['display_name'] as String? ??
            '',
        email: emailAddresses?.isNotEmpty == true
            ? emailAddresses!.first as String
            : null,
        phoneNumber: phoneNumbers?.isNotEmpty == true
            ? phoneNumbers!.first as String
            : null,
        rawData: userInfo,
      );

      _eventsController.add(
        FlidaEvent(type: FlidaEventType.userInfoFetched, user: user),
      );

      return user;
    } catch (e) {
      dev.log('GetUserInfo failed: $e', name: 'FlidaAuthSdkWeb', error: e);
      _eventsController.add(
        FlidaEvent(
          type: FlidaEventType.userInfoFetchFailed,
          error: FlidaError(code: 'user_info_failed', message: e.toString()),
        ),
      );
      throw Exception('GetUserInfo failed: $e');
    }
  }

  void _saveTokens(String access, String refresh) {
    web.window.localStorage.setItem(_accessTokenKey, access);
    web.window.localStorage.setItem(_refreshTokenKey, refresh);
  }
}
