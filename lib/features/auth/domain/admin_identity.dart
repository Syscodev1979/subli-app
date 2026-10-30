import '../../../app/club_config.dart';
import 'app_user.dart';
import 'user_role.dart';

/// Igaz, ha a dokumentum az egyetlen kijelölt adminé.
bool isDesignatedAdmin(AppUser user) {
  return user.role == UserRole.admin &&
      user.email.toLowerCase() == ClubConfig.adminEmail;
}
