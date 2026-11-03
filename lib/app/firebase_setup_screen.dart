import 'package:flutter/material.dart';

import 'app_flavor.dart';

/// Akkor jelenik meg, ha a flavor Firebase-projektje még nincs bekötve.
/// Ilyenkor a Firebase inicializálása nem fut le, hálózati hívás nincs.
class FirebaseSetupScreen extends StatelessWidget {
  const FirebaseSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final flavor = AppFlavor.current;
    final projectId = flavor.isDev ? 'subli-app-dev' : 'subli-app';
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
                  'A Firebase-projekt még nincs összekötve. '
                  'Az alkalmazás ezért nem csatlakozik klubadatokhoz, '
                  'és nem indít hálózati hívást.',
                ),
                const SizedBox(height: 12),
                Text(
                  'Hozd létre a $projectId projektet, majd futtasd '
                  'a docs/KORNYEZETEK.md-ben leírt flutterfire configure '
                  'parancsot.',
                ),
                const SizedBox(height: 12),
                Text(
                  'Várt azonosító: ${flavor.applicationId}',
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
