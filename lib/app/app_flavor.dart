import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'club_config.dart';

/// A futó változat. A `flutter run --flavor` állítja a [appFlavor] értékét.
enum AppFlavor {
  dev,
  prod;

  static AppFlavor get current {
    return switch (appFlavor) {
      'prod' => AppFlavor.prod,
      'dev' => AppFlavor.dev,
      _ when kReleaseMode => AppFlavor.prod,
      _ => AppFlavor.dev,
    };
  }

  String get applicationId => switch (this) {
    AppFlavor.dev => ClubConfig.devApplicationId,
    AppFlavor.prod => ClubConfig.prodApplicationId,
  };

  String get appName => switch (this) {
    AppFlavor.dev => ClubConfig.devAppName,
    AppFlavor.prod => ClubConfig.prodAppName,
  };

  bool get isDev => this == AppFlavor.dev;
}
