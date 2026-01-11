import 'package:flida_auth_sdk_platform_interface/flida_auth_sdk_platform_interface.dart';
import 'package:flida_auth_sdk_web/flida_auth_sdk_web.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FlidaAuthSdkWeb', () {
    const kPlatformName = 'Web';
    late FlidaAuthSdkWeb flidaAuthSdk;

    setUp(() async {
      flidaAuthSdk = FlidaAuthSdkWeb();
    });

    test('can be registered', () {
      FlidaAuthSdkWeb.registerWith(Registrar());
      expect(FlidaAuthSdkPlatform.instance, isA<FlidaAuthSdkWeb>());
    });

    test('getPlatformName returns correct name', () async {
      final name = await flidaAuthSdk.getPlatformName();
      expect(name, equals(kPlatformName));
    });
  });
}
