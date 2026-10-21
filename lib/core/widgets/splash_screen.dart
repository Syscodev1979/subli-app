import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/constants.dart';
import '../../features/auth/data/auth_providers.dart';
import '../../features/auth/domain/auth_session.dart';

/// Amíg a Firebase Auth és a profil állapota nem ismert.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authGateProvider);
    final profileMissing = session.asData?.value is AuthProfileMissing;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (session.hasError) ...[
                const Text(
                  'A bejelentkezés állapotát nem sikerült betölteni.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(authGateProvider),
                  child: const Text('Újra'),
                ),
              ] else if (profileMissing) ...[
                const Text(
                  'A fiók adatai még nem elérhetők.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.read(authRepositoryProvider).signOut(),
                  child: const Text('Kijelentkezés'),
                ),
              ] else ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  AppInfo.clubName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
