import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/event_time.dart';
import '../domain/post_category.dart';
import 'category_style.dart';
import 'feed_palette.dart';

/// A hírfolyam kártyáján a nap és az időpont.
class EventWhenBanner extends StatelessWidget {
  const EventWhenBanner({required this.startsAt, this.endsAt, super.key});

  final DateTime startsAt;
  final DateTime? endsAt;

  @override
  Widget build(BuildContext context) {
    final style = CategoryStyle.of(
      PostCategory.event,
      Theme.of(context).brightness,
    );
    final month = DateFormat(
      'MMM',
      'hu',
    ).format(startsAt).replaceAll('.', '').toUpperCase();
    return Semantics(
      container: true,
      label: _capitalized(eventWhenLabel(startsAt, endsAt)),
      child: ExcludeSemantics(
        child: Padding(
          key: const Key('event-when'),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: style.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: style.color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SizedBox(
                      width: 52,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          children: [
                            Text(
                              month,
                              style: TextStyle(
                                color: style.onColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                            Text(
                              '${startsAt.day}',
                              style: TextStyle(
                                color: style.onColor,
                                fontSize: 20,
                                height: 1.1,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _capitalized(
                            DateFormat('EEEE', 'hu').format(startsAt),
                          ),
                          style: TextStyle(
                            color: FeedPalette.title(context),
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _timeLine(startsAt, endsAt),
                          style: TextStyle(
                            color: FeedPalette.muted(context),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A szerkesztőben a dátum, a kezdés és az opcionális vége.
class EventScheduleEditor extends StatelessWidget {
  const EventScheduleEditor({
    required this.startsAt,
    required this.endsAt,
    required this.onPickDate,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onClearEnd,
    super.key,
  });

  final DateTime? startsAt;
  final DateTime? endsAt;
  final VoidCallback onPickDate;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final VoidCallback onClearEnd;

  @override
  Widget build(BuildContext context) {
    final style = CategoryStyle.of(
      PostCategory.event,
      Theme.of(context).brightness,
    );
    final start = startsAt;
    final end = endsAt;
    final invalid = start != null && eventEndsBeforeStart(start, end);
    return DecoratedBox(
      key: const Key('event-schedule'),
      decoration: BoxDecoration(
        color: style.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: style.color.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_month, color: style.color, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Az esemény időpontja',
                  style: TextStyle(
                    color: FeedPalette.title(context),
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _ScheduleRow(
              buttonKey: const Key('event-pick-date'),
              icon: Icons.event,
              color: style.color,
              label: start == null
                  ? 'Válassz dátumot'
                  : DateFormat.yMMMMEEEEd('hu').format(start),
              onTap: onPickDate,
            ),
            _ScheduleRow(
              buttonKey: const Key('event-pick-start'),
              icon: Icons.schedule,
              color: style.color,
              label: start == null
                  ? 'Kezdés'
                  : 'Kezdés ${DateFormat.Hm('hu').format(start)}',
              onTap: start == null ? onPickDate : onPickStart,
            ),
            if (end == null)
              TextButton(
                key: const Key('event-pick-end'),
                onPressed: start == null ? null : onPickEnd,
                child: const Text('Vége hozzáadása'),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _ScheduleRow(
                      buttonKey: const Key('event-pick-end'),
                      icon: Icons.flag_outlined,
                      color: style.color,
                      label: 'Vége ${DateFormat.Hm('hu').format(end)}',
                      onTap: onPickEnd,
                    ),
                  ),
                  IconButton(
                    key: const Key('event-clear-end'),
                    tooltip: 'Vége törlése',
                    onPressed: onClearEnd,
                    icon: Icon(Icons.close, color: FeedPalette.muted(context)),
                  ),
                ],
              ),
            if (start == null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Koppints, és add meg a napot.',
                  style: TextStyle(
                    color: FeedPalette.muted(context),
                    fontSize: 13,
                  ),
                ),
              ),
            if (invalid)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'A vége nem lehet a kezdés előtt.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({
    required this.buttonKey,
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final Key buttonKey;
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: FeedPalette.card(context),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          key: buttonKey,
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: FeedPalette.title(context),
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _timeLine(DateTime startsAt, DateTime? endsAt) {
  final day = DateFormat.yMMMMd('hu').format(startsAt);
  final from = DateFormat.Hm('hu').format(startsAt);
  if (endsAt == null) return '$day · $from';
  return '$day · $from–${DateFormat.Hm('hu').format(endsAt)}';
}

String _capitalized(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1);
}
