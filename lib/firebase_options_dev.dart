// Fejlesztői Firebase-beállítások (gastroyal-karate-dev).
// Amíg az apiKey REPLACE_ kezdetű, a dev flavor nem a éles projekthez csatlakozik.
// A flutterfire configure felülírja ezt a fájlt. A osztály neve maradjon
// DefaultFirebaseOptions.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        throw UnsupportedError(
          'A ${defaultTargetPlatform.name} platform nincs beállítva.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REPLACE_WITH_FLUTTERFIRE',
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'gastroyal-karate-dev',
    storageBucket: 'gastroyal-karate-dev.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_WITH_FLUTTERFIRE',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'gastroyal-karate-dev',
    storageBucket: 'gastroyal-karate-dev.firebasestorage.app',
    iosBundleId: 'hu.gastroyalkarate.app.dev',
  );
}
