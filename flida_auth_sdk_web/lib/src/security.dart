import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Security utilities for PKCE flow.
class Security {
  final _state = _CookieStorage('state');
  final _codeVerifier = _CookieStorage('code_verifier');

  /// Gets or generates the state parameter.
  String getState() => _state.retrieve();

  /// Gets or generates the code verifier.
  String getCodeVerifier() => _codeVerifier.retrieve();

  /// Generates the code challenge from the code verifier.
  String getCodeChallenge() {
    final verifier = getCodeVerifier();
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }

  /// Verifies and clears the state.
  void verifyAndClearState(String state) {
    final saved = _state.get();
    if (saved == null || saved.isEmpty) {
      throw Exception('Missing state');
    }
    if (saved != state) {
      throw Exception('Invalid state');
    }
    _state.clear();
  }

  /// Clears the code verifier.
  void clearCodeVerifier() => _codeVerifier.clear();
}

/// Simple in-memory storage (cookies not accessible from Dart on web).
class _CookieStorage {
  _CookieStorage(this.name);

  final String name;
  String? _value;

  String retrieve() {
    if (_value == null || _value!.isEmpty) {
      _value = _generateRandomString(48);
    }
    return _value!;
  }

  String? get() => _value;

  void clear() => _value = null;

  static String _generateRandomString(int length) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final buffer = StringBuffer();
    for (var i = 0; i < length; i++) {
      buffer.write(chars[DateTime.now().microsecondsSinceEpoch % chars.length]);
    }
    return buffer.toString();
  }
}
