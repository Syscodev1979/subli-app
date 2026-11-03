import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/club_config.dart';

/// Az áruház, ahol ez a készülék frissíteni tud.
Uri storeListingUri() {
  if (!kIsWeb && Platform.isIOS) return Uri.parse(ClubConfig.appStoreUrl);
  return Uri.parse(ClubConfig.playStoreUrl);
}

Future<void> openExternal(String url) {
  return launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}

Future<void> openStoreListing() => openExternal(storeListingUri().toString());
