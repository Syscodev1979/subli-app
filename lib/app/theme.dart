import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'club_colors.dart';
import 'constants.dart';

/// Material 3 téma világos és sötét móddal.
///
/// A gombok és kiemelések bordók maradnak, a másodlagos szín a zöld pipáé.
/// Az AppBar világos módban fehér, sötét módban a sötét felület.
abstract final class AppTheme {
  static ThemeData get light =>
      _build(_lightScheme, _lightAppBar, ClubColors.light);

  static ThemeData get dark => _build(_darkScheme, _darkAppBar, ClubColors.dark);

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
        surface: AppColors.darkSurface,
      );

  /// Fehér fejléc, sötét bordó felirat és ikonok, alul egy halványszürke vonal.
  static const AppBarTheme _lightAppBar = AppBarTheme(
    backgroundColor: Color(0xFFFFFFFF),
    foregroundColor: AppColors.burgundy,
    elevation: 0,
    scrolledUnderElevation: 0,
    surfaceTintColor: Colors.transparent,
    shadowColor: Colors.transparent,
    centerTitle: false,
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
    iconTheme: IconThemeData(color: AppColors.burgundy),
    actionsIconTheme: IconThemeData(color: AppColors.burgundy),
    titleTextStyle: TextStyle(
      color: AppColors.burgundy,
      fontSize: 18,
      fontWeight: FontWeight.w700,
    ),
    shape: Border(bottom: BorderSide(color: AppColors.appBarDivider, width: 1)),
  );

  /// Sötét felület, rózsaszínes bordó felirat és ikonok.
  static const AppBarTheme _darkAppBar = AppBarTheme(
    backgroundColor: AppColors.darkSurface,
    foregroundColor: AppColors.burgundyDarkMode,
    elevation: 0,
    scrolledUnderElevation: 0,
    surfaceTintColor: Colors.transparent,
    shadowColor: Colors.transparent,
    centerTitle: false,
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
    iconTheme: IconThemeData(color: AppColors.burgundyDarkMode),
    actionsIconTheme: IconThemeData(color: AppColors.burgundyDarkMode),
    titleTextStyle: TextStyle(
      color: AppColors.burgundyDarkMode,
      fontSize: 18,
      fontWeight: FontWeight.w700,
    ),
  );

  static ThemeData _build(
    ColorScheme scheme,
    AppBarTheme appBarTheme,
    ClubColors colors,
  ) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: appBarTheme,
      extensions: [colors],
    );
  }
}
