import 'package:intl/intl.dart';

/// A beszélgetéslista ideje: „14:32”, „tegnap”, „okt. 12.”.
String chatListTime(DateTime time, DateTime now) {
  final local = time.toLocal();
  final current = now.toLocal();
  if (_sameDay(local, current)) return DateFormat.Hm('hu').format(local);
  final yesterday = DateTime(current.year, current.month, current.day)
      .subtract(const Duration(days: 1));
  if (_sameDay(local, yesterday)) return 'tegnap';
  if (local.year == current.year) return DateFormat('MMM d.', 'hu').format(local);
  return DateFormat('y. MMM d.', 'hu').format(local);
}

/// Napelválasztó: „Ma”, „Tegnap”, „2026. október 12.”.
String chatDayLabel(DateTime time, DateTime now) {
  final local = time.toLocal();
  final current = now.toLocal();
  if (_sameDay(local, current)) return 'Ma';
  final yesterday = DateTime(current.year, current.month, current.day)
      .subtract(const Duration(days: 1));
  if (_sameDay(local, yesterday)) return 'Tegnap';
  return DateFormat.yMMMMd('hu').format(local);
}

String chatClock(DateTime time) => DateFormat.Hm('hu').format(time.toLocal());

bool _sameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
