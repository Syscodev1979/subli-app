import 'package:flutter/material.dart';

/// A felhasználó témaválasztása.
///
/// A [system] a telefon beállítását követi, amíg nincs saját döntés,
/// és akkor is, ha a menüben ezt választják vissza.
enum ThemePreference {
  light('Világos'),
  dark('Sötét'),
  system('Rendszer szerint');

  const ThemePreference(this.label);

  final String label;

  ThemeMode get themeMode {
    return switch (this) {
      ThemePreference.light => ThemeMode.light,
      ThemePreference.dark => ThemeMode.dark,
      ThemePreference.system => ThemeMode.system,
    };
  }

  static ThemePreference fromStorage(String? raw) {
    return switch (raw) {
      'light' => ThemePreference.light,
      'dark' => ThemePreference.dark,
      'system' => ThemePreference.system,
      _ => ThemePreference.system,
    };
  }

  /// A kapcsoló felirata az éppen látható témához.
  static String semantics({required bool dark}) {
    return dark
        ? 'Téma: Sötét. Koppints a világos témához.'
        : 'Téma: Világos. Koppints a sötét témához.';
  }

  /// Alsó értesítés, miután a kapcsolóval váltott a felhasználó.
  static String snackBar({required bool dark}) {
    return dark ? '🌙 Sötét téma bekapcsolva' : '☀️ Világos téma bekapcsolva';
  }
}
