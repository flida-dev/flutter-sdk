import 'dart:convert';
import 'dart:developer' as dev;

import 'package:http/http.dart' as http;

/// API client for Flida authentication endpoints.
class Api {
  /// Creates an API client with optional custom base URL.
  Api([String? baseUrl]) : _baseUrl = baseUrl ?? 'https://api.flida.dev';

  final String _baseUrl;

  Future<Map<String, dynamic>> _request(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    dev.log('API Request: $endpoint', name: 'Api');

    final response = await http.post(
      Uri.parse('$_baseUrl/$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      dev.log('API error: ${response.statusCode}', name: 'Api');
      throw Exception('Request failed: ${response.statusCode}');
    }

    final result = jsonDecode(response.body) as Map<String, dynamic>;
    dev.log('API Response: $result', name: 'Api');
    return result;
  }

  /// Issues a new token using the authorization code.
  Future<Map<String, dynamic>> issueToken({
    required String clientId,
    required String authorizationCode,
    required String codeVerifier,
    required String redirectUri,
  }) {
    return _request('flida.oauth.v1.TokenService/IssueToken', {
      'client_id': clientId,
      'authorization_code': authorizationCode,
      'code_verifier': codeVerifier,
      'redirect_uri': redirectUri,
    });
  }

  /// Refreshes an access token using a refresh token.
  Future<Map<String, dynamic>> refreshToken({
    required String clientId,
    required String refreshToken,
  }) {
    return _request('flida.oauth.v1.TokenService/RefreshToken', {
      'client_id': clientId,
      'client_secret': '',
      'refresh_token': refreshToken,
    });
  }

  /// Gets user information using an access token.
  Future<Map<String, dynamic>> getUserInfo({
    required String accessToken,
  }) {
    return _request('flida.oidc.v1.OIDCService/GetUserInfo', {
      'access_token': accessToken,
    });
  }
}
