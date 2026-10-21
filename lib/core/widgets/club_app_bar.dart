import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/constants.dart';
import '../../features/feed/presentation/feed_chrome.dart';
import 'club_logo.dart';

/// A klub neve és logója. Bárhonnan a hírfolyamra visz.
///
/// A hírfolyamon a lista tetejére görget, és frissít.
class ClubAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const ClubAppBar({this.leading, this.actions, super.key});

  final Widget? leading;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBar(
      automaticallyImplyLeading: false,
      leading: leading,
      titleSpacing: leading == null ? 16 : 0,
      title: InkWell(
        onTap: () => _openFeed(context, ref),
        borderRadius: BorderRadius.circular(8),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              ClubLogo(),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppInfo.clubName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: actions,
    );
  }

  Future<void> _openFeed(BuildContext context, WidgetRef ref) async {
    final onFeed = GoRouterState.of(context).matchedLocation == AppRoutes.feed;
    if (onFeed) {
      final scroll = ref.read(feedChromeProvider).scrollToTopAndRefresh;
      if (scroll != null) {
        await scroll();
        return;
      }
    }
    if (context.mounted) context.go(AppRoutes.feed);
  }
}
