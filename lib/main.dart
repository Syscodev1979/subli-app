import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gastroyal_karate_app/firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/constants.dart';
import 'app/router.dart';
import 'app/theme.dart';
import 'app/theme_controller.dart';
import 'app/theme_preference.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('hu');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final prefs = await SharedPreferences.getInstance();
  final initial = ThemePreference.fromStorage(
    prefs.getString(ThemeController.storageKey),
  );
  runApp(
    ProviderScope(
      overrides: [
        themePreferenceProvider.overrideWith(
          () => ThemeController(initial: initial, preloaded: true),
        ),
      ],
      child: const GastroyalApp(),
    ),
  );
}

/// Az app gyökere: magyar lokalizáció, világos és sötét téma, go_router.
class GastroyalApp extends ConsumerWidget {
  const GastroyalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final preference = ref.watch(themePreferenceProvider);

    return MaterialApp.router(
      title: AppInfo.clubName,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: preference.themeMode,
      builder: (context, child) {
        final dark = Theme.of(context).brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
            statusBarBrightness: dark ? Brightness.dark : Brightness.light,
          ),
          child: AnimatedTheme(
            data: Theme.of(context),
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      routerConfig: router,
      locale: const Locale('hu', 'HU'),
      supportedLocales: const [Locale('hu', 'HU')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
