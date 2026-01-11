import 'package:flida_auth_sdk_platform_interface/flida_auth_sdk_platform_interface.dart';

/// The Web implementation of [FlidaAuthSdkPlatform].
class FlidaAuthSdkWeb extends FlidaAuthSdkPlatform {
  /// Registers this class as the default instance of [FlidaAuthSdkPlatform]
  static void registerWith([Object? registrar]) {
    FlidaAuthSdkPlatform.instance = FlidaAuthSdkWeb();
  }

  @override
  Future<String?> getPlatformName() async => 'Web';
}
