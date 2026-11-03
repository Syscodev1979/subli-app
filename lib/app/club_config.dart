import 'package:flutter/material.dart';

/// A klub megjelenéséhez és szabályaihoz tartozó, kódban rögzített értékek.
///
/// A lovas szintek és a dokumentumtípusok itt cserélhetők, ha a klub mást használ.
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

  /// Az egyetlen admin e-mail, kisbetűsen tárolva. Az összehasonlítás a
  /// bejövő címet is kisbetűsíti. Ugyanez a szöveg szerepel a Firestore és a
  /// Storage szabályokban, valamint a Cloud Functionsben.
  /// Lásd a docs/UJ_KLUB.md fájlt.
  static const String adminEmail = 'info@sarosigyorgy.hu';

  /// Az iOS alkalmazás minimum verziója.
  static const String iosMinimumVersion = '15.0';

  static const int avatarSize = 512;
  static const int avatarQuality = 85;
  static const int maxAvatarBytes = 5 * 1024 * 1024;
  static const int maxDocumentBytes = 20 * 1024 * 1024;
  static const int maxDocumentsPerPost = 5;

  /// Lovas szintek. A [key] a `users.beltRank` mezőbe kerül,
  /// a régi övfokozat-mechanizmussal. A felirat a szint neve.
  static const List<BeltGrade> belts = [
    BeltGrade(
      key: 'beginner',
      label: 'Kezdő',
      beltName: '',
      color: Color(0xFF2E7D32),
    ),
    BeltGrade(
      key: 'advanced',
      label: 'Haladó',
      beltName: '',
      color: Color(0xFF1F6FEB),
    ),
    BeltGrade(
      key: 'competitor',
      label: 'Versenyző',
      beltName: '',
      color: Color(0xFF6B1E2E),
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

/// Egy lovas szint. A [key] kerül a `users.beltRank` mezőbe.
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

  /// Üres [beltName] esetén csak a szint neve, különben „cím – név”.
  String get caption => beltName.isEmpty ? label : '$label – $beltName';
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
