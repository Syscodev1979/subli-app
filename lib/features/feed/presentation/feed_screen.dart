import 'package:flutter/material.dart';

import '../../../app/constants.dart';
import '../../../core/widgets/club_drawer.dart';

/// Hírfolyam. A törzs még placeholder, a fejléc már a végleges elrendezés.
class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // A menügomb a jobb oldalon van, ezért a panel is jobbról nyílik.
      endDrawer: const ClubDrawer(),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: const Row(
          children: [
            _ClubLogo(),
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
        actions: [
          // A FeedScreen kontextusa a Scaffold fölött van, ezért a gomb
          // saját kontextusából keressük meg a nyitható panelt.
          Builder(
            builder: (buttonContext) {
              return IconButton(
                tooltip: 'Menü',
                onPressed: () => Scaffold.of(buttonContext).openEndDrawer(),
                icon: const Icon(Icons.menu),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'A hírfolyam a következő lépésben készül el.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}

/// A klublogó helye, amíg a címer nem kerül az appba.
class _ClubLogo extends StatelessWidget {
  const _ClubLogo();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Klublogó',
      excludeSemantics: true,
      child: const CircleAvatar(
        radius: 16,
        backgroundColor: AppColors.burgundyLight,
        child: Icon(
          Icons.sports_martial_arts,
          size: 18,
          color: AppColors.burgundy,
        ),
      ),
    );
  }
}
