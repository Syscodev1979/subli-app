import 'package:flutter_test/flutter_test.dart';
import 'package:subli_app/app/emulator.dart';

void main() {
  test('az emulátor mód alapból ki van kapcsolva', () {
    expect(useFirebaseEmulator, isFalse);
    expect(emulatorFirebaseOptions.projectId, 'demo-subli');
    expect(emulatorFirebaseOptions.apiKey, isNot(startsWith('REPLACE_')));
  });
}
