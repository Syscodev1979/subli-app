// Éles Firebase-beállítások (gastroyal-karate).
// A flutterfire configure felülírhatja ezt a fájlt. A osztály neve maradjon
// DefaultFirebaseOptions, a main előtaggal importálja.
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
    apiKey: 'AIzaSyApFMD2liX5wTdaYxNXxXf8Ap49GA0ECXw',
    appId: '1:555040837330:android:59bed8fa5d3c434918e70b',
    messagingSenderId: '555040837330',
    projectId: 'gastroyal-karate',
    storageBucket: 'gastroyal-karate.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDyHM290hZrogKmgzTdxoj74MUHeek7VSI',
    appId: '1:555040837330:ios:58b7ba2a5807f47a18e70b',
    messagingSenderId: '555040837330',
    projectId: 'gastroyal-karate',
    storageBucket: 'gastroyal-karate.firebasestorage.app',
    iosBundleId: 'hu.gastroyalkarate.app',
  );
}
