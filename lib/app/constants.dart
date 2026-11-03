import 'package:flutter/material.dart';

import 'club_config.dart';

/// A Subli márkaszínei. A kanonikus értékek a [ClubConfig]-ban vannak.
///
/// A [brandRed] nagy felület és díszítés. A gombok és az aktív ikonok a
/// [primary] színt használják, mert a fehér felirat azon éri el az 5,0:1-et.
abstract final class AppColors {
  static const Color brandRed = ClubConfig.brandRed;
  static const Color primary = ClubConfig.primary;
  static const Color onPrimary = ClubConfig.onPrimary;
  static const Color primaryContainer = ClubConfig.primaryContainer;
  static const Color onPrimaryContainer = ClubConfig.onPrimaryContainer;
  static const Color error = ClubConfig.error;

  /// Meglévő kiemelések a gombpirosra mutatnak.
  static const Color burgundy = primary;

  /// Sötét piros felirat a halvány rózsaszín felületen.
  static const Color burgundyDark = onPrimaryContainer;

  /// Halvány rózsaszín felület.
  static const Color burgundyLight = primaryContainer;

  /// Sötét felületen a logó pirosa. A #121212-n a kontraszt 4,8:1.
  static const Color burgundyDarkMode = brandRed;

  /// Kiegészítő zöld.
  static const Color accentGreen = Color(0xFF2E7D32);

  /// Kiegészítő arany.
  static const Color gold = Color(0xFFC9A227);

  /// Halvány arany felület.
  static const Color goldLight = Color(0xFFF6EBC8);

  /// A téma kapcsoló sötét sínjének bal színe.
  static const Color themeTrackNight = Color(0xFF2A1A2E);

  /// A sötét állású csúszógomb.
  static const Color themeKnobDark = Color(0xFF2B2930);

  /// Arany szöveg sötét felületen. A #C9A227 a sötét kártyán is átmegy,
  /// ez a világosabb változat a kiemeléshez.
  static const Color goldDark = Color(0xFFE6C35C);

  /// Halvány arany felület sötét módban.
  static const Color goldDarkSurface = Color(0xFF3A3118);

  /// A közzététel gomb átmenete. Mindegyiken a fehér felirat eléri a 4,5:1-et.
  static const Color gradientStart = Color(0xFFA31B22);
  static const Color gradientMid = primary;
  static const Color gradientEnd = onPrimaryContainer;

  /// Médiagombok: erős ikon és halvány háttér.
  static const Color mediaPhoto = Color(0xFF2E7D32);
  static const Color mediaPhotoBackground = Color(0xFFE6F4EA);
  static const Color mediaVideo = Color(0xFFD1435B);
  static const Color mediaVideoBackground = Color(0xFFFCE8EC);
  static const Color mediaCamera = Color(0xFF2D6CDF);
  static const Color mediaCameraBackground = Color(0xFFE7EFFC);

  /// Sötét módbeli médiagombok. A szöveg és a háttér kontrasztja WCAG AA.
  static const Color mediaPhotoDark = Color(0xFF8FD9A0);
  static const Color mediaPhotoDarkBackground = Color(0xFF163322);
  static const Color mediaVideoDark = Color(0xFFFFB0BE);
  static const Color mediaVideoDarkBackground = Color(0xFF3A1824);
  static const Color mediaCameraDark = Color(0xFFA9C7FF);
  static const Color mediaCameraDarkBackground = Color(0xFF15233F);

  /// Inaktív közzététel gomb. A felirat mindkét módban AA kontrasztú.
  static const Color publishDisabled = Color(0xFFE4DFE1);
  static const Color onPublishDisabled = Color(0xFF4E4A4C);
  static const Color publishDisabledDark = Color(0xFF3A3638);
  static const Color onPublishDisabledDark = Color(0xFFF2EEEF);

  /// Világos mód alapja.
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);

  /// A hírfolyam oldala, a kártyák közötti rés.
  static const Color feedBackground = Color(0xFFF0F1F3);

  /// Bejegyzéskártya világos módban.
  static const Color feedCard = Color(0xFFFFFFFF);

  /// Lekerekített mező és hozzászólás-buborék.
  static const Color feedField = Color(0xFFE6E0E2);

  /// Másodlagos, szürke felirat a hírfolyamon.
  static const Color feedMuted = Color(0xFF6E6A6C);

  /// Hírfolyam háttere sötét módban.
  static const Color feedDarkBackground = Color(0xFF141214);

  /// Bejegyzéskártya sötét módban.
  static const Color feedDarkCard = Color(0xFF221F21);

  /// Mező és buborék sötét módban.
  static const Color feedDarkField = Color(0xFF2C2A2B);

  /// Világos mód szövegszíne.
  static const Color text = Color(0xFF1C1B1F);

  /// Sötét mód felülete és AppBar háttere.
  static const Color darkSurface = Color(0xFF121212);

  /// Sötét mód szövege a #121212 felületen.
  static const Color darkOnSurface = Color(0xFFF2EEEF);

  /// Hibaszöveg sötét felületen. A [error] ott csak 3,7:1 lenne.
  static const Color errorOnDark = Color(0xFFD97706);

  /// Sötét módban a gomb felirata. A fehér a [brandRed]on csak 3,9:1 lenne.
  static const Color darkOnPrimary = Color(0xFF000000);

  /// Világos AppBar alatti elválasztó vonal.
  static const Color appBarDivider = Color(0xFFE6E0E2);
}

/// Az app útvonalai.
abstract final class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String resetPassword = '/login/reset';
  static const String register = '/register';
  static const String pending = '/pending';
  static const String feed = '/feed';
  static const String newPost = '/feed/new';

  static String feedPost(String id) => '/feed/$id';

  static String editPost(String id) => '/feed/$id/edit';
  static const String chat = '/chat';
  static const String newMessage = '/chat/new';

  static String conversation(String id) => '/chat/$id';
  static const String profile = '/profile';

  static String member(String id) => '/members/$id';
  static const String calendar = '/calendar';
  static const String admin = '/admin';
  static const String members = '/admin/members';
  static const String groups = '/admin/groups';
  static const String suspended = '/suspended';

  static String memberAdmin(String id) => '/admin/members/$id';
}

/// Közös, a felületen megjelenő nevek. A forrás a [ClubConfig].
abstract final class AppInfo {
  static const String clubName = ClubConfig.clubName;

  /// Szűk fejlécen ennyi fér ki a klubnévből.
  static const String clubNameShort = ClubConfig.clubNameShort;
}
