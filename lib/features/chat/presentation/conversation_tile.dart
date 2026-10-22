import 'package:flutter/material.dart';

import '../../../app/constants.dart';
import '../../feed/presentation/author_avatar.dart';
import '../../profile/presentation/profile_navigation.dart';
import '../../feed/presentation/feed_palette.dart';
import '../domain/club_member.dart';

/// Egy sor a beszélgetéslistában.
class ConversationTile extends StatelessWidget {
  const ConversationTile({
    required this.title,
    required this.preview,
    required this.timeLabel,
    required this.unread,
    required this.people,
    required this.onTap,
    super.key,
  });

  final String title;
  final String preview;
  final String timeLabel;
  final bool unread;
  final List<ClubMember> people;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final titleColor = FeedPalette.title(context);
    final muted = FeedPalette.muted(context);
    final weight = unread ? FontWeight.w800 : FontWeight.w600;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _Avatars(people: people),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: titleColor,
                      fontWeight: weight,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: unread ? titleColor : muted,
                      fontWeight: unread ? FontWeight.w700 : FontWeight.w400,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(timeLabel, style: TextStyle(color: muted, fontSize: 12)),
                if (unread) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.burgundy,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatars extends StatelessWidget {
  const _Avatars({required this.people});

  final List<ClubMember> people;

  @override
  Widget build(BuildContext context) {
    if (people.length <= 1) {
      final person = people.isEmpty ? null : people.first;
      final id = person?.id;
      final avatar = AuthorAvatar(
        name: person?.name ?? '?',
        photoUrl: person?.photoUrl,
        radius: 26,
      );
      if (id == null) return avatar;
      return ProfileTap(userId: id, child: avatar);
    }
    final shown = people.take(3).toList();
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        children: [
          for (var index = 0; index < shown.length; index++)
            Positioned(
              left: index * 14,
              top: index == 0 ? 0 : 14,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: FeedPalette.card(context),
                    width: 2,
                  ),
                ),
                child: ProfileTap(
                  userId: shown[index].id,
                  child: AuthorAvatar(
                    name: shown[index].name,
                    photoUrl: shown[index].photoUrl,
                    radius: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
