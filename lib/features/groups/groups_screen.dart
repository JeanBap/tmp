import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kdbx/kdbx.dart';

import '../../core/kdbx/kdbx_service.dart';

/// Vista ad albero dei gruppi (cartelle KeePass).
///
/// CRUD: aggiungi/rinomina/elimina/sposta sottogruppi.
class GroupsScreen extends ConsumerStatefulWidget {
  const GroupsScreen({super.key});
  @override
  ConsumerState<GroupsScreen> createState() => _GroupsState();
}

class _GroupsState extends ConsumerState<GroupsScreen> {
  @override
  Widget build(BuildContext context) {
    final vault = ref.watch(currentVaultProvider);
    if (vault == null) {
      return const Scaffold(body: Center(child: Text('Vault non aperto')));
    }
    final root = vault.file.body.rootGroup;
    return Scaffold(
      appBar: AppBar(title: const Text('Gruppi')),
      body: ListView(
        children: <Widget>[_groupTile(context, root, depth: 0)],
      ),
    );
  }

  Widget _groupTile(BuildContext context, KdbxGroup g, {required int depth}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(left: 16.0 + depth * 16),
          child: ListTile(
            leading: const Icon(Icons.folder_outlined),
            title: Text(g.name.get() ?? ''),
            subtitle: Text('${g.entries.length} voci, ${g.groups.length} gruppi'),
            trailing: PopupMenuButton<String>(
              onSelected: (v) => _menu(g, v),
              itemBuilder: (_) => const <PopupMenuEntry<String>>[
                PopupMenuItem(value: 'add', child: Text('Aggiungi sottogruppo')),
                PopupMenuItem(value: 'rename', child: Text('Rinomina')),
                PopupMenuItem(value: 'delete', child: Text('Elimina')),
              ],
            ),
          ),
        ),
        for (final child in g.groups)
          _groupTile(context, child, depth: depth + 1),
      ],
    );
  }

  Future<void> _menu(KdbxGroup g, String action) async {
    final vault = ref.read(currentVaultProvider)!;
    switch (action) {
      case 'add':
        final name = await _prompt('Nome sottogruppo');
        if (name == null) return;
        vault.file.createGroup(parent: g, name: name);
      case 'rename':
        final name = await _prompt('Nuovo nome', initial: g.name.get() ?? '');
        if (name == null) return;
        g.name.set(name);
      case 'delete':
        if (g.parent == null) return; // niente delete sulla root
        vault.file.deleteGroup(g);
    }
    await ref.read(kdbxServiceProvider).save(vault.file, vault.path);
    if (mounted) setState(() {});
  }

  Future<String?> _prompt(String label, {String initial = ''}) async {
    final ctrl = TextEditingController(text: initial);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(label),
        content: TextField(controller: ctrl, autofocus: true),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annulla')),
          FilledButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    return (result == null || result.isEmpty) ? null : result;
  }
}
