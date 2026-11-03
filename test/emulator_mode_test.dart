import 'package:flutter_test/flutter_test.dart';
import 'package:subli_app/app/emulator.dart';

void main() {
  test('a fejlesztői helyettesítő kulcs emulátorra megy, az éles nem', () {
    expect(const bool.fromEnvironment('USE_EMULATOR'), isFalse);
    expect(
      emulatorModeFor(
        dartDefine: false,
        devFlavor: true,
        devApiKey: 'REPLACE_WITH_FLUTTERFIRE',
      ),
      isTrue,
    );
    expect(
      emulatorModeFor(
        dartDefine: false,
        devFlavor: false,
        devApiKey: 'REPLACE_WITH_FLUTTERFIRE',
      ),
      isFalse,
    );
    expect(
      emulatorModeFor(
        dartDefine: false,
        devFlavor: true,
        devApiKey: 'AIzaSyRealKeyNotAPlaceholder000000',
      ),
      isFalse,
    );
    expect(
      emulatorModeFor(
        dartDefine: true,
        devFlavor: false,
        devApiKey: 'AIzaSyRealKeyNotAPlaceholder000000',
      ),
      isTrue,
    );
    expect(useFirebaseEmulator, isTrue);
    final options = emulatorFirebaseOptions();
    expect(options.projectId, 'demo-subli');
    expect(options.apiKey, isNot(startsWith('REPLACE_')));
    expect(options.apiKey.length, 39);
    expect(options.apiKey, startsWith('A'));
    expect(options.appId, contains(':android:'));
  });
}
