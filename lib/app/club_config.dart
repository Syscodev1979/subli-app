import 'package:flutter/material.dart';

/// A klub megjelenéséhez és szabályaihoz tartozó, kódban rögzített értékek.
///
/// Az övfokozatok és a dokumentumtípusok itt cserélhetők, ha a klub mást használ.
abstract final class ClubConfig {
  /// TODO_SUBLI: ideiglenes piros kör S betűvel, amíg a végleges logó nincs meg.
  static const String logoAsset = 'assets/images/logo.png';

  /// A fejléc teljes neve.
  static const String clubName = 'Subli – lovas közösségi app';

  /// Szűk fejlécen ennyi fér ki a névből.
  static const String clubNameShort = 'Subli';

  /// Éles alkalmazásazonosító (iOS bundle ID és Android applicationId).
  static const String prodApplicationId = 'hu.subli.app';

  /// Fejlesztői alkalmazásazonosító. A két változat egyszerre telepíthető.
  static const String devApplicationId = 'hu.subli.app.dev';

  static const String prodAppName = 'Subli';
  static const String devAppName = 'Subli DEV';

  /// Csak 18. életévüket betöltött tagok. Ha false, a szülős klub viselkedése
  /// marad: szülő szerep, gyermekkapcsolat és a kiskorú jelzések.
  static const bool adultsOnly = true;

  /// A tesztek ezzel kapcsolják vissza a szülős viselkedést.
  static bool? debugAdultsOnlyOverride;

  static bool get enforceAdultsOnly => debugAdultsOnlyOverride ?? adultsOnly;

  /// TODO_SUBLI: a visszajelző cím. Addig senki nem kap levelet.
  static const String feedbackEmail = 'visszajelzes-beallitando@invalid';

  /// TODO_SUBLI: az egyetlen admin e-mail. A helyettesítő cím nem létezik,
  /// ezért véletlenül senki nem kap admin jogot. Ugyanez a szöveg szerepel a
  /// Firestore és a Storage szabályokban, valamint a Cloud Functionsben.
  /// Lásd a docs/UJ_KLUB.md fájlt.
  static const String adminEmail = 'admin-beallitando@invalid';

  /// Az iOS alkalmazás minimum verziója.
  static const String iosMinimumVersion = '15.0';

  static const int avatarSize = 512;
  static const int avatarQuality = 85;
  static const int maxAvatarBytes = 5 * 1024 * 1024;
  static const int maxDocumentBytes = 20 * 1024 * 1024;
  static const int maxDocumentsPerPost = 5;

  /// 10. kyu-tól 1. kyu-ig, majd 1. dan-tól 10. dan-ig.
  ///
  /// A színek egy szokásos magyar kyu-skála szerint vannak, és szabadon
  /// átírhatók. A felirat mindig „5. kyu – kék öv” alakú.
  static const List<BeltGrade> belts = [
    BeltGrade(
      key: 'kyu10',
      label: '10. kyu',
      beltName: 'fehér öv',
      color: Color(0xFFF4F1F2),
    ),
    BeltGrade(
      key: 'kyu9',
      label: '9. kyu',
      beltName: 'fehér-sárga öv',
      color: Color(0xFFF4F1F2),
      stripe: Color(0xFFF2C200),
    ),
    BeltGrade(
      key: 'kyu8',
      label: '8. kyu',
      beltName: 'sárga öv',
      color: Color(0xFFF2C200),
    ),
    BeltGrade(
      key: 'kyu7',
      label: '7. kyu',
      beltName: 'narancssárga öv',
      color: Color(0xFFF08A24),
    ),
    BeltGrade(
      key: 'kyu6',
      label: '6. kyu',
      beltName: 'zöld öv',
      color: Color(0xFF2E7D32),
    ),
    BeltGrade(
      key: 'kyu5',
      label: '5. kyu',
      beltName: 'kék öv',
      color: Color(0xFF1F6FEB),
    ),
    BeltGrade(
      key: 'kyu4',
      label: '4. kyu',
      beltName: 'lila öv',
      color: Color(0xFF7B4B9A),
    ),
    BeltGrade(
      key: 'kyu3',
      label: '3. kyu',
      beltName: 'barna öv',
      color: Color(0xFF8D5A32),
    ),
    BeltGrade(
      key: 'kyu2',
      label: '2. kyu',
      beltName: 'barna öv',
      color: Color(0xFF6B3E22),
    ),
    BeltGrade(
      key: 'kyu1',
      label: '1. kyu',
      beltName: 'barna öv',
      color: Color(0xFF4A2A16),
    ),
    BeltGrade(
      key: 'dan1',
      label: '1. dan',
      beltName: 'fekete öv',
      color: Color(0xFF1C1B1F),
    ),
    BeltGrade(
      key: 'dan2',
      label: '2. dan',
      beltName: 'fekete öv',
      color: Color(0xFF1C1B1F),
    ),
    BeltGrade(
      key: 'dan3',
      label: '3. dan',
      beltName: 'fekete öv',
      color: Color(0xFF1C1B1F),
    ),
    BeltGrade(
      key: 'dan4',
      label: '4. dan',
      beltName: 'fekete öv',
      color: Color(0xFF1C1B1F),
    ),
    BeltGrade(
      key: 'dan5',
      label: '5. dan',
      beltName: 'fekete öv',
      color: Color(0xFF1C1B1F),
    ),
    BeltGrade(
      key: 'dan6',
      label: '6. dan',
      beltName: 'fekete öv',
      color: Color(0xFF1C1B1F),
    ),
    BeltGrade(
      key: 'dan7',
      label: '7. dan',
      beltName: 'fekete öv',
      color: Color(0xFF1C1B1F),
    ),
    BeltGrade(
      key: 'dan8',
      label: '8. dan',
      beltName: 'fekete öv',
      color: Color(0xFF1C1B1F),
    ),
    BeltGrade(
      key: 'dan9',
      label: '9. dan',
      beltName: 'fekete öv',
      color: Color(0xFF1C1B1F),
    ),
    BeltGrade(
      key: 'dan10',
      label: '10. dan',
      beltName: 'fekete öv',
      color: Color(0xFF1C1B1F),
    ),
  ];

  static BeltGrade? beltByKey(String? key) {
    if (key == null || key.isEmpty) return null;
    for (final belt in belts) {
      if (belt.key == key) return belt;
    }
    return null;
  }

  static const List<ClubDocumentType> documentTypes = [
    ClubDocumentType(
      extension: 'pdf',
      mimeType: 'application/pdf',
      kind: DocumentKind.pdf,
    ),
    ClubDocumentType(
      extension: 'doc',
      mimeType: 'application/msword',
      kind: DocumentKind.word,
    ),
    ClubDocumentType(
      extension: 'docx',
      mimeType: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      kind: DocumentKind.word,
    ),
    ClubDocumentType(
      extension: 'xls',
      mimeType: 'application/vnd.ms-excel',
      kind: DocumentKind.excel,
    ),
    ClubDocumentType(
      extension: 'xlsx',
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      kind: DocumentKind.excel,
    ),
    ClubDocumentType(
      extension: 'ppt',
      mimeType: 'application/vnd.ms-powerpoint',
      kind: DocumentKind.powerpoint,
    ),
    ClubDocumentType(
      extension: 'pptx',
      mimeType: 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      kind: DocumentKind.powerpoint,
    ),
  ];

  static List<String> get documentExtensions => [
    for (final type in documentTypes) type.extension,
  ];

  static ClubDocumentType? documentTypeForName(String name) {
    final dot = name.lastIndexOf('.');
    if (dot < 0 || dot == name.length - 1) return null;
    final extension = name.substring(dot + 1).toLowerCase();
    for (final type in documentTypes) {
      if (type.extension == extension) return type;
    }
    return null;
  }

  static ClubDocumentType? documentTypeForMime(String? mimeType) {
    if (mimeType == null || mimeType.isEmpty) return null;
    for (final type in documentTypes) {
      if (type.mimeType == mimeType) return type;
    }
    return null;
  }

  /// A bejegyzés célközönsége. A [AudienceOption.key] kerül a `posts.audience` listába.
  static const List<AudienceOption> audiences = [
    AudienceOption(
      key: 'all',
      emoji: '🌐',
      label: 'Minden tag',
      description: 'A klub minden aktív tagja',
    ),
    AudienceOption(
      key: 'staff',
      emoji: '🥋',
      label: 'Edzők és adminok',
      description: 'Csak a vezetőség',
    ),
    AudienceOption(
      key: 'parents',
      emoji: '👨‍👩‍👧',
      label: 'Szülők',
      description: 'A szülők és a vezetőség',
    ),
    AudienceOption(
      key: 'athletes',
      emoji: '🏃',
      label: 'Sportolók',
      description: 'A sportolók és a vezetőség',
    ),
  ];

  /// A szerkesztőben látható célközönségek. 18 év feletti klubban nincs „Szülők”.
  static List<AudienceOption> get visibleAudiences => enforceAdultsOnly
      ? [
          for (final option in audiences)
            if (option.key != 'parents') option,
        ]
      : audiences;

  static AudienceOption? audienceByKey(String key) {
    for (final option in audiences) {
      if (option.key == key) return option;
    }
    return null;
  }

  /// A szerkesztő címkéje, például „🥋 Edzők és adminok”.
  static String audienceChipLabel(List<String> keys) {
    if (keys.isEmpty || keys.contains('all')) {
      return '🌐 Minden tag';
    }
    return [
      for (final option in audiences)
        if (option.key != 'all' && keys.contains(option.key))
          '${option.emoji} ${option.label}',
    ].join(', ');
  }

  /// A kártya lakatfelirata, például „Edzők és adminok”.
  static String audienceLockLabel(List<String> keys) {
    return [
      for (final option in audiences)
        if (option.key != 'all' && keys.contains(option.key)) option.label,
    ].join(', ');
  }
}

/// Egy választható célközönség a szerkesztő lapján.
class AudienceOption {
  const AudienceOption({
    required this.key,
    required this.emoji,
    required this.label,
    required this.description,
  });

  final String key;
  final String emoji;
  final String label;
  final String description;
}

/// Egy övfokozat. A [key] kerül a `users.beltRank` mezőbe.
class BeltGrade {
  const BeltGrade({
    required this.key,
    required this.label,
    required this.beltName,
    required this.color,
    this.stripe,
  });

  final String key;
  final String label;
  final String beltName;
  final Color color;
  final Color? stripe;

  /// Például „5. kyu – kék öv”.
  String get caption => '$label – $beltName';
}

enum DocumentKind { pdf, word, excel, powerpoint }

class ClubDocumentType {
  const ClubDocumentType({
    required this.extension,
    required this.mimeType,
    required this.kind,
  });

  final String extension;
  final String mimeType;
  final DocumentKind kind;
}
