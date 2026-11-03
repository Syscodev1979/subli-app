import '../../auth/domain/user_role.dart';

/// Ki olvashatja a bejegyzést. A `posts.audience` lista ezeket a kulcsokat tárolja.
enum PostAudience {
  all('all'),
  staff('staff'),
  parents('parents'),
  athletes('athletes');

  const PostAudience(this.value);

  final String value;

  static const List<PostAudience> everyone = [PostAudience.all];

  static PostAudience? tryParse(String value) {
    for (final audience in PostAudience.values) {
      if (audience.value == value) return audience;
    }
    return null;
  }

  /// Hiányzó vagy üres lista minden tagnak szól, ahogy a régi bejegyzések.
  static List<PostAudience> listFrom(Object? raw) {
    if (raw is! List || raw.isEmpty) return everyone;
    final parsed = <PostAudience>[
      for (final item in raw)
        if (item is String && tryParse(item) != null) tryParse(item)!,
    ];
    if (parsed.isEmpty || parsed.contains(PostAudience.all)) return everyone;
    return parsed;
  }

  static bool isPublic(List<PostAudience> audience) {
    return audience.isEmpty || audience.contains(PostAudience.all);
  }

  static bool same(List<PostAudience> left, List<PostAudience> right) {
    final a = [...left]..sort((x, y) => x.index.compareTo(y.index));
    final b = [...right]..sort((x, y) => x.index.compareTo(y.index));
    if (a.length != b.length) return false;
    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }

  /// A „Minden tag” kizárólagos. A többiből több is maradhat, de legalább egy.
  static List<PostAudience> toggle(
    List<PostAudience> current,
    PostAudience choice, {
    required bool selected,
  }) {
    if (choice == PostAudience.all) {
      return selected ? everyone : current;
    }
    final next = [
      for (final item in current)
        if (item != PostAudience.all) item,
    ];
    if (selected) {
      if (!next.contains(choice)) next.add(choice);
      return next;
    }
    next.remove(choice);
    if (next.isEmpty) return current;
    return next;
  }

  /// Sportoló és szülő lekérdezése. Edző és admin nem szűr.
  static List<String>? queryFor(UserRole role) {
    return switch (role) {
      UserRole.admin || UserRole.coach => null,
      UserRole.athlete => const ['all', 'athletes'],
      UserRole.parent => const ['all', 'parents'],
      UserRole.member => const ['all'],
    };
  }
}
