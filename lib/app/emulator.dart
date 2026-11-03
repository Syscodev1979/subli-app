import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase_options_dev.dart' as dev_options;
import 'app_flavor.dart';

/// A fejlesztői flavor helyettesítő kulccsal magától az emulátorra megy.
/// Az éles flavor a zászló nélkül a felhős beállítást használja.
bool emulatorModeFor({
  required bool dartDefine,
  required bool devFlavor,
  required String devApiKey,
}) {
  if (dartDefine) return true;
  if (!devFlavor) return false;
  return devApiKey.startsWith('REPLACE_');
}

bool get useFirebaseEmulator => emulatorModeFor(
  dartDefine: const bool.fromEnvironment('USE_EMULATOR'),
  devFlavor: AppFlavor.current.isDev,
  devApiKey: dev_options.DefaultFirebaseOptions.currentPlatform.apiKey,
);

/// A belépési oldalon, ha a helyi emulátor nem válaszol.
const emulatorOfflineMessage =
    'A helyi próbaszerver nem fut. Indítsd el: ./tool/run_dev.sh';

/// Igaz, ha az emulátor mód kellene, de a 4000-es port nem válaszol.
final emulatorOfflineProvider = Provider<bool>((ref) => false);

/// Az emulátor kezelőfelülete. Az iOS szimulátor a gép localhostját látja.
Future<bool> emulatorHubReachable() async {
  final client = HttpClient();
  try {
    final request = await client
        .getUrl(Uri.parse('http://127.0.0.1:4000/'))
        .timeout(const Duration(seconds: 2));
    final response = await request.close().timeout(const Duration(seconds: 2));
    await response.drain<void>();
    return response.statusCode >= 200 && response.statusCode < 500;
  } catch (_) {
    return false;
  } finally {
    client.close(force: true);
  }
}

/// Demo-projekt. Az emulátor nem ellenőrzi a kulcsot, a projectId a lényeg.
///
/// Az iOS Firebase a kulcs formáját mégis ellenőrzi: 39 karakter, `A` betűvel
/// kezdődik. Az alkalmazásazonosító hexadecimális, a bundle ID a futó flavoré.
/// A kulcs nem valódi, felhőbe nem mutat.
FirebaseOptions emulatorFirebaseOptions() {
  final ios = defaultTargetPlatform == TargetPlatform.iOS;
  return FirebaseOptions(
    apiKey: 'AIzaSyDEMOSubliLocalEmulatorKey00000000',
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
