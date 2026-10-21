import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../app/constants.dart';
import '../../../core/utils/name_initials.dart';

/// Kerek profilkép, fotó nélkül a név kezdőbetűi bordó körben.
class AuthorAvatar extends StatelessWidget {
  const AuthorAvatar({
    required this.name,
    required this.photoUrl,
    this.radius = 20,
    super.key,
  });

  final String name;
  final String? photoUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final fallback = _InitialsAvatar(name: name, radius: radius);
    final url = photoUrl;
    if (url == null || url.isEmpty) return fallback;
    return CachedNetworkImage(
      imageUrl: url,
      width: radius * 2,
      height: radius * 2,
      imageBuilder: (context, image) {
        return CircleAvatar(radius: radius, backgroundImage: image);
      },
      placeholder: (_, _) => fallback,
      errorWidget: (_, _, _) => fallback,
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.name, required this.radius});

  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.burgundy,
      child: Text(
        nameInitials(name),
        style: TextStyle(
          color: AppColors.onPrimary,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.7,
        ),
      ),
    );
  }
}
