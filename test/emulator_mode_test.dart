import 'package:flutter_test/flutter_test.dart';
import 'package:subli_app/app/emulator.dart';

void main() {
  test('az emulátor mód alapból ki van kapcsolva', () {
    expect(useFirebaseEmulator, isFalse);
    final options = emulatorFirebaseOptions();
    expect(options.projectId, 'demo-subli');
    expect(options.apiKey, isNot(startsWith('REPLACE_')));
    expect(options.apiKey.length, 39);
    expect(options.apiKey, startsWith('A'));
    expect(options.appId, contains(':android:'));
  });
}
