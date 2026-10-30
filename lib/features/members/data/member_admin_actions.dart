import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_providers.dart';
import '../../auth/domain/app_user.dart';

final allUsersProvider = StreamProvider<List<AppUser>>((ref) {
  return ref.watch(userRepositoryProvider).watchAll();
});

final memberAdminActionsProvider = Provider<MemberAdminActions>((ref) {
  return MemberAdminActions(
    FirebaseFunctions.instanceFor(region: 'europe-west3'),
  );
});

class MemberAdminActions {
  MemberAdminActions(this._functions);

  final FirebaseFunctions _functions;

  Future<void> deleteMember(String uid) {
    return _functions.httpsCallable('deleteMember').call({'uid': uid});
  }
}
