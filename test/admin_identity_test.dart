import 'package:flutter_test/flutter_test.dart';
import 'package:subli_app/app/club_config.dart';
import 'package:subli_app/features/auth/domain/admin_identity.dart';
import 'package:subli_app/features/auth/domain/app_user.dart';
import 'package:subli_app/features/auth/domain/user_role.dart';
import 'package:subli_app/features/auth/domain/user_status.dart';

void main() {
  test('csak a kijelölt cím admin, kisbetűsítve', () {
    expect(ClubConfig.adminEmail, 'info@sarosigyorgy.hu');
    expect(isDesignatedAdmin(_user('Info@SarosiGyorgy.hu')), isTrue);
    expect(isDesignatedAdmin(_user('info@sarosigyorgy.hu')), isTrue);
    expect(isDesignatedAdmin(_user('admin-beallitando@invalid')), isFalse);
    expect(isDesignatedAdmin(_user('mas@example.com')), isFalse);
    expect(
      isDesignatedAdmin(_user('info@sarosigyorgy.hu', role: UserRole.coach)),
      isFalse,
    );
  });
}

AppUser _user(String email, {UserRole role = UserRole.admin}) {
  return AppUser(
    id: 'admin-1',
    name: 'Admin',
    email: email,
    role: role,
    birthDate: DateTime(1990, 1, 1),
    photoUrl: null,
    status: UserStatus.active,
    childIds: const [],
    parentIds: const [],
    childRequests: const [],
    createdAt: DateTime(2026, 1, 1),
  );
}
