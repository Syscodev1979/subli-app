import 'package:intl/intl.dart';

/// Magyar hosszú dátum, például: „2026. október 21., szerda”.
///
/// A `hu` lokalizációs adatot az app induláskor tölti be.
String formatHungarianDate(DateTime date) {
  return DateFormat.yMMMMEEEEd('hu').format(date);
}
