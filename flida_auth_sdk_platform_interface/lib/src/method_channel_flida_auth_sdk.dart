import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart';
import 'package:flida_auth_sdk_platform_interface/flida_auth_sdk_platform_interface.dart';

/// An implementation of [FlidaAuthSdkPlatform] that uses method channels.
class MethodChannelFlidaAuthSdk extends FlidaAuthSdkPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flida_auth_sdk');

  @override
  Future<String?> getPlatformName() {
    return methodChannel.invokeMethod<String>('getPlatformName');
  }
}
