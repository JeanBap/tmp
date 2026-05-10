import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/kdbx/kdbx_service.dart';
import '../../core/router.dart';
import '../../l10n/generated/app_localizations.dart';

/// Schermata di selezione del vault.
///
/// Sicurezza:
/// - Il file picker apre solo file con estensione `.kdbx`.
/// - La creazione richiede una master password forte (almeno 8 caratteri,
///   validati prima di chiamare il KdbxService).
class VaultSelectorScreen extends ConsumerWidget {
  const VaultSelectorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.vaultSelectTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: <Widget>[
            FilledButton.icon(
              icon: const Icon(Icons.add),
              label: Text(t.vaultCreateNew),
              onPressed: () => _create(context, ref),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.folder_open),
              label: Text(t.vaultOpenExisting),
              onPressed: () => _open(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['kdbx'],
    );
    final path = picked?.files.single.path;
    if (path == null) return;
    ref.read(selectedVaultPathProvider.notifier).state = path;
    if (context.mounted) context.go('/unlock');
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<_CreateData>(
      context: context,
      builder: (_) => const _CreateDialog(),
    );
    if (result == null) return;

    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/${result.name}.kdbx';
    final service = ref.read(kdbxServiceProvider);
    final file = service.createNew(
      name: result.name,
      masterPassword: result.masterPassword,
    );
    await service.save(file, path);

    ref.read(selectedVaultPathProvider.notifier).state = path;
    ref.read(currentVaultProvider.notifier).state =
        CurrentVault(file: file, path: path);
    if (context.mounted) context.go('/');
  }
}

class _CreateData {
  const _CreateData({required this.name, required this.masterPassword});
  final String name;
  final String masterPassword;
}

class _CreateDialog extends StatefulWidget {
  const _CreateDialog();
  @override
  State<_CreateDialog> createState() => _CreateDialogState();
}

class _CreateDialogState extends State<_CreateDialog> {
  final _name = TextEditingController(text: 'MyVault');
  final _pwd = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _name.dispose();
    _pwd.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Crea nuovo vault'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nome'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Obbligatorio' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _pwd,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Master password'),
              validator: (v) => (v == null || v.length < 8)
                  ? 'Minimo 8 caratteri'
                  : null,
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop(
                _CreateData(
                  name: _name.text.trim(),
                  masterPassword: _pwd.text,
                ),
              );
            }
          },
          child: const Text('Crea'),
        ),
      ],
    );
  }
}

