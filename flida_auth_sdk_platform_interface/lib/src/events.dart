import 'package:flida_auth_sdk_platform_interface/src/types.dart';

/// Types of events emitted by the Flida Auth SDK.
enum FlidaEventType {
  /// Emitted when a user successfully signs in.
  signedIn,

  /// Emitted when a sign-in attempt fails.
  signInFailed,

  /// Emitted when tokens are successfully refreshed.
  tokensRefreshed,

  /// Emitted when a token refresh attempt fails.
  tokenRefreshFailed,

  /// Emitted when the user logs out.
  loggedOut,

  /// Emitted when user information is successfully fetched.
  userInfoFetched,

  /// Emitted when an attempt to fetch user information fails.
  userInfoFetchFailed,
}

/// Reasons for a user logout.
enum FlidaLogoutReason {
  /// The user initiated the logout.
  userInitiated,

  /// The session expired (e.g., refresh token is no longer valid).
  sessionExpired,

  /// The user is unauthorized (e.g., 401 error during an operation).
  unauthorized,
}

/// An event emitted by the Flida Auth SDK.
class FlidaEvent {
  /// Creates a new [FlidaEvent].
  FlidaEvent({
    required this.type,
    this.user,
    this.token,
    this.error,
    this.logoutReason,
  });

  /// Creates a [FlidaEvent] from a map.
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
          ? () {
              final errorMap = Map<String, dynamic>.from(map['error'] as Map);
              return FlidaError(
                code: errorMap['code'] as String,
                message: errorMap['message'] as String,
                details: errorMap['details'],
              );
            }()
          : null,
      logoutReason: logoutReason,
    );
  }

  /// The type of the event.
  final FlidaEventType type;

  /// The user associated with the event, if applicable (e.g., [FlidaEventType.signedIn], [FlidaEventType.userInfoFetched]).
  final FlidaUser? user;

  /// The token associated with the event, if applicable (e.g., [FlidaEventType.signedIn], [FlidaEventType.tokensRefreshed]).
  final FlidaToken? token;

  /// The error associated with the event, if applicable (e.g., [FlidaEventType.signInFailed], [FlidaEventType.tokenRefreshFailed]).
  final FlidaError? error;

  /// The reason for logout, if applicable (e.g., [FlidaEventType.loggedOut]).
  final FlidaLogoutReason? logoutReason;
}
