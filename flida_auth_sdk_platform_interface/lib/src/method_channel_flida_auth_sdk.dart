import 'package:flida_auth_sdk_platform_interface/flida_auth_sdk_platform_interface.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart';

/// An implementation of [FlidaAuthSdkPlatform] that uses method channels.
class MethodChannelFlidaAuthSdk extends FlidaAuthSdkPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flida_auth_sdk');

  /// The event channel used to receive events from the native platform.
  @visibleForTesting
  final eventChannel = const EventChannel('flida_auth_sdk/events');

  @override
  Future<String?> getPlatformName() {
    return methodChannel.invokeMethod<String>('getPlatformName');
  }

  @override
  Future<FlidaToken?> signIn({required List<String> scopes}) async {
    final result = await methodChannel.invokeMapMethod<String, dynamic>(
      'signIn',
      {'scopes': scopes},
    );
    if (result != null) {
      return FlidaToken.fromMap(result);
    }
    return null;
  }

  @override
  Future<void> signOut() async {
    await methodChannel.invokeMethod<void>('signOut');
  }

  @override
  Future<FlidaToken?> refreshTokens({required String refreshToken}) async {
    final result = await methodChannel.invokeMapMethod<String, dynamic>(
      'refreshTokens',
      {'refreshToken': refreshToken},
    );
    if (result != null) {
      return FlidaToken.fromMap(result);
    }
    return null;
  }

  @override
  Future<FlidaUser?> getUserInfo({required String accessToken}) async {
    final result = await methodChannel.invokeMapMethod<String, dynamic>(
      'getUserInfo',
      {'accessToken': accessToken},
    );
    if (result != null) {
      return FlidaUser.fromMap(result);
    }
    return null;
  }

  @override
  Future<FlidaToken?> loadToken() async {
    final result = await methodChannel.invokeMapMethod<String, dynamic>(
      'loadToken',
    );
    if (result != null) {
      return FlidaToken.fromMap(result);
    }
    return null;
  }

  @override
  Stream<FlidaEvent> get events {
    return eventChannel.receiveBroadcastStream().map((event) {
      return FlidaEvent.fromMap(Map<String, dynamic>.from(event as Map));
    });
  }
}
