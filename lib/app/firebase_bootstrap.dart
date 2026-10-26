import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options_dev.dart' as dev_options;
import '../firebase_options_prod.dart' as prod_options;
import 'app_flavor.dart';

/// A flavorhoz tartozó Firebase-beállítások. Hamis, ha a dev projekt még nincs
/// összekötve, és ilyenkor az app nem az éles adatbázishoz csatlakozik.
FirebaseOptions? firebaseOptionsForCurrentFlavor() {
  final options = switch (AppFlavor.current) {
    AppFlavor.prod => prod_options.DefaultFirebaseOptions.currentPlatform,
    AppFlavor.dev => dev_options.DefaultFirebaseOptions.currentPlatform,
  };
  if (options.apiKey.startsWith('REPLACE_')) return null;
  return options;
}

/// Debug módban nem küld jelentést, és csak a felhasználó azonosítóját tárolja.
Future<void> startCrashReporting() async {
  final crashlytics = FirebaseCrashlytics.instance;
  await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (kDebugMode) return;
    crashlytics.recordFlutterFatalError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    if (!kDebugMode) {
      crashlytics.recordError(error, stack, fatal: true);
    }
    return true;
  };
}

Future<void> setCrashlyticsUser(String? uid) async {
  await FirebaseCrashlytics.instance.setUserIdentifier(uid ?? '');
}
