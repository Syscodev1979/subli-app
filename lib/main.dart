import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app_flavor.dart';
import 'app/emulator.dart';
import 'app/firebase_bootstrap.dart';
import 'app/firebase_setup_screen.dart';
import 'app/router.dart';
import 'app/theme.dart';
import 'app/theme_controller.dart';
import 'app/theme_preference.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('hu');
  final options = useFirebaseEmulator
      ? emulatorFirebaseOptions()
      : firebaseOptionsForCurrentFlavor();
  if (options == null) {
    runApp(const FirebaseSetupScreen());
    return;
  }
  await Firebase.initializeApp(options: options);
  if (useFirebaseEmulator) {
    await connectFirebaseEmulators();
  } else {
    await startCrashReporting();
    FirebaseAuth.instance.authStateChanges().listen((user) {
      setCrashlyticsUser(user?.uid);
    });
  }
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
      child: const SubliApp(),
    ),
  );
}

/// Az app gyökere: magyar lokalizáció, világos és sötét téma, go_router.
class SubliApp extends ConsumerWidget {
  const SubliApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final preference = ref.watch(themePreferenceProvider);

    return MaterialApp.router(
      title: AppFlavor.current.appName,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: preference.themeMode,
      builder: (context, child) {
        final dark = Theme.of(context).brightness == Brightness.dark;
        final app = AnnotatedRegion<SystemUiOverlayStyle>(
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
        if (!useFirebaseEmulator) return app;
        return Banner(
          message: 'EMULÁTOR',
          location: BannerLocation.topStart,
          color: const Color(0xFFB45309),
          child: app,
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
