import 'package:flutter/material.dart';

import 'app_flavor.dart';
import 'club_config.dart';

/// A dev flavor akkor jelenik meg, ha a gastroyal-karate-dev még nincs bekötve.
class FirebaseSetupScreen extends StatelessWidget {
  const FirebaseSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final flavor = AppFlavor.current;
    return MaterialApp(
      title: flavor.appName,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  flavor.appName,
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                const Text(
                  'A fejlesztői Firebase-projekt még nincs összekötve. '
                  'Az alkalmazás ezért nem csatlakozik az éles klubadatokhoz.',
                ),
                const SizedBox(height: 12),
                const Text(
                  'Hozd létre a gastroyal-karate-dev projektet, majd futtasd '
                  'a docs/KORNYEZETEK.md-ben leírt flutterfire configure '
                  'parancsot.',
                ),
                const SizedBox(height: 12),
                Text(
                  'Várt azonosító: ${ClubConfig.devApplicationId}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
