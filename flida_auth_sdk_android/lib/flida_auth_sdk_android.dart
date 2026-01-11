import 'package:flida_auth_sdk_platform_interface/flida_auth_sdk_platform_interface.dart';

/// The Android implementation of [FlidaAuthSdkPlatform].
/// The Android implementation of [FlidaAuthSdkPlatform].
class FlidaAuthSdkAndroid extends MethodChannelFlidaAuthSdk {
  /// Registers this class as the default instance of [FlidaAuthSdkPlatform]
  static void registerWith() {
    FlidaAuthSdkPlatform.instance = FlidaAuthSdkAndroid();
  }
}
