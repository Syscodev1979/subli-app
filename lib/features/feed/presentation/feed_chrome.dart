import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A hírfolyam görgetése, amíg a kezdőoldal a képernyőn van.
class FeedChrome {
  Future<void> Function()? scrollToTopAndRefresh;
}

final feedChromeProvider = Provider<FeedChrome>((ref) => FeedChrome());
