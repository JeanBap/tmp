import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import 'core/providers/settings_provider.dart';
import 'core/router.dart';
import 'l10n/generated/app_localizations.dart';
import 'theme/app_theme.dart';

/// Entry point dell'applicazione "Password Manager".
///
/// Note di sicurezza all'avvio:
/// - Forziamo orientamento portrait per ridurre la superficie di
///   "shoulder surfing".
/// - FLAG_SECURE è impostato lato nativo (vedere `MainActivity.kt`).
///   Da Dart si può solo richiederlo via platform channel, ma è sempre meglio
///   averlo già attivo dal primo frame.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((rec) {
    // Niente segreti nei log: ci aspettiamo che gli altri moduli siano puliti.
    // ignore: avoid_print
    print('[${rec.level.name}] ${rec.loggerName}: ${rec.message}');
  });

  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);
  runApp(const ProviderScope(child: PasswordManagerApp()));
}

class PasswordManagerApp extends ConsumerWidget {
  const PasswordManagerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    return MaterialApp.router(
      title: 'Password Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      locale: locale,
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
