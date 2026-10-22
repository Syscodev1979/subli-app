import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme_preference.dart';

/// A témaválasztás a készüléken.
///
/// Az első indítás a rendszert követi. A saját választás a következő
/// indításkor is megmarad.
final themePreferenceProvider =
    NotifierProvider<ThemeController, ThemePreference>(ThemeController.new);

class ThemeController extends Notifier<ThemePreference> {
  ThemeController({
    this.initial = ThemePreference.system,
    this.preloaded = false,
  });

  static const storageKey = 'theme_preference';

  final ThemePreference initial;
  final bool preloaded;
  var _touched = false;

  @override
  ThemePreference build() {
    if (!preloaded) unawaited(_hydrate());
    return initial;
  }

  Future<void> select(ThemePreference preference) async {
    _touched = true;
    state = preference;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, preference.name);
  }

  Future<void> _hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    if (!ref.mounted || _touched) return;
    state = ThemePreference.fromStorage(prefs.getString(storageKey));
  }
}
