/// Igaz, amíg a [birthDate] tulajdonosa a [onDate] napon még nincs 18 éves.
bool isUnder18(DateTime birthDate, {DateTime? onDate}) {
  final today = onDate ?? DateTime.now();
  final todayDate = DateTime(today.year, today.month, today.day);
  final eighteenthBirthday = DateTime(
    birthDate.year + 18,
    birthDate.month,
    birthDate.day,
  );
  return todayDate.isBefore(eighteenthBirthday);
}
