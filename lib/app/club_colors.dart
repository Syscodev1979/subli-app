import 'package:flutter/material.dart';

import 'constants.dart';

/// A szerkesztő és a hírfolyam sáv design tokenjei.
///
/// A világos értékek a megadott márkaszínek. A sötét változatok úgy vannak
/// megválasztva, hogy a felirat és a háttér kontrasztja elérje a WCAG AA
/// 4,5:1 arányt.
class ClubColors extends ThemeExtension<ClubColors> {
  const ClubColors({
    required this.gold,
    required this.goldSurface,
    required this.onGoldSurface,
    required this.photo,
    required this.photoBackground,
    required this.video,
    required this.videoBackground,
    required this.camera,
    required this.cameraBackground,
    required this.publishDisabled,
    required this.onPublishDisabled,
    required this.sheet,
    required this.sheetMuted,
    required this.publishGradient,
  });

  static const ClubColors light = ClubColors(
    gold: AppColors.gold,
    goldSurface: AppColors.goldLight,
    onGoldSurface: AppColors.burgundyDark,
    photo: AppColors.mediaPhoto,
    photoBackground: AppColors.mediaPhotoBackground,
    video: AppColors.mediaVideo,
    videoBackground: AppColors.mediaVideoBackground,
    camera: AppColors.mediaCamera,
    cameraBackground: AppColors.mediaCameraBackground,
    publishDisabled: AppColors.publishDisabled,
    onPublishDisabled: AppColors.onPublishDisabled,
    sheet: AppColors.feedCard,
    sheetMuted: AppColors.feedMuted,
    publishGradient: LinearGradient(
      colors: [
        AppColors.gradientStart,
        AppColors.gradientMid,
        AppColors.gradientEnd,
      ],
    ),
  );

  static const ClubColors dark = ClubColors(
    gold: AppColors.goldDark,
    goldSurface: AppColors.goldDarkSurface,
    onGoldSurface: AppColors.goldLight,
    photo: AppColors.mediaPhotoDark,
    photoBackground: AppColors.mediaPhotoDarkBackground,
    video: AppColors.mediaVideoDark,
    videoBackground: AppColors.mediaVideoDarkBackground,
    camera: AppColors.mediaCameraDark,
    cameraBackground: AppColors.mediaCameraDarkBackground,
    publishDisabled: AppColors.publishDisabledDark,
    onPublishDisabled: AppColors.onPublishDisabledDark,
    sheet: AppColors.feedDarkCard,
    sheetMuted: Color(0xFFC8C4C6),
    publishGradient: LinearGradient(
      colors: [
        AppColors.gradientStart,
        AppColors.gradientMid,
        AppColors.gradientEnd,
      ],
    ),
  );

  final Color gold;
  final Color goldSurface;
  final Color onGoldSurface;
  final Color photo;
  final Color photoBackground;
  final Color video;
  final Color videoBackground;
  final Color camera;
  final Color cameraBackground;
  final Color publishDisabled;
  final Color onPublishDisabled;
  final Color sheet;
  final Color sheetMuted;
  final LinearGradient publishGradient;

  static ClubColors of(BuildContext context) {
    return Theme.of(context).extension<ClubColors>() ??
        (Theme.of(context).brightness == Brightness.dark ? dark : light);
  }

  @override
  ClubColors copyWith({
    Color? gold,
    Color? goldSurface,
    Color? onGoldSurface,
    Color? photo,
    Color? photoBackground,
    Color? video,
    Color? videoBackground,
    Color? camera,
    Color? cameraBackground,
    Color? publishDisabled,
    Color? onPublishDisabled,
    Color? sheet,
    Color? sheetMuted,
    LinearGradient? publishGradient,
  }) {
    return ClubColors(
      gold: gold ?? this.gold,
      goldSurface: goldSurface ?? this.goldSurface,
      onGoldSurface: onGoldSurface ?? this.onGoldSurface,
      photo: photo ?? this.photo,
      photoBackground: photoBackground ?? this.photoBackground,
      video: video ?? this.video,
      videoBackground: videoBackground ?? this.videoBackground,
      camera: camera ?? this.camera,
      cameraBackground: cameraBackground ?? this.cameraBackground,
      publishDisabled: publishDisabled ?? this.publishDisabled,
      onPublishDisabled: onPublishDisabled ?? this.onPublishDisabled,
      sheet: sheet ?? this.sheet,
      sheetMuted: sheetMuted ?? this.sheetMuted,
      publishGradient: publishGradient ?? this.publishGradient,
    );
  }

  @override
  ClubColors lerp(ThemeExtension<ClubColors>? other, double t) {
    if (other is! ClubColors) return this;
    return ClubColors(
      gold: Color.lerp(gold, other.gold, t)!,
      goldSurface: Color.lerp(goldSurface, other.goldSurface, t)!,
      onGoldSurface: Color.lerp(onGoldSurface, other.onGoldSurface, t)!,
      photo: Color.lerp(photo, other.photo, t)!,
      photoBackground: Color.lerp(photoBackground, other.photoBackground, t)!,
      video: Color.lerp(video, other.video, t)!,
      videoBackground: Color.lerp(videoBackground, other.videoBackground, t)!,
      camera: Color.lerp(camera, other.camera, t)!,
      cameraBackground: Color.lerp(
        cameraBackground,
        other.cameraBackground,
        t,
      )!,
      publishDisabled: Color.lerp(publishDisabled, other.publishDisabled, t)!,
      onPublishDisabled: Color.lerp(
        onPublishDisabled,
        other.onPublishDisabled,
        t,
      )!,
      sheet: Color.lerp(sheet, other.sheet, t)!,
      sheetMuted: Color.lerp(sheetMuted, other.sheetMuted, t)!,
      publishGradient: LinearGradient(
        colors: [
          for (var i = 0; i < publishGradient.colors.length; i++)
            Color.lerp(
              publishGradient.colors[i],
              other.publishGradient.colors[i],
              t,
            )!,
        ],
      ),
    );
  }
}
