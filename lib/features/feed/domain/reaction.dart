/// Egy felhasználó egy reakciója. A dokumentum azonosítója a felhasználóé.
enum ReactionType {
  like,
  heart,
  haha,
  wow,
  sad,
  horse;

  static ReactionType? fromName(Object? value) {
    return switch (value) {
      'like' => ReactionType.like,
      'heart' => ReactionType.heart,
      'haha' => ReactionType.haha,
      'wow' => ReactionType.wow,
      'sad' => ReactionType.sad,
      'horse' => ReactionType.horse,
      _ => null,
    };
  }

  String get label => switch (this) {
    ReactionType.like => 'Like',
    ReactionType.heart => 'Szív',
    ReactionType.haha => 'Haha',
    ReactionType.wow => 'Wow',
    ReactionType.sad => 'Szomorú',
    ReactionType.horse => 'Lovas!',
  };

  /// A Like pipa ikon, a többi emoji.
  String? get emoji => switch (this) {
    ReactionType.like => null,
    ReactionType.heart => '❤️',
    ReactionType.haha => '😄',
    ReactionType.wow => '😮',
    ReactionType.sad => '😢',
    ReactionType.horse => '🐴',
  };
}

class PostReaction {
  const PostReaction({
    required this.userId,
    required this.userName,
    required this.type,
    required this.createdAt,
  });

  final String userId;
  final String userName;
  final ReactionType type;
  final DateTime createdAt;
}
