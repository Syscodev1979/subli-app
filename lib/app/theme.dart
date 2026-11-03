import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'club_colors.dart';
import 'constants.dart';

/// Material 3 téma világos és sötét móddal.
///
/// A színeket kézzel adjuk meg, nem [ColorScheme.fromSeed]-ből. A gombok a
/// [AppColors.primary] színt kapják, a sötét téma a [AppColors.brandRed]ot.
/// Az AppBar világos módban fehér, sötét módban a #121212 felület.
abstract final class AppTheme {
  static ThemeData get light =>
      _build(_lightScheme, _lightAppBar, ClubColors.light);

  static ThemeData get dark =>
      _build(_darkScheme, _darkAppBar, ClubColors.dark);

  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.onPrimaryContainer,
    secondary: AppColors.accentGreen,
    onSecondary: AppColors.onPrimary,
    error: AppColors.error,
    onError: AppColors.onPrimary,
    surface: AppColors.surface,
    onSurface: AppColors.text,
  );

  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.brandRed,
    onPrimary: AppColors.darkOnPrimary,
    primaryContainer: AppColors.onPrimaryContainer,
    onPrimaryContainer: AppColors.primaryContainer,
    secondary: AppColors.accentGreen,
    onSecondary: AppColors.onPrimary,
    error: AppColors.error,
    onError: AppColors.onPrimary,
    surface: AppColors.darkSurface,
    onSurface: AppColors.darkOnSurface,
  );

  /// Fehér fejléc, piros felirat és ikonok, alul egy halványszürke vonal.
  static const AppBarTheme _lightAppBar = AppBarTheme(
    backgroundColor: Color(0xFFFFFFFF),
    foregroundColor: AppColors.primary,
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
    iconTheme: IconThemeData(color: AppColors.primary),
    actionsIconTheme: IconThemeData(color: AppColors.primary),
    titleTextStyle: TextStyle(
      color: AppColors.primary,
      fontSize: 18,
      fontWeight: FontWeight.w700,
    ),
    shape: Border(bottom: BorderSide(color: AppColors.appBarDivider, width: 1)),
  );

  /// Sötét felület, a logó pirosával rajzolt felirat és ikonok.
  static const AppBarTheme _darkAppBar = AppBarTheme(
    backgroundColor: AppColors.darkSurface,
    foregroundColor: AppColors.brandRed,
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
    iconTheme: IconThemeData(color: AppColors.brandRed),
    actionsIconTheme: IconThemeData(color: AppColors.brandRed),
    titleTextStyle: TextStyle(
      color: AppColors.brandRed,
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
