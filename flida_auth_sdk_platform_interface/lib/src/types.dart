class FlidaUser {
  final String id;
  final String name;
  final String? email;
  final String? phoneNumber;
  final Map<String, dynamic> rawData;

  FlidaUser({
    required this.id,
    required this.name,
    this.email,
    this.phoneNumber,
    required this.rawData,
  });

  factory FlidaUser.fromMap(Map<String, dynamic> map) {
    return FlidaUser(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      rawData: map,
    );
  }
}

class FlidaToken {
  final String accessToken;
  final String? refreshToken;
  final int? expiresIn;

  FlidaToken({
    required this.accessToken,
    this.refreshToken,
    this.expiresIn,
  });

  factory FlidaToken.fromMap(Map<String, dynamic> map) {
    return FlidaToken(
      accessToken: map['accessToken'] as String,
      refreshToken: map['refreshToken'] as String?,
      expiresIn: map['expiresIn'] as int?,
    );
  }
}

class FlidaError implements Exception {
  final String code;
  final String message;
  final dynamic details;

  FlidaError({
    required this.code,
    required this.message,
    this.details,
  });

  @override
  String toString() =>
      'FlidaError(code: $code, message: $message, details: $details)';
}
