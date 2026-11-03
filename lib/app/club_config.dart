import 'package:flutter/material.dart';

import '../features/feed/domain/post_category.dart';

/// A klub megjelenéséhez és szabályaihoz tartozó, kódban rögzített értékek.
///
/// A lovas szintek és a dokumentumtípusok itt cserélhetők, ha a klub mást használ.
abstract final class ClubConfig {
  /// A teljes Subli logó: piros blokk, „Subli”, „PAARDENVOEDERS”.
  static const String logoAsset = 'assets/branding/subli_logo.png';

  /// A logó pirosa. Nagy felületre és díszítésre való. Fehér szöveg alatt
  /// nem használható, mert a kontraszt csak 3,9:1.
  static const Color brandRed = Color(0xFFEF3D42);

  /// Gombok, linkek, aktív ikonok. Fehér felirattal 5,0:1.
  static const Color primary = Color(0xFFD7262B);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFFDE7E8);
  static const Color onPrimaryContainer = Color(0xFF7A1418);

  /// Borostyán, nem piros. Fehér felirattal 5,0:1.
  static const Color error = Color(0xFFB45309);

  /// A fejléc teljes neve.
  static const String clubName = 'Subli – lovas közösségi app';

  /// Szűk fejlécen ennyi fér ki a névből.
  static const String clubNameShort = 'Subli';

  /// A logó alatti cím a belépésen. Null esetén a sor kimarad.
  // A típus szándékosan nullable, hogy egy másik klubnál a sor kimaradhasson.
  // ignore: unnecessary_nullable_for_final_variable_declarations
  static const String? loginTitle = 'Subli Lovas Közösségi App';

  /// A cím alatti támogatói sor. A [loginSponsorUrl] hosztneve a szövegben
  /// link. Null esetén a sor kimarad.
  // ignore: unnecessary_nullable_for_final_variable_declarations
  static const String? loginSponsorText = 'A sublilotapok.hu támogatásával';

  /// A támogatói oldal. Külső böngészőben nyílik. Null esetén a sor nem link.
  // ignore: unnecessary_nullable_for_final_variable_declarations
  static const String? loginSponsorUrl = 'https://sublilotapok.hu';

  /// A regisztráció alatti kredit. Null esetén a sor kimarad.
  // ignore: unnecessary_nullable_for_final_variable_declarations
  static const String? loginCredit = 'Készítette: Sysco System';

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

  /// Egyszerű tagság: minden regisztráló tag, egy admin van, szerepet nem választ.
  /// A Gastroyal hamisra állítja, ott a sportoló, szülő és edző megmarad.
  static const bool simpleMembership = true;

  static bool? debugSimpleMembershipOverride;

  static bool get enforceSimpleMembership =>
      debugSimpleMembershipOverride ?? simpleMembership;

  /// A klub jele. A Gastroyal a mancsot tartja meg.
  static const ClubMark themeIcon = ClubMark.horseshoe;

  /// Választható posztkategóriák, ebben a sorrendben.
  /// A Gastroyal a saját listáját ide írja, nem a közös kódba.
  static const List<PostCategory> postCategories = [
    PostCategory.post,
    PostCategory.announcement,
    PostCategory.event,
    PostCategory.horses,
  ];

  static const PostCategory defaultPostCategory = PostCategory.post;

  /// Csoportos beszélgetés. A Subli csak kétszemélyes chatet enged.
  /// A Gastroyal igazra állítja, ott a viselkedés a régi marad.
  static const bool allowGroupChats = false;

  static bool? debugAllowGroupChatsOverride;

  static bool get groupChatsAllowed =>
      debugAllowGroupChatsOverride ?? allowGroupChats;

  /// 2-nél több tagú beszélgetés a felületen és a kliensen is tilos.
  static void rejectGroupConversation(int memberCount) {
    if (!groupChatsAllowed && memberCount > 2) {
      throw StateError('Csoportos beszélgetés nem hozható létre.');
    }
  }

  /// TODO_SUBLI: a visszajelző cím. Addig senki nem kap levelet.
  static const String feedbackEmail = 'visszajelzes-beallitando@invalid';

  /// Az App Store alkalmazásazonosító. A Frissítés gomb ezt nyitja.
  static const String appStoreAppleId = '6830208527';

  static const String appStoreUrl =
      'https://apps.apple.com/app/id$appStoreAppleId';

  /// TODO_SUBLI: a Google Play oldal. A Frissítés gomb addig ezt nyitja.
  static const String playStoreUrl = 'https://example.invalid/TODO_SUBLI/play';

  /// TODO_SUBLI: adatvédelmi tájékoztató. Külső böngészőben nyílik.
  static const String privacyPolicyUrl =
      'https://example.invalid/TODO_SUBLI/adatvedelem';

  /// TODO_SUBLI: felhasználási feltételek. Külső böngészőben nyílik.
  static const String termsOfUseUrl =
      'https://example.invalid/TODO_SUBLI/feltetelek';

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

  /// A poszt írásakor választható célközönségek.
  /// A Subli csak a „Minden tag”. A Gastroyal a teljes listát adja meg,
  /// és abból a felnőtt szabály továbbra is kiveszi a szülőket.
  static const List<String> selectableAudienceKeys = ['all'];

  static List<String>? debugSelectableAudiencesOverride;

  /// A szerkesztőben látható célközönségek.
  static List<AudienceOption> get visibleAudiences {
    final allowed = debugSelectableAudiencesOverride ?? selectableAudienceKeys;
    final base = enforceAdultsOnly
        ? [
            for (final option in audiences)
              if (option.key != 'parents') option,
          ]
        : audiences;
    return [
      for (final option in base)
        if (allowed.contains(option.key)) option,
    ];
  }

  /// Egy választásnál a célközönség-választó nem jelenik meg.
  static bool get showsAudiencePicker => visibleAudiences.length > 1;

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

/// A klub jele a hírfolyamon és a kategóriáknál.
enum ClubMark { paw, horseshoe }

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
