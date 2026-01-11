import 'package:flida_auth_sdk_platform_interface/flida_auth_sdk_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

class FlidaAuthSdkMock extends FlidaAuthSdkPlatform {
  static const mockPlatformName = 'Mock';

  @override
  Future<String?> getPlatformName() async => mockPlatformName;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('FlidaAuthSdkPlatformInterface', () {
    late FlidaAuthSdkPlatform flidaAuthSdkPlatform;

    setUp(() {
      flidaAuthSdkPlatform = FlidaAuthSdkMock();
      FlidaAuthSdkPlatform.instance = flidaAuthSdkPlatform;
    });

    group('getPlatformName', () {
      test('returns correct name', () async {
        expect(
          await FlidaAuthSdkPlatform.instance.getPlatformName(),
          equals(FlidaAuthSdkMock.mockPlatformName),
        );
      });
    });
  });
}
