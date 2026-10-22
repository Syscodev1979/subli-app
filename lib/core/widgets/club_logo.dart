import 'package:flutter/material.dart';

import '../../app/club_config.dart';

/// A klublogó a fejlécben, kb. 36 px magas, a kép arányát megtartva.
class ClubLogo extends StatelessWidget {
  const ClubLogo({super.key});

  static const double height = 36;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final image = Image.asset(
      ClubConfig.logoAsset,
      height: dark ? height - 6 : height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      isAntiAlias: true,
      semanticLabel: 'Klublogó',
    );
    if (!dark) return image;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F4F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(padding: const EdgeInsets.all(3), child: image),
    );
  }
}
