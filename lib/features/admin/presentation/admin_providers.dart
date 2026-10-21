import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_providers.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/domain/user_status.dart';

final pendingUsersProvider = StreamProvider<List<AppUser>>((ref) {
  return ref.watch(userRepositoryProvider).watchByStatus(UserStatus.pending);
});

final activeAthletesProvider = StreamProvider<List<AppUser>>((ref) {
  return ref.watch(userRepositoryProvider).watchActiveAthletes();
});
