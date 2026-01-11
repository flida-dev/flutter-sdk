import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flida_auth_sdk_ios/flida_auth_sdk_ios.dart';
import 'package:flida_auth_sdk_platform_interface/flida_auth_sdk_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FlidaAuthSdkIOS', () {
    const kPlatformName = 'iOS';
    late FlidaAuthSdkIOS flidaAuthSdk;
    late List<MethodCall> log;

    setUp(() async {
      flidaAuthSdk = FlidaAuthSdkIOS();

      log = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(flidaAuthSdk.methodChannel, (methodCall) async {
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
      FlidaAuthSdkIOS.registerWith();
      expect(FlidaAuthSdkPlatform.instance, isA<FlidaAuthSdkIOS>());
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
