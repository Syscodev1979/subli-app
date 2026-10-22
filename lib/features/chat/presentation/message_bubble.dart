import 'package:flutter/material.dart';

import '../../../app/constants.dart';
import '../../feed/presentation/author_avatar.dart';
import '../../profile/presentation/profile_navigation.dart';
import '../../feed/presentation/feed_palette.dart';
import '../domain/chat_message.dart';
import '../domain/club_member.dart';

/// Egy csevegőbuborék, a sorozat szélén lekerekítve.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    required this.message,
    required this.mine,
    required this.groupedAbove,
    required this.groupedBelow,
    required this.timeLabel,
    this.author,
    this.receipt,
    this.seenBy = const [],
    this.onLongPress,
    this.onRetry,
    super.key,
  });

  final ChatMessage message;
  final bool mine;
  final bool groupedAbove;
  final bool groupedBelow;
  final String? timeLabel;
  final ClubMember? author;
  final String? receipt;
  final List<ClubMember> seenBy;
  final VoidCallback? onLongPress;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final deleted = message.deleted;
    final bubble = _Bubble(
      mine: mine,
      groupedAbove: groupedAbove,
      groupedBelow: groupedBelow,
      deleted: deleted,
      faded: message.delivery == MessageDelivery.sending,
      text: deleted ? 'Ez az üzenet törölve lett' : message.text,
      onLongPress: deleted ? null : onLongPress,
    );
    final showAvatar = !mine && !groupedBelow;
    return Padding(
      padding: EdgeInsets.only(top: groupedAbove ? 2 : 8, left: 12, right: 12),
      child: Column(
        crossAxisAlignment: mine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: mine
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!mine) ...[
                SizedBox(
                  width: 28,
                  child: showAvatar
                      ? ProfileTap(
                          userId: message.senderId,
                          child: AuthorAvatar(
                            name: author?.name ?? '?',
                            photoUrl: author?.photoUrl,
                            radius: 12,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 6),
              ],
              Flexible(child: bubble),
            ],
          ),
          if (timeLabel != null && !groupedBelow)
            Padding(
              padding: EdgeInsets.only(top: 2, left: mine ? 0 : 34),
              child: Text(
                timeLabel!,
                style: TextStyle(
                  color: FeedPalette.muted(context),
                  fontSize: 11,
                ),
              ),
            ),
          if (receipt != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    receipt!,
                    style: TextStyle(
                      color: FeedPalette.muted(context),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (seenBy.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    for (final person in seenBy.take(4))
                      Padding(
                        padding: const EdgeInsets.only(left: 2),
                        child: ProfileTap(
                          userId: person.id,
                          child: AuthorAvatar(
                            name: person.name,
                            photoUrl: person.photoUrl,
                            radius: 8,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          if (message.delivery == MessageDelivery.failed)
            GestureDetector(
              onTap: onRetry,
              child: const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Nem sikerült elküldeni – koppints az újraküldéshez',
                  style: TextStyle(
                    color: Color(0xFFD32F2F),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.mine,
    required this.groupedAbove,
    required this.groupedBelow,
    required this.deleted,
    required this.faded,
    required this.text,
    required this.onLongPress,
  });

  final bool mine;
  final bool groupedAbove;
  final bool groupedBelow;
  final bool deleted;
  final bool faded;
  final String text;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    const round = Radius.circular(18);
    const tight = Radius.circular(6);
    final radius = mine
        ? BorderRadius.only(
            topLeft: round,
            bottomLeft: round,
            topRight: groupedAbove ? tight : round,
            bottomRight: groupedBelow ? tight : round,
          )
        : BorderRadius.only(
            topRight: round,
            bottomRight: round,
            topLeft: groupedAbove ? tight : round,
            bottomLeft: groupedBelow ? tight : round,
          );
    final child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Text(
        text,
        style: TextStyle(
          color: deleted
              ? FeedPalette.muted(context)
              : mine
              ? Colors.white
              : FeedPalette.title(context),
          fontSize: 15,
          height: 1.35,
          fontStyle: deleted ? FontStyle.italic : FontStyle.normal,
        ),
      ),
    );
    final decoration = deleted
        ? BoxDecoration(
            color: Colors.transparent,
            borderRadius: radius,
            border: Border.all(
              color: FeedPalette.muted(context).withValues(alpha: 0.4),
            ),
          )
        : mine
        ? BoxDecoration(
            borderRadius: radius,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.gradientStart,
                AppColors.gradientMid,
                AppColors.gradientEnd,
              ],
            ),
          )
        : BoxDecoration(
            color: FeedPalette.field(context),
            borderRadius: radius,
          );
    return Opacity(
      opacity: faded ? 0.55 : 1,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: DecoratedBox(decoration: decoration, child: child),
      ),
    );
  }
}
