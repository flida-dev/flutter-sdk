import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flida_auth_sdk_platform_interface/src/method_channel_flida_auth_sdk.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const kPlatformName = 'platformName';

  group('$MethodChannelFlidaAuthSdk', () {
    late MethodChannelFlidaAuthSdk methodChannelFlidaAuthSdk;
    final log = <MethodCall>[];

    setUp(() async {
      methodChannelFlidaAuthSdk = MethodChannelFlidaAuthSdk();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        methodChannelFlidaAuthSdk.methodChannel,
        (methodCall) async {
          log.add(methodCall);
          switch (methodCall.method) {
            case 'getPlatformName':
              return kPlatformName;
            default:
              return null;
          }
        },
      );
    });

    tearDown(log.clear);

    test('getPlatformName', () async {
      final platformName = await methodChannelFlidaAuthSdk.getPlatformName();
      expect(
        log,
        <Matcher>[isMethodCall('getPlatformName', arguments: null)],
      );
      expect(platformName, equals(kPlatformName));
    });
  });
}
