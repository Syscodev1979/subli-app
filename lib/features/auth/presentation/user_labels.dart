import '../domain/user_role.dart';
import '../domain/user_status.dart';

extension UserRoleLabel on UserRole {
  String get labelHu => switch (this) {
    UserRole.admin => 'Adminisztrátor',
    UserRole.coach => 'Edző',
    UserRole.athlete => 'Sportoló',
    UserRole.parent => 'Szülő',
    UserRole.member => 'Tag',
  };
}

extension UserStatusLabel on UserStatus {
  String get labelHu => switch (this) {
    UserStatus.pending => 'Jóváhagyásra vár',
    UserStatus.active => 'Aktív',
    UserStatus.suspended => 'Felfüggesztve',
    UserStatus.rejected => 'Elutasítva',
  };
}
