import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flida_auth_sdk_platform_interface/flida_auth_sdk_platform_interface.dart';

/// The iOS implementation of [FlidaAuthSdkPlatform].
class FlidaAuthSdkIOS extends FlidaAuthSdkPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flida_auth_sdk_ios');

  /// Registers this class as the default instance of [FlidaAuthSdkPlatform]
  static void registerWith() {
    FlidaAuthSdkPlatform.instance = FlidaAuthSdkIOS();
  }

  @override
  Future<String?> getPlatformName() {
    return methodChannel.invokeMethod<String>('getPlatformName');
  }
}
