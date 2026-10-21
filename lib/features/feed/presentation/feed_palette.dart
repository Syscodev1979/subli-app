import 'package:flutter/material.dart';

import '../../../app/constants.dart';

/// A hírfolyam felületi színei világos és sötét módban.
abstract final class FeedPalette {
  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color background(BuildContext context) {
    return isDark(context)
        ? AppColors.feedDarkBackground
        : AppColors.feedBackground;
  }

  static Color card(BuildContext context) {
    return isDark(context) ? AppColors.feedDarkCard : AppColors.feedCard;
  }

  static Color field(BuildContext context) {
    return isDark(context) ? AppColors.feedDarkField : AppColors.feedField;
  }

  static Color title(BuildContext context) {
    return isDark(context) ? AppColors.onPrimary : AppColors.text;
  }

  static Color muted(BuildContext context) {
    return isDark(context)
        ? AppColors.onPrimary.withValues(alpha: 0.65)
        : AppColors.feedMuted;
  }

  static Color divider(BuildContext context) {
    return isDark(context)
        ? AppColors.onPrimary.withValues(alpha: 0.12)
        : AppColors.appBarDivider;
  }
}
