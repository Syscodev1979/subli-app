import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/constants.dart';
import '../../features/feed/presentation/feed_chrome.dart';
import 'club_logo.dart';
import 'theme_switch.dart';

/// A klub neve és logója. Bárhonnan a hírfolyamra visz.
///
/// A hírfolyamon a lista tetejére görget, és frissít.
class ClubAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const ClubAppBar({this.leading, this.title, this.actions, super.key});

  final Widget? leading;

  /// Ha megvan, a logó és a klubnév helyére kerül.
  final Widget? title;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RepaintBoundary(
      key: const Key('club-app-bar'),
      child: AppBar(
        automaticallyImplyLeading: false,
        leading: leading,
        titleSpacing: leading == null ? 16 : 0,
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child:
              title ??
              InkWell(
                key: const ValueKey('club-brand'),
                onTap: () => _openFeed(context, ref),
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      ClubLogo(),
                      SizedBox(width: 12),
                      Expanded(child: ClubTitle()),
                    ],
                  ),
                ),
              ),
        ),
        actions: [
          const Padding(
            padding: EdgeInsets.only(right: 4),
            child: ThemeSwitch(),
          ),
          ...?actions,
        ],
      ),
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

/// A fejléc klubneve. 360 px alatt a rövid név, egyébként a teljes.
class ClubTitle extends StatelessWidget {
  const ClubTitle({super.key});

  static const double narrowWidth = 360;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < narrowWidth;
    final label = narrow ? AppInfo.clubNameShort : AppInfo.clubName;
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(label, maxLines: 1, softWrap: false),
    );
  }
}
