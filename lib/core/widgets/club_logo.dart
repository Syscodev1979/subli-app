import 'package:flutter/material.dart';

import '../../app/constants.dart';

/// A klublogó helye, amíg a címer nem kerül az appba.
class ClubLogo extends StatelessWidget {
  const ClubLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Klublogó',
      excludeSemantics: true,
      child: const CircleAvatar(
        radius: 16,
        backgroundColor: AppColors.burgundyLight,
        child: Icon(
          Icons.sports_martial_arts,
          size: 18,
          color: AppColors.burgundy,
        ),
      ),
    );
  }
}
