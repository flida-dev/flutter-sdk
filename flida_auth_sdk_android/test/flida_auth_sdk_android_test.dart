import 'package:flida_auth_sdk_android/flida_auth_sdk_android.dart';
import 'package:flida_auth_sdk_platform_interface/flida_auth_sdk_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FlidaAuthSdkAndroid', () {
    const kPlatformName = 'Android';
    late FlidaAuthSdkAndroid flidaAuthSdk;
    late List<MethodCall> log;

    setUp(() async {
      flidaAuthSdk = FlidaAuthSdkAndroid();

      log = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(flidaAuthSdk.methodChannel, (
            methodCall,
          ) async {
            log.add(methodCall);
            switch (methodCall.method) {
              case 'getPlatformName':
                return kPlatformName;
              default:
                return null;
            }
          });
    });

    test('can be registered', () {
      FlidaAuthSdkAndroid.registerWith();
      expect(FlidaAuthSdkPlatform.instance, isA<FlidaAuthSdkAndroid>());
    });

    test('getPlatformName returns correct name', () async {
      final name = await flidaAuthSdk.getPlatformName();
      expect(
        log,
        <Matcher>[isMethodCall('getPlatformName', arguments: null)],
      );
      expect(name, equals(kPlatformName));
    });
  });
}
