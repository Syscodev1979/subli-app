import 'package:flutter/material.dart';

import '../../../app/constants.dart';
import 'feed_palette.dart';

/// A lista alja, ha minden bejegyzés betöltődött.
class FeedEndMark extends StatelessWidget {
  const FeedEndMark({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 40),
      child: Column(
        children: [
          const Icon(
            Icons.pets,
            size: 28,
            color: AppColors.gold,
          ),
          const SizedBox(height: 10),
          Text(
            'Minden bejegyzést láttál 🐴',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: FeedPalette.title(context),
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Nézz vissza később a friss hírekért!',
            textAlign: TextAlign.center,
            style: TextStyle(color: FeedPalette.muted(context), fontSize: 13),
          ),
        ],
      ),
    );
  }
}
