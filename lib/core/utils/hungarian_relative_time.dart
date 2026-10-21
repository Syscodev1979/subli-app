import 'package:intl/intl.dart';

/// Rövid magyar idő a hírfolyamhoz: „5 perce”, „tegnap 18:30”.
///
/// A `hu` lokalizációs adatot az app induláskor tölti be.
String hungarianRelativeTime(DateTime time, DateTime now) {
  final localTime = time.toLocal();
  final localNow = now.toLocal();
  final difference = localNow.difference(localTime);

  if (!difference.isNegative && _isSameDay(localTime, localNow)) {
    if (difference.inMinutes < 1) return 'most';
    if (difference.inHours < 1) return '${difference.inMinutes} perce';
    return '${difference.inHours} órája';
  }

  if (difference.isNegative || difference.inMinutes < 1) return 'most';

  final yesterday = DateTime(
    localNow.year,
    localNow.month,
    localNow.day,
  ).subtract(const Duration(days: 1));
  if (_isSameDay(localTime, yesterday)) {
    return 'tegnap ${DateFormat.Hm('hu').format(localTime)}';
  }

  if (localTime.year == localNow.year) {
    return DateFormat('MMM d. HH:mm', 'hu').format(localTime);
  }
  return DateFormat('y. MMM d. HH:mm', 'hu').format(localTime);
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
