import 'package:flutter/material.dart';

import '../../app/club_config.dart';

/// A teljes Subli logó a fejlécben, 38 px magas, a kép arányát megtartva.
class ClubLogo extends StatelessWidget {
  const ClubLogo({super.key});

  static const double height = 38;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      ClubConfig.logoAsset,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      isAntiAlias: true,
      semanticLabel: 'Subli',
    );
  }
}
