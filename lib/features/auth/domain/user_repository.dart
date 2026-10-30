import 'app_user.dart';
import 'user_role.dart';
import 'user_status.dart';

/// A `users` gyűjtemény írása és olvasása.
abstract class UserRepository {
  Stream<AppUser?> watchUser(String id);

  Future<void> createUser(AppUser user);

  Stream<List<AppUser>> watchByStatus(UserStatus status);

  Stream<List<AppUser>> watchActiveAthletes();

  /// Jóváhagyás. A [assignedRole] csak admin hívásból érkezik.
  /// Szülőnél a [childIds] bekerül a szülőhöz, a gyermek `parentIds` mezőjébe
  /// pedig a szülő azonosítója.
  Future<void> approveUser({
    required String userId,
    required UserRole currentRole,
    UserRole? assignedRole,
    List<String> childIds = const [],
  });

  Future<void> rejectUser(String userId);

  /// Név, születési dátum vagy profilkép. Csak a megadott mezők íródnak.
  Future<void> updateOwnProfile({
    required String userId,
    String? name,
    DateTime? birthDate,
    String? photoUrl,
    bool clearPhoto = false,
  });

  /// Gyermek profilképe. A szülő más mezőt nem írhat.
  Future<void> updatePhotoUrl({
    required String userId,
    required String? photoUrl,
  });

  /// Övfokozat. A [beltRank] null törli a mezőt.
  Future<void> setBeltRank({required String userId, required String? beltRank});

  /// Minden regisztrált fiók. Csak admin olvashatja.
  Stream<List<AppUser>> watchAll();

  /// Admin mentése. Szerep, státusz vagy csoport változásakor [actorId] kerül a naplóba.
  Future<void> saveMember({
    required String actorId,
    required AppUser before,
    required String name,
    required UserRole role,
    required UserStatus status,
    required String? beltRank,
    required List<String> groupIds,
    required DateTime? birthDate,
    required List<String> childIds,
    required List<String> parentIds,
  });
}
