import 'types.dart';

enum FlidaEventType {
  signedIn,
  signInFailed,
  tokensRefreshed,
  tokenRefreshFailed,
  loggedOut,
  userInfoFetched,
  userInfoFetchFailed,
}

enum FlidaLogoutReason {
  userInitiated,
  sessionExpired,
  unauthorized,
}

class FlidaEvent {
  final FlidaEventType type;
  final FlidaUser? user;
  final FlidaToken? token;
  final FlidaError? error;
  final FlidaLogoutReason? logoutReason;

  FlidaEvent({
    required this.type,
    this.user,
    this.token,
    this.error,
    this.logoutReason,
  });

  factory FlidaEvent.fromMap(Map<String, dynamic> map) {
    final typeStr = map['type'] as String;
    final type = FlidaEventType.values.firstWhere(
      (e) => e.toString().split('.').last == typeStr,
      orElse: () => throw Exception('Unknown event type: $typeStr'),
    );

    FlidaLogoutReason? logoutReason;
    if (map['logoutReason'] != null) {
      final reasonStr = map['logoutReason'] as String;
      logoutReason = FlidaLogoutReason.values.firstWhere(
        (e) => e.toString().split('.').last == reasonStr,
      );
    }

    return FlidaEvent(
      type: type,
      user: map['user'] != null
          ? FlidaUser.fromMap(Map<String, dynamic>.from(map['user'] as Map))
          : null,
      token: map['token'] != null
          ? FlidaToken.fromMap(Map<String, dynamic>.from(map['token'] as Map))
          : null,
      error: map['error'] != null
          ? FlidaError(
              code: map['error']['code'] as String,
              message: map['error']['message'] as String,
              details: map['error']['details'],
            )
          : null,
      logoutReason: logoutReason,
    );
  }
}
