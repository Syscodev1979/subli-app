import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/club_config.dart';
import '../../app/constants.dart';
import '../../features/auth/data/auth_providers.dart';
import 'appearance_section.dart';
import '../../features/auth/domain/admin_identity.dart';
import '../../features/auth/domain/auth_session.dart';

/// A hírfolyam jobb oldali menüje.
class ClubDrawer extends ConsumerWidget {
  const ClubDrawer({super.key});

  void _go(BuildContext context, String location) {
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.go(location);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authGateProvider).asData?.value;
    final user = session is AuthSignedIn ? session.user : null;
    final showAdmin = user?.role.canReviewMembers ?? false;
    final showMembers = user != null && isDesignatedAdmin(user);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
            ),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Image.asset(
                ClubConfig.logoAsset,
                height: 56,
                fit: BoxFit.contain,
                semanticLabel: 'Subli',
              ),
            ),
          ),
          if (showMembers)
            ListTile(
              leading: const Icon(Icons.groups_outlined),
              title: const Text('Tagok'),
              onTap: () => _go(context, AppRoutes.members),
            ),
          if (showAdmin)
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined),
              title: const Text('Adminisztráció'),
              onTap: () => _go(context, AppRoutes.admin),
            ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profil'),
            onTap: () => _go(context, AppRoutes.profile),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month_outlined),
            title: const Text('Naptár'),
            onTap: () => _go(context, AppRoutes.calendar),
          ),
          ListTile(
            leading: const Icon(Icons.chat_bubble_outline),
            title: const Text('Üzenetek'),
            onTap: () => _go(context, AppRoutes.chat),
          ),
          const Divider(),
          const AppearanceSection(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Kijelentkezés'),
            onTap: () async {
              final auth = ref.read(authRepositoryProvider);
              Navigator.of(context).pop();
              await auth.signOut();
            },
          ),
        ],
      ),
    );
  }
}
