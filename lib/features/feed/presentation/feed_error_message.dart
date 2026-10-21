import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// A hírfolyam műveleteinek magyar hibaszövege.
///
/// A Firebase-hibakód debug módban a konzolra kerül.
String feedErrorMessage(Object error, {required bool saving}) {
  if (kDebugMode) {
    if (error is FirebaseException) {
      debugPrint('Firebase hiba: ${error.code}');
    } else {
      debugPrint('Firebase hiba: $error');
    }
  }
  if (error is FirebaseException && error.code == 'permission-denied') {
    return 'Ehhez nincs jogosultságod.';
  }
  if (saving) return 'Nem sikerült menteni.';
  return 'Nem sikerült betölteni a hírfolyamot.';
}
