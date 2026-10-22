import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastroyal_karate_app/app/club_colors.dart';
import 'package:gastroyal_karate_app/app/constants.dart';

void main() {
  test('a sötét módbeli szövegek elérik a WCAG AA kontrasztot', () {
    const dark = ClubColors.dark;
    final pairs = <(Color, Color)>[
      (dark.photo, dark.photoBackground),
      (dark.video, dark.videoBackground),
      (dark.camera, dark.cameraBackground),
      (dark.onGoldSurface, dark.goldSurface),
      (dark.gold, dark.sheet),
      (dark.onPublishDisabled, dark.publishDisabled),
      (dark.sheetMuted, dark.sheet),
      (AppColors.onPrimary, AppColors.gradientStart),
      (AppColors.onPrimary, AppColors.gradientMid),
      (AppColors.onPrimary, AppColors.gradientEnd),
    ];

    for (final (foreground, background) in pairs) {
      expect(
        contrastRatio(foreground, background),
        greaterThanOrEqualTo(4.5),
        reason: '$foreground on $background',
      );
    }
  });

  test('a világos arany címke és az inaktív gomb is olvasható', () {
    const light = ClubColors.light;
    expect(
      contrastRatio(light.onGoldSurface, light.goldSurface),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      contrastRatio(light.onPublishDisabled, light.publishDisabled),
      greaterThanOrEqualTo(4.5),
    );
  });
}

/// Két szín kontrasztaránya a WCAG 2 szerint.
double contrastRatio(Color foreground, Color background) {
  final lighter = math.max(luminance(foreground), luminance(background));
  final darker = math.min(luminance(foreground), luminance(background));
  return (lighter + 0.05) / (darker + 0.05);
}

double luminance(Color color) {
  return 0.2126 * _linear(color.r) +
      0.7152 * _linear(color.g) +
      0.0722 * _linear(color.b);
}

double _linear(double channel) {
  if (channel <= 0.04045) return channel / 12.92;
  return math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
}
