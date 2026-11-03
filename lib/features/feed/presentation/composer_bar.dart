import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/club_colors.dart';
import '../../../app/constants.dart';
import '../../../core/utils/given_name.dart';
import '../../auth/domain/app_user.dart';
import 'author_avatar.dart';
import 'feed_palette.dart';
import 'post_editor_screen.dart';
import 'press_scale.dart';

/// A hírfolyam tetején lévő meghívó sáv.
class ComposerBar extends StatelessWidget {
  const ComposerBar({required this.user, super.key});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final colors = ClubColors.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final name = givenName(user.name);
    final prompt = name.isEmpty ? 'Mire gondolsz?' : 'Mire gondolsz, $name?';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: FeedPalette.card(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: dark ? 0.35 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              PressScale(
                onTap: () => context.push(AppRoutes.newPost),
                child: Row(
                  children: [
                    _GoldRing(
                      child: AuthorAvatar(
                        name: user.name,
                        photoUrl: user.photoUrl,
                        radius: 22,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: FeedPalette.field(context),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Text(
                            prompt,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: FeedPalette.muted(context),
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _QuickButton(
                      label: 'Fotó',
                      icon: Icons.photo_outlined,
                      foreground: colors.photo,
                      background: colors.photoBackground,
                      launch: ComposerLaunch.photo,
                    ),
                    const SizedBox(width: 8),
                    _QuickButton(
                      label: 'Videó',
                      icon: Icons.videocam_outlined,
                      foreground: colors.video,
                      background: colors.videoBackground,
                      launch: ComposerLaunch.video,
                    ),
                    const SizedBox(width: 8),
                    _QuickButton(
                      label: 'Dokumentum',
                      icon: Icons.description_outlined,
                      foreground: colors.gold,
                      background: colors.goldSurface,
                      labelColor: colors.onGoldSurface,
                      launch: ComposerLaunch.document,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.push(AppRoutes.newPost),
                  child: const Text('+ Új bejegyzés'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoldRing extends StatelessWidget {
  const _GoldRing({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ClubColors.of(context).gold, width: 1.5),
      ),
      child: child,
    );
  }
}

class _QuickButton extends StatelessWidget {
  const _QuickButton({
    required this.label,
    required this.icon,
    required this.foreground,
    required this.background,
    required this.launch,
    this.labelColor,
  });

  final String label;
  final IconData icon;
  final Color foreground;
  final Color background;
  final Color? labelColor;
  final ComposerLaunch launch;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: () {
        final media = switch (launch) {
          ComposerLaunch.photo => 'photo',
          ComposerLaunch.video => 'video',
          ComposerLaunch.document => 'document',
        };
        context.push('${AppRoutes.newPost}?media=$media');
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: foreground, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  color: labelColor ?? foreground,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
