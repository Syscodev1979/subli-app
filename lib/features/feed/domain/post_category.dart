/// A bejegyzés kategóriája. A [name] a Firestore-ban tárolt kulcs.
enum PostCategory {
  news('Hír'),
  announcement('Közlemény'),
  event('Esemény'),
  training('Edzés'),
  result('Eredmény'),
  horses('Lovaink');

  const PostCategory(this.label);

  final String label;

  static PostCategory parse(Object? raw) {
    for (final category in values) {
      if (category.name == raw) return category;
    }
    return news;
  }
}
