import 'package:intl/intl.dart';

/// Az esemény napja és időszaka, például „szombat, 2026. október 25. · 18:00–20:00”.
String eventWhenLabel(DateTime startsAt, DateTime? endsAt) {
  final day = DateFormat('EEEE, y. MMMM d.', 'hu').format(startsAt);
  final from = DateFormat.Hm('hu').format(startsAt);
  if (endsAt == null) return '$day · $from';
  return '$day · $from–${DateFormat.Hm('hu').format(endsAt)}';
}

/// A keresőbe kerülő dátumszavak. A kulcsszavak később hajtják az ékezeteket.
String eventSearchText(DateTime startsAt) {
  return DateFormat('y MMMM d EEEE', 'hu').format(startsAt);
}

bool eventEndsBeforeStart(DateTime startsAt, DateTime? endsAt) {
  if (endsAt == null) return false;
  return !endsAt.isAfter(startsAt);
}

bool sameEventMinute(DateTime? a, DateTime? b) {
  if (a == null || b == null) return a == null && b == null;
  return a.year == b.year &&
      a.month == b.month &&
      a.day == b.day &&
      a.hour == b.hour &&
      a.minute == b.minute;
}
