import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/constants.dart';
import '../../app/theme_controller.dart';
import '../../app/theme_preference.dart';
import '../../features/auth/data/auth_providers.dart';
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

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: AppColors.burgundy),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                AppInfo.clubName,
                style: TextStyle(
                  color: AppColors.onPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
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
          const _AppearanceSection(),
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

class _AppearanceSection extends ConsumerWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(themePreferenceProvider);
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.contrast_outlined),
          title: Text(
            'Megjelenés',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        for (final preference in ThemePreference.values)
          ListTile(
            selected: preference == selected,
            leading: Icon(
              preference == selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
            ),
            title: Text(preference.label),
            onTap: () {
              ref.read(themePreferenceProvider.notifier).select(preference);
            },
          ),
      ],
    );
  }
}
