import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Igaz, ha az appot `--dart-define=USE_EMULATOR=true` mellett indították.
///
/// A zászló nélkül az érték hamis, és a Firebase a korábbi úton indul.
const bool useFirebaseEmulator = bool.fromEnvironment('USE_EMULATOR');

/// Demo-projekt. Az emulátor nem ellenőrzi a kulcsot, a [projectId] a lényeg.
const FirebaseOptions emulatorFirebaseOptions = FirebaseOptions(
  apiKey: 'demo-api-key',
  appId: '1:123456789000:ios:demo',
  messagingSenderId: '123456789000',
  projectId: 'demo-subli',
  storageBucket: 'demo-subli.appspot.com',
  authDomain: 'demo-subli.firebaseapp.com',
);

/// A helyi emulátor portjai. Az iOS szimulátor a gép `localhost`-ját látja.
Future<void> connectFirebaseEmulators() async {
  await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  await FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
  FirebaseFunctions.instanceFor(region: 'europe-west3')
      .useFunctionsEmulator('localhost', 5001);
}
