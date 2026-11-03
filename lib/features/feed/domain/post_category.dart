/// A bejegyzés kategóriája. A [name] a Firestore-ban tárolt kulcs.
///
/// A klubonkénti sorrend és a választható lista a [ClubConfig.postCategories].
enum PostCategory {
  post('Poszt'),
  announcement('Közlemény'),
  event('Esemény'),
  horses('Lovaink');

  const PostCategory(this.label);

  final String label;

  static PostCategory parse(Object? raw) {
    for (final category in values) {
      if (category.name == raw) return category;
    }
    return post;
  }
}
