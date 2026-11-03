import 'package:flutter/material.dart';

import '../../../app/constants.dart';
import '../../feed/presentation/feed_palette.dart';

/// Gyors üzenetek sportolónak és szülőnek, ha edző is a beszélgetésben van.
class QuickReplies extends StatelessWidget {
  const QuickReplies({required this.onSelected, super.key});

  static const templates = <String>[
    'Ma nem tudok jönni',
    'Késni fogok',
    'Kérdésem van a lóról',
    'Kérdésem van az edzésről',
  ];

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: templates.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final text = templates[index];
          return ActionChip(
            label: Text(text),
            labelStyle: TextStyle(
              color: FeedPalette.title(context),
              fontSize: 13,
            ),
            backgroundColor: FeedPalette.field(context),
            side: const BorderSide(color: AppColors.gold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            onPressed: () => onSelected(text),
          );
        },
      ),
    );
  }
}
