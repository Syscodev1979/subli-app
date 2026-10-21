import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_providers.dart';
import '../domain/age.dart';
import '../domain/auth_session.dart';
import '../domain/user_role.dart';
import '../domain/user_status.dart';

/// Pending és elutasított fiók. Innen csak kijelentkezni lehet.
class PendingScreen extends ConsumerWidget {
  const PendingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authGateProvider).asData?.value;
    final user = session is AuthSignedIn ? session.user : null;
    final rejected = user?.status == UserStatus.rejected;
    final under18 =
        user != null &&
        user.role == UserRole.athlete &&
        user.birthDate != null &&
        isUnder18(user.birthDate!);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(rejected ? 'Regisztráció elutasítva' : 'Jóváhagyásra vár'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  rejected
                      ? 'A regisztrációdat elutasították. Ha kérdésed van, keresd az edzőt.'
                      : 'A regisztrációd jóváhagyásra vár.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
                if (!rejected && under18) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Mivel még nem vagy 18 éves, a fiókot szülői jóváhagyás után aktiválja az edző.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => ref.read(authRepositoryProvider).signOut(),
                  child: const Text('Kijelentkezés'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
