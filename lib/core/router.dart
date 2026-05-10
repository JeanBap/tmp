import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/entries/entries_list_screen.dart';
import '../features/entries/entry_detail_screen.dart';
import '../features/entries/entry_form_screen.dart';
import '../features/groups/groups_screen.dart';
import '../features/home/home_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/password_gen/password_gen_screen.dart';
import '../features/search/search_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/unlock/unlock_screen.dart';
import '../features/vault/vault_selector_screen.dart';
import 'auth/auto_lock_manager.dart';
import 'kdbx/kdbx_service.dart';

/// Router globale dell'app.
///
/// Logica di redirect (sicurezza):
/// - Se non c'è un vault selezionato (`vaultPath` null) -> `/vault`.
/// - Se c'è un vault ma non è sbloccato (`currentVaultProvider == null`)
///   -> `/unlock`.
/// - Una volta sbloccato, l'utente può accedere alle rotte autenticate
///   (/, /entries, /groups, /search, /password-gen, /settings).
final selectedVaultPathProvider = StateProvider<String?>((ref) => null);
final hasSeenOnboardingProvider = StateProvider<bool>((ref) => false);

final appRouterProvider = Provider<GoRouter>((ref) {
  // Tieni vivo l'auto-lock manager finché il router esiste.
  ref.watch(autoLockManagerProvider);

  return GoRouter(
    initialLocation: '/onboarding',
    refreshListenable: _RouterRefresh(ref),
    redirect: (context, state) {
      final seen = ref.read(hasSeenOnboardingProvider);
      final vaultPath = ref.read(selectedVaultPathProvider);
      final unlocked = ref.read(currentVaultProvider) != null;
      final loc = state.matchedLocation;

      if (!seen && loc != '/onboarding') return '/onboarding';
      if (seen && loc == '/onboarding') return '/vault';
      if (vaultPath == null && loc != '/vault' && loc != '/onboarding') {
        return '/vault';
      }
      if (vaultPath != null && !unlocked && loc != '/unlock' && loc != '/vault') {
        return '/unlock';
      }
      if (unlocked && (loc == '/unlock' || loc == '/vault' || loc == '/onboarding')) {
        return '/';
      }
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/vault',
        builder: (_, __) => const VaultSelectorScreen(),
      ),
      GoRoute(
        path: '/unlock',
        builder: (_, __) => const UnlockScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (_, __) => const HomeScreen(),
        routes: <RouteBase>[
          GoRoute(
            path: 'entries',
            builder: (_, __) => const EntriesListScreen(),
            routes: <RouteBase>[
              GoRoute(
                path: 'new',
                builder: (_, __) => const EntryFormScreen(entryUuid: null),
              ),
              GoRoute(
                path: ':uuid',
                builder: (_, s) =>
                    EntryDetailScreen(entryUuid: s.pathParameters['uuid']!),
              ),
              GoRoute(
                path: ':uuid/edit',
                builder: (_, s) =>
                    EntryFormScreen(entryUuid: s.pathParameters['uuid']),
              ),
            ],
          ),
          GoRoute(
            path: 'groups',
            builder: (_, __) => const GroupsScreen(),
          ),
          GoRoute(
            path: 'search',
            builder: (_, __) => const SearchScreen(),
          ),
          GoRoute(
            path: 'password-gen',
            builder: (_, __) => const PasswordGenScreen(),
          ),
          GoRoute(
            path: 'settings',
            builder: (_, __) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});

/// Ricarica il router quando cambiano i provider chiave di auth/vault.
class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(this._ref) {
    _ref.listen(currentVaultProvider, (_, __) => notifyListeners());
    _ref.listen(selectedVaultPathProvider, (_, __) => notifyListeners());
    _ref.listen(hasSeenOnboardingProvider, (_, __) => notifyListeners());
  }
  final Ref _ref;
}
