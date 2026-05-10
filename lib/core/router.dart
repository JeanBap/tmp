import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Router temporaneo per Fase 1.
/// Verrà esteso in Fase 2 con tutte le rotte feature-first
/// (/onboarding, /vault, /unlock, /home, /entries, /groups, /search, ...).
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (context, state) => const _PlaceholderHome(),
      ),
    ],
  );
});

class _PlaceholderHome extends StatelessWidget {
  const _PlaceholderHome();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Password Manager')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Fase 1 completata.\n\n'
            'Le schermate verranno aggiunte nelle fasi successive.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
