import 'package:flutter/material.dart';

import '../../../core/widgets/placeholder_screen.dart';

/// Bejelentkezés helye. A Firebase Auth űrlap később készül el.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Bejelentkezés',
      message: 'A bejelentkezés a következő lépésben készül el.',
    );
  }
}
