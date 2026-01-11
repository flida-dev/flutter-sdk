import 'package:flida_auth_sdk_platform_interface/src/method_channel_flida_auth_sdk.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// {@template flida_auth_sdk_platform}
/// The interface that implementations of flida_auth_sdk must implement.
///
/// Platform implementations should extend this class
/// rather than implement it as `FlidaAuthSdk`.
///
/// Extending this class (using `extends`) ensures that the subclass will get
/// the default implementation, while platform implementations that `implements`
/// this interface will be broken by newly added [FlidaAuthSdkPlatform] methods.
/// {@endtemplate}
abstract class FlidaAuthSdkPlatform extends PlatformInterface {
  /// {@macro flida_auth_sdk_platform}
  FlidaAuthSdkPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlidaAuthSdkPlatform _instance = MethodChannelFlidaAuthSdk();

  /// The default instance of [FlidaAuthSdkPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlidaAuthSdk].
  static FlidaAuthSdkPlatform get instance => _instance;

  /// Platform-specific plugins should set this with their own platform-specific
  /// class that extends [FlidaAuthSdkPlatform] when they register themselves.
  static set instance(FlidaAuthSdkPlatform instance) {
    PlatformInterface.verify(instance, _token);
    _instance = instance;
  }

  /// Return the current platform name.
  Future<String?> getPlatformName();
}
