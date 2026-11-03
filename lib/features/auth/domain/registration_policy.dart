import 'age.dart';

/// A 18 év alatti regisztráció elutasító mondata.
const adultsOnlyRegistrationMessage =
    'Az alkalmazást csak 18. életévüket betöltött tagok használhatják.';

/// 18 év feletti klubban a születési dátum kötelező, és 18 alatt nem elég.
String? adultsOnlyBirthDateError(DateTime? birthDate, {DateTime? onDate}) {
  if (birthDate == null) return 'A születési dátum kötelező.';
  if (isUnder18(birthDate, onDate: onDate)) return adultsOnlyRegistrationMessage;
  return null;
}
