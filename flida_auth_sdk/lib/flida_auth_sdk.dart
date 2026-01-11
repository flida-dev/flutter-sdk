import 'package:flida_auth_sdk_platform_interface/flida_auth_sdk_platform_interface.dart';

export 'package:flida_auth_sdk_platform_interface/flida_auth_sdk_platform_interface.dart'
    show
        FlidaError,
        FlidaEvent,
        FlidaEventType,
        FlidaLogoutReason,
        FlidaToken,
        FlidaUser;

/// The entry point for the Flida Auth SDK.
///
/// This class provides static methods to interact with the authentication service,
/// including signing in, signing out, refreshing tokens, and retrieving user information.
class FlidaAuthSdk {
  static FlidaAuthSdkPlatform get _platform => FlidaAuthSdkPlatform.instance;

  /// Returns the name of the current platform.
  static Future<String?> getPlatformName() {
    return _platform.getPlatformName();
  }

  /// Initiates the sign-in process with the specified [scopes].
  ///
  /// Returns a [FlidaToken] if the sign-in is successful.
  static Future<FlidaToken?> signIn({required List<String> scopes}) {
    return _platform.signIn(scopes: scopes);
  }

  /// Signs out the current user.
  ///
  /// This clears the stored token and session.
  static Future<void> signOut() {
    return _platform.signOut();
  }

  /// Refreshes the access token using the provided [refreshToken].
  ///
  /// Returns a new [FlidaToken] if the refresh is successful, or throws a [FlidaError] if it fails.
  static Future<FlidaToken?> refreshTokens({required String refreshToken}) {
    return _platform.refreshTokens(refreshToken: refreshToken);
  }

  /// Fetches the user information using the provided [accessToken].
  ///
  /// Returns a [FlidaUser] if the request is successful.
  static Future<FlidaUser?> getUserInfo({required String accessToken}) {
    return _platform.getUserInfo(accessToken: accessToken);
  }

  /// Loads the stored token from the persistent storage.
  ///
  /// Returns the stored [FlidaToken] if available, or `null` if no token is stored.
  static Future<FlidaToken?> loadToken() {
    return _platform.loadToken();
  }

  /// A stream of [FlidaEvent]s emitted by the SDK.
  ///
  /// Listen to this stream to handle authentication events such as login success,
  /// token refresh, logout, and errors.
  static Stream<FlidaEvent> get events {
    return _platform.events;
  }
}
