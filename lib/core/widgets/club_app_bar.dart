import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/club_config.dart';
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
  Size get preferredSize =>
      Size.fromHeight(ClubConfig.loginTitle == null ? kToolbarHeight : 72);

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

/// A fejléc klubneve. Ha van [ClubConfig.loginTitle], az látszik minden
/// szélességen. Különben 360 px alatt a rövid név, egyébként a teljes.
class ClubTitle extends StatelessWidget {
  const ClubTitle({super.key});

  static const double narrowWidth = 360;

  @override
  Widget build(BuildContext context) {
    final title = ClubConfig.loginTitle;
    if (title == null) {
      final narrow = MediaQuery.sizeOf(context).width < narrowWidth;
      final label = narrow ? AppInfo.clubNameShort : AppInfo.clubName;
      return FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(label, maxLines: 1, softWrap: false),
      );
    }
    final theme = Theme.of(context);
    final style = theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.bold,
      color: theme.colorScheme.onSurface,
      height: 1.15,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final oneLine = TextPainter(
          text: TextSpan(text: title, style: style),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout();
        final fits = oneLine.width <= constraints.maxWidth;
        final shown = fits ? title : _twoLines(title);
        var size = style?.fontSize ?? 22;
        if (!fits) {
          while (size > 14) {
            final trial = style?.copyWith(fontSize: size);
            final painter = TextPainter(
              text: TextSpan(text: shown, style: trial),
              maxLines: 2,
              textDirection: TextDirection.ltr,
            )..layout(maxWidth: constraints.maxWidth);
            if (!painter.didExceedMaxLines) break;
            size -= 1;
          }
          if (size < 14) size = 14;
        }
        return Text(
          shown,
          key: const Key('club-title'),
          maxLines: 2,
          softWrap: true,
          overflow: TextOverflow.visible,
          style: style?.copyWith(fontSize: fits ? style.fontSize : size),
        );
      },
    );
  }

  /// „Subli Lovas Közösségi App” → „Subli Lovas” / „Közösségi App”.
  static String _twoLines(String title) {
    const first = 'Subli Lovas ';
    if (title.startsWith(first)) {
      return 'Subli Lovas\n${title.substring(first.length)}';
    }
    final space = title.lastIndexOf(' ');
    if (space <= 0) return title;
    return '${title.substring(0, space)}\n${title.substring(space + 1)}';
  }
}
