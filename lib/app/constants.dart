import 'package:flutter/material.dart';

/// A Gastroyal Karate SE márkaszínei.
///
/// Világos módban a fő szín a [burgundy], sötét módban a [burgundyDarkMode].
/// A [accentGreen] később a lájk helyetti pipa színe lesz.
abstract final class AppColors {
  /// Fő bordó.
  static const Color burgundy = Color(0xFF6B1E2E);

  /// Sötétebb bordó, kiemeléshez és sötét felületekhez.
  static const Color burgundyDark = Color(0xFF4A121E);

  /// Világos bordó felület, például a logó helye mögött.
  static const Color burgundyLight = Color(0xFFF3E6E9);

  /// Fő szín sötét módban.
  static const Color burgundyDarkMode = Color(0xFFC4566B);

  /// Kiegészítő zöld.
  static const Color accentGreen = Color(0xFF2E7D32);

  /// Világos mód háttere.
  static const Color background = Color(0xFFFAFAFA);

  /// Világos mód szövegszíne, egyben a sötét felület színe.
  static const Color text = Color(0xFF1C1B1F);

  /// Sötét mód felülete és AppBar háttere.
  static const Color darkSurface = Color(0xFF1C1B1F);

  /// Világos AppBar alatti elválasztó vonal.
  static const Color appBarDivider = Color(0xFFE6E0E2);

  /// Szöveg és ikon a bordó felületeken.
  static const Color onPrimary = Color(0xFFFFFFFF);
}

/// Az app útvonalai.
abstract final class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String pending = '/pending';
  static const String feed = '/feed';
  static const String chat = '/chat';
  static const String profile = '/profile';
  static const String calendar = '/calendar';
  static const String admin = '/admin';
}

/// Közös, a felületen megjelenő nevek.
abstract final class AppInfo {
  static const String clubName = 'Gastroyal Karate SE';
}
