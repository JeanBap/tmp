import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kdbx/kdbx.dart';

import '../../core/kdbx/kdbx_service.dart';

class EntriesListScreen extends ConsumerWidget {
  const EntriesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vault = ref.watch(currentVaultProvider);
    final entries = vault?.file.body.rootGroup.getAllEntries().toList() ?? <KdbxEntry>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Voci')),
      body: entries.isEmpty
          ? const Center(child: Text('Nessuna voce'))
          : ListView.separated(
              itemCount: entries.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final e = entries[i];
                final title = e.getString(KdbxKeyCommon.TITLE)?.getText() ?? '(senza titolo)';
                final user = e.getString(KdbxKeyCommon.USER_NAME)?.getText() ?? '';
                return ListTile(
                  leading: const Icon(Icons.key_outlined),
                  title: Text(title),
                  subtitle: user.isEmpty ? null : Text(user),
                  onTap: () => context.go('/entries/${e.uuid.uuid}'),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/entries/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
