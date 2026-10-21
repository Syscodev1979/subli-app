import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/constants.dart';

/// A hírfolyam jobb oldali menüje.
///
/// A kijelentkezés egyelőre csak a bejelentkező képernyőre visz.
/// A Firebase Auth kijelentkeztetés az auth lépésben kerül ide.
class ClubDrawer extends StatelessWidget {
  const ClubDrawer({super.key});

  void _go(BuildContext context, String location) {
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.go(location);
  }

  @override
  Widget build(BuildContext context) {
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
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Kijelentkezés'),
            onTap: () => _go(context, AppRoutes.login),
          ),
        ],
      ),
    );
  }
}
