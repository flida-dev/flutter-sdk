import 'package:flida_auth_sdk_platform_interface/flida_auth_sdk_platform_interface.dart';

FlidaAuthSdkPlatform get _platform => FlidaAuthSdkPlatform.instance;

/// Returns the name of the current platform.
Future<String> getPlatformName() async {
  final platformName = await _platform.getPlatformName();
  if (platformName == null) throw Exception('Unable to get platform name.');
  return platformName;
}
