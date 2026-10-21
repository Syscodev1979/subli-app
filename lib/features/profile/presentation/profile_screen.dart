import 'package:flutter/material.dart';

import '../../../core/widgets/placeholder_screen.dart';

/// Saját profil. Az adatok később készülnek el.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Profil',
      message: 'A profil a következő lépésben készül el.',
    );
  }
}
