import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/kdbx/kdbx_service.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vault = ref.watch(currentVaultProvider);
    final entriesCount = vault?.file.body.rootGroup.getAllEntries().length ?? 0;
    final groupsCount = vault?.file.body.rootGroup.getAllGroups().length ?? 0;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Password Manager'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Blocca',
            icon: const Icon(Icons.lock_outline),
            onPressed: () =>
                ref.read(currentVaultProvider.notifier).state = null,
          ),
          IconButton(
            tooltip: 'Impostazioni',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _Tile(
            icon: Icons.key_outlined,
            title: 'Voci',
            subtitle: '$entriesCount totali',
            onTap: () => context.go('/entries'),
          ),
          _Tile(
            icon: Icons.folder_outlined,
            title: 'Gruppi',
            subtitle: '$groupsCount totali',
            onTap: () => context.go('/groups'),
          ),
          _Tile(
            icon: Icons.search,
            title: 'Cerca',
            onTap: () => context.go('/search'),
          ),
          _Tile(
            icon: Icons.casino_outlined,
            title: 'Generatore password',
            onTap: () => context.go('/password-gen'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/entries/new'),
        icon: const Icon(Icons.add),
        label: const Text('Nuova voce'),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
