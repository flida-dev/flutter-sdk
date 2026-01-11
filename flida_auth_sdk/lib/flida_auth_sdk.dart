import 'package:flida_auth_sdk_platform_interface/flida_auth_sdk_platform_interface.dart';

export 'package:flida_auth_sdk_platform_interface/flida_auth_sdk_platform_interface.dart'
    show
        FlidaToken,
        FlidaUser,
        FlidaEvent,
        FlidaEventType,
        FlidaError,
        FlidaLogoutReason;

class FlidaAuthSdk {
  static FlidaAuthSdkPlatform get _platform => FlidaAuthSdkPlatform.instance;

  static Future<String?> getPlatformName() {
    return _platform.getPlatformName();
  }

  static Future<FlidaToken?> signIn({required List<String> scopes}) {
    return _platform.signIn(scopes: scopes);
  }

  static Future<void> signOut() {
    return _platform.signOut();
  }

  static Future<FlidaToken?> refreshTokens({required String refreshToken}) {
    return _platform.refreshTokens(refreshToken: refreshToken);
  }

  static Future<FlidaUser?> getUserInfo({required String accessToken}) {
    return _platform.getUserInfo(accessToken: accessToken);
  }

  static Future<FlidaToken?> loadToken() {
    return _platform.loadToken();
  }

  static Stream<FlidaEvent> get events {
    return _platform.events;
  }
}
