/// Represents a Flida user profile.
///
/// Contains user information retrieved from the Flida authentication service.
class FlidaUser {
  /// Creates a new [FlidaUser] instance.
  ///
  /// [id] is the unique user identifier.
  /// [name] is the user's display name.
  /// [email] is the user's email address (optional).
  /// [phoneNumber] is the user's phone number (optional).
  /// [rawData] contains the complete raw response from the server.
  FlidaUser({
    required this.id,
    required this.name,
    required this.rawData,
    this.email,
    this.phoneNumber,
  });

  /// Creates a [FlidaUser] from a map (typically from JSON).
  factory FlidaUser.fromMap(Map<String, dynamic> map) {
    return FlidaUser(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      rawData: map,
    );
  }

  /// The unique user identifier.
  final String id;

  /// The user's display name.
  final String name;

  /// The user's email address, if available.
  final String? email;

  /// The user's phone number, if available.
  final String? phoneNumber;

  /// The complete raw data from the server response.
  ///
  /// Use this to access any additional fields not explicitly defined.
  final Map<String, dynamic> rawData;
}

/// Represents authentication tokens from Flida.
///
/// Contains the access token for API calls and optionally a refresh token
/// for obtaining new access tokens.
class FlidaToken {
  /// Creates a new [FlidaToken] instance.
  ///
  /// [accessToken] is required for authenticating API requests.
  /// [refreshToken] can be used to obtain a new access token.
  /// [expiresIn] indicates how many seconds until the access token expires.
  FlidaToken({
    required this.accessToken,
    this.refreshToken,
    this.expiresIn,
  });

  /// Creates a [FlidaToken] from a map (typically from JSON).
  factory FlidaToken.fromMap(Map<String, dynamic> map) {
    return FlidaToken(
      accessToken: map['accessToken'] as String,
      refreshToken: map['refreshToken'] as String?,
      expiresIn: (map['expiresIn'] as num?)?.toInt(),
    );
  }

  /// The access token for authenticating API requests.
  ///
  /// This token is typically short-lived and should be refreshed
  /// using the [refreshToken] before it expires.
  final String accessToken;

  /// The refresh token for obtaining new access tokens.
  ///
  /// Use this with FlidaAuthSdk.refreshTokens to get a new
  /// access token without requiring the user to sign in again.
  final String? refreshToken;

  /// The number of seconds until the access token expires.
  ///
  /// May be null if the server doesn't provide this information.
  final int? expiresIn;
}

/// Represents an error from the Flida SDK.
///
/// Implements [Exception] so it can be thrown and caught.
class FlidaError implements Exception {
  /// Creates a new [FlidaError] instance.
  ///
  /// [code] is a machine-readable error code (e.g., 'sign_in_failed').
  /// [message] is a human-readable error description.
  /// [details] contains additional error information (optional).
  FlidaError({
    required this.code,
    required this.message,
    this.details,
  });

  /// A machine-readable error code.
  ///
  /// Common codes include:
  /// - `sign_in_failed` — Sign in process failed
  /// - `refresh_failed` — Token refresh failed
  /// - `user_info_failed` — Failed to fetch user info
  final String code;

  /// A human-readable error message.
  final String message;

  /// Additional error details, if available.
  ///
  /// May contain the original exception or additional context.
  final dynamic details;

  @override
  String toString() =>
      'FlidaError(code: $code, message: $message, details: $details)';
}
