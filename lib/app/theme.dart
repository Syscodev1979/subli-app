import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'constants.dart';

/// Material 3 téma világos és sötét móddal.
///
/// A színséma a bordó magból készül, majd a klub fix színeire állítjuk,
/// hogy a generált árnyalatok ne írják felül a megadott értékeket.
/// Az AppBar mindkét módban bordó, fehér szöveggel.
abstract final class AppTheme {
  static ThemeData get light => _build(_lightScheme);

  static ThemeData get dark => _build(_darkScheme);

  static final ColorScheme _lightScheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.burgundy,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppColors.burgundy,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.burgundyLight,
        onPrimaryContainer: AppColors.burgundyDark,
        secondary: AppColors.accentGreen,
        onSecondary: AppColors.onPrimary,
        surface: AppColors.background,
        onSurface: AppColors.text,
      );

  static final ColorScheme _darkScheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.burgundyDarkMode,
        brightness: Brightness.dark,
      ).copyWith(
        primary: AppColors.burgundyDarkMode,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.burgundyDark,
        onPrimaryContainer: AppColors.burgundyLight,
        secondary: AppColors.accentGreen,
        onSecondary: AppColors.onPrimary,
      );

  static const AppBarTheme _appBarTheme = AppBarTheme(
    backgroundColor: AppColors.burgundy,
    foregroundColor: AppColors.onPrimary,
    elevation: 0,
    scrolledUnderElevation: 0,
    surfaceTintColor: Colors.transparent,
    centerTitle: false,
    systemOverlayStyle: SystemUiOverlayStyle.light,
    iconTheme: IconThemeData(color: AppColors.onPrimary),
    actionsIconTheme: IconThemeData(color: AppColors.onPrimary),
    titleTextStyle: TextStyle(
      color: AppColors.onPrimary,
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
  );

  static ThemeData _build(ColorScheme scheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: _appBarTheme,
    );
  }
}
