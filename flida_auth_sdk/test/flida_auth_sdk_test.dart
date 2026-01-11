import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flida_auth_sdk/flida_auth_sdk.dart';
import 'package:flida_auth_sdk_platform_interface/flida_auth_sdk_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlidaAuthSdkPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements FlidaAuthSdkPlatform {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group(FlidaAuthSdkPlatform, () {
    late FlidaAuthSdkPlatform flidaAuthSdkPlatform;

    setUp(() {
      flidaAuthSdkPlatform = MockFlidaAuthSdkPlatform();
      FlidaAuthSdkPlatform.instance = flidaAuthSdkPlatform;
    });

    group('getPlatformName', () {
      test('returns correct name when platform implementation exists',
          () async {
        const platformName = '__test_platform__';
        when(
          () => flidaAuthSdkPlatform.getPlatformName(),
        ).thenAnswer((_) async => platformName);

        final actualPlatformName = await getPlatformName();
        expect(actualPlatformName, equals(platformName));
      });

      test('throws exception when platform implementation is missing',
          () async {
        when(
          () => flidaAuthSdkPlatform.getPlatformName(),
        ).thenAnswer((_) async => null);

        expect(getPlatformName, throwsException);
      });
    });
  });
}
