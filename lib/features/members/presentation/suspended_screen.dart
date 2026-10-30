import 'package:flutter/material.dart';

import '../../../core/widgets/club_app_bar.dart';

/// Felfüggesztett fiók. Más képernyő nem érhető el.
class SuspendedScreen extends StatelessWidget {
  const SuspendedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: ClubAppBar(),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'A fiókod fel van függesztve, keresd a klub vezetőjét',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
