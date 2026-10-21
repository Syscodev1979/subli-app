import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/constants.dart';
import 'club_app_bar.dart';

/// Egyszerű képernyő a még el nem készült funkciók helyén.
///
/// A vissza gomb a hírfolyamra visz, mert ezek a képernyők nem egy
/// egymásra helyezett navigációs veremben nyílnak, hanem útvonalcserével.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    required this.title,
    required this.message,
    super.key,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ClubAppBar(
        leading: IconButton(
          tooltip: 'Vissza a hírfolyamra',
          onPressed: () => context.go(AppRoutes.feed),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
