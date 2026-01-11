import 'package:flida_auth_sdk_platform_interface/flida_auth_sdk_platform_interface.dart';

/// The iOS implementation of [FlidaAuthSdkPlatform].
/// The iOS implementation of [FlidaAuthSdkPlatform].
class FlidaAuthSdkIOS extends MethodChannelFlidaAuthSdk {
  /// Registers this class as the default instance of [FlidaAuthSdkPlatform]
  static void registerWith() {
    FlidaAuthSdkPlatform.instance = FlidaAuthSdkIOS();
  }
}
