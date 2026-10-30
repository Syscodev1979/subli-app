import '../../../app/club_config.dart';
import 'app_user.dart';
import 'user_role.dart';

/// Igaz, ha a dokumentum az egyetlen kijelölt adminé.
bool isDesignatedAdmin(AppUser user) {
  return user.role == UserRole.admin &&
      user.email.toLowerCase() == ClubConfig.adminEmail;
}

/// A hírfolyam és az adminfelületek sávja, amíg a cím nincs megerősítve.
bool needsAdminEmailVerification({
  required String? email,
  required bool emailVerified,
}) {
  return email != null &&
      email.toLowerCase() == ClubConfig.adminEmail &&
      !emailVerified;
}
