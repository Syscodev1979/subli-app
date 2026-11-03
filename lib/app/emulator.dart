import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import 'app_flavor.dart';

/// Igaz, ha az appot `--dart-define=USE_EMULATOR=true` mellett indították.
///
/// A zászló nélkül az érték hamis, és a Firebase a korábbi úton indul.
const bool useFirebaseEmulator = bool.fromEnvironment('USE_EMULATOR');

/// Demo-projekt. Az emulátor nem ellenőrzi a kulcsot, a projectId a lényeg.
///
/// Az iOS Firebase elutasítja a nem hexadecimális alkalmazásazonosítót, ezért
/// a helyettesítő azonosító hex, a bundle ID pedig a futó flavoré.
FirebaseOptions emulatorFirebaseOptions() {
  final ios = defaultTargetPlatform == TargetPlatform.iOS;
  return FirebaseOptions(
    apiKey: 'demo-api-key',
    appId: ios
        ? '1:123456789000:ios:0123456789abcdef'
        : '1:123456789000:android:0123456789abcdef',
    messagingSenderId: '123456789000',
    projectId: 'demo-subli',
    storageBucket: 'demo-subli.appspot.com',
    authDomain: 'demo-subli.firebaseapp.com',
    iosBundleId: AppFlavor.current.applicationId,
  );
}

/// A helyi emulátor portjai. Az iOS szimulátor a gép `localhost`-ját látja.
Future<void> connectFirebaseEmulators() async {
  await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  await FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
  FirebaseFunctions.instanceFor(region: 'europe-west3')
      .useFunctionsEmulator('localhost', 5001);
}
