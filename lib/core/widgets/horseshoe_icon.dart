import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/club_config.dart';

/// A klub jele. A Subli patkót, a Gastroyal mancsot használ.
class ClubThemeIcon extends StatelessWidget {
  const ClubThemeIcon({this.size, this.color, super.key});

  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final resolvedSize = size ?? theme.size ?? 24;
    final resolvedColor = color ?? theme.color ?? const Color(0xFF000000);
    if (ClubConfig.themeIcon == ClubMark.horseshoe) {
      return HorseshoeIcon(size: resolvedSize, color: resolvedColor);
    }
    return Icon(Icons.pets, size: resolvedSize, color: resolvedColor);
  }
}

/// Felfelé nyitott patkó, a szárain 3-3 szöghellyel.
class HorseshoeIcon extends StatelessWidget {
  const HorseshoeIcon({this.size, this.color, super.key});

  static const asset = 'assets/branding/icons/horseshoe.svg';

  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final resolvedSize = size ?? theme.size ?? 24;
    final resolvedColor = color ?? theme.color ?? const Color(0xFF000000);
    return SvgPicture.asset(
      asset,
      width: resolvedSize,
      height: resolvedSize,
      colorFilter: ColorFilter.mode(resolvedColor, BlendMode.srcIn),
    );
  }
}
