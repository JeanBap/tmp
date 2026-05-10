import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router.dart';
import 'l10n/generated/app_localizations.dart';
import 'theme/app_theme.dart';

/// Entry point dell'applicazione "Password Manager".
///
/// Note di sicurezza all'avvio:
/// - Forziamo orientamento portrait per ridurre la superficie di "shoulder
///   surfing" su tablet che ruotano automaticamente.
/// - FLAG_SECURE è impostato lato nativo (vedere `MainActivity.kt` in Fase 6),
///   non da Dart, per essere attivo dal primo frame.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
    return MaterialApp.router(
      title: 'Password Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
