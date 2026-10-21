import 'package:firebase_auth/firebase_auth.dart';

/// A Firebase hibakódok magyar szövege a felülethez.
String authErrorMessage(Object error) {
  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'invalid-email' => 'Érvénytelen e-mail-cím.',
      'user-disabled' => 'Ez a fiók le van tiltva.',
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' => 'Hibás e-mail-cím vagy jelszó.',
      'email-already-in-use' => 'Ezzel az e-mail-címmel már regisztráltak.',
      'weak-password' => 'A jelszó túl gyenge. Legalább 6 karakter legyen.',
      'too-many-requests' => 'Túl sok próbálkozás. Próbáld újra később.',
      'network-request-failed' => 'Nincs hálózati kapcsolat.',
      'operation-not-allowed' =>
        'Az e-mailes bejelentkezés nincs engedélyezve a Firebase-ben.',
      _ => 'A művelet nem sikerült. Próbáld újra.',
    };
  }
  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' => 'Nincs jogosultságod ehhez a művelethez.',
      'unavailable' => 'Nincs hálózati kapcsolat.',
      _ => 'Az adatok mentése nem sikerült. Próbáld újra.',
    };
  }
  return 'Váratlan hiba történt. Próbáld újra.';
}
