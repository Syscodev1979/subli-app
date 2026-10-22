import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/constants.dart';
import '../../auth/data/auth_providers.dart';
import '../../auth/domain/auth_session.dart';

/// Profilkép vagy név: saját magánál a saját profil, különben a tag profilja.
class ProfileTap extends ConsumerWidget {
  const ProfileTap({required this.userId, required this.child, super.key});

  final String userId;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => openProfile(context, ref, userId),
      child: child,
    );
  }
}

void openProfile(BuildContext context, WidgetRef ref, String userId) {
  final session = ref.read(authGateProvider).asData?.value;
  final selfId = session is AuthSignedIn ? session.user.id : null;
  if (selfId != null && selfId == userId) {
    context.push(AppRoutes.profile);
  } else {
    context.push(AppRoutes.member(userId));
  }
}
