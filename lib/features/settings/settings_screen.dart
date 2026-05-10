import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_service.dart';
import '../../core/csv/csv_service.dart';
import '../../core/kdbx/kdbx_service.dart';
import '../../core/pdf/pdf_service.dart';
import '../../core/providers/settings_provider.dart';
import '../../l10n/generated/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final autoLock = ref.watch(autoLockTimeoutSecondsProvider);
    final clip = ref.watch(clipboardClearSecondsProvider);
    final theme = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.settingsTitle)),
      body: ListView(
        children: <Widget>[
          ListTile(
            title: Text(t.settingsAutoLockTimeout),
            subtitle: Text('$autoLock s'),
            trailing: DropdownButton<int>(
              value: autoLock,
              items: const <DropdownMenuItem<int>>[
                DropdownMenuItem(value: 0, child: Text('Mai')),
                DropdownMenuItem(value: 30, child: Text('30 s')),
                DropdownMenuItem(value: 60, child: Text('1 min')),
                DropdownMenuItem(value: 300, child: Text('5 min')),
                DropdownMenuItem(value: 900, child: Text('15 min')),
              ],
              onChanged: (v) async {
                if (v == null) return;
                ref.read(autoLockTimeoutSecondsProvider.notifier).state = v;
                final repo = await ref.read(settingsRepoProvider.future);
                await repo.setAutoLockSeconds(v);
              },
            ),
          ),
          ListTile(
            title: Text(t.settingsClipboardClearSeconds),
            subtitle: Text('$clip s'),
            trailing: DropdownButton<int>(
              value: clip,
              items: const <DropdownMenuItem<int>>[
                DropdownMenuItem(value: 10, child: Text('10 s')),
                DropdownMenuItem(value: 30, child: Text('30 s')),
                DropdownMenuItem(value: 60, child: Text('1 min')),
              ],
              onChanged: (v) async {
                if (v == null) return;
                ref.read(clipboardClearSecondsProvider.notifier).state = v;
                final repo = await ref.read(settingsRepoProvider.future);
                await repo.setClipboardClearSeconds(v);
              },
            ),
          ),
          ListTile(
            title: Text(t.settingsTheme),
            trailing: DropdownButton<ThemeMode>(
              value: theme,
              items: const <DropdownMenuItem<ThemeMode>>[
                DropdownMenuItem(value: ThemeMode.system, child: Text('Sistema')),
                DropdownMenuItem(value: ThemeMode.light, child: Text('Chiaro')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Scuro')),
              ],
              onChanged: (m) async {
                if (m == null) return;
                ref.read(themeModeProvider.notifier).state = m;
                final repo = await ref.read(settingsRepoProvider.future);
                await repo.setThemeMode(m);
              },
            ),
          ),
          ListTile(
            title: Text(t.settingsLanguage),
            trailing: DropdownButton<String>(
              value: locale?.languageCode ?? '',
              items: const <DropdownMenuItem<String>>[
                DropdownMenuItem(value: '', child: Text('Sistema')),
                DropdownMenuItem(value: 'it', child: Text('Italiano')),
                DropdownMenuItem(value: 'en', child: Text('English')),
              ],
              onChanged: (v) async {
                final newLoc = (v == null || v.isEmpty) ? null : Locale(v);
                ref.read(localeProvider.notifier).state = newLoc;
                final repo = await ref.read(settingsRepoProvider.future);
                await repo.setLocale(newLoc);
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.upload_file_outlined),
            title: const Text('Esporta vault in CSV'),
            onTap: () async {
              final vault = ref.read(currentVaultProvider);
              if (vault == null) return;
              await ref.read(csvServiceProvider).exportVault(vault.file);
            },
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf_outlined),
            title: const Text('Esporta vault in PDF'),
            onTap: () async {
              final vault = ref.read(currentVaultProvider);
              if (vault == null) return;
              await ref.read(pdfServiceProvider).exportVault(vault.file);
            },
          ),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('Importa CSV'),
            onTap: () async {
              final vault = ref.read(currentVaultProvider);
              if (vault == null) return;
              final imported = await ref.read(csvServiceProvider).importIntoVault(vault.file);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Importate $imported voci')),
                );
              }
              await ref.read(kdbxServiceProvider).save(vault.file, vault.path);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.fingerprint),
            title: const Text('Memorizza master password (biometria)'),
            onTap: () async {
              final vault = ref.read(currentVaultProvider);
              if (vault == null) return;
              final pwd = await _promptPwd(context);
              if (pwd == null) return;
              await ref.read(authServiceProvider).rememberMasterPassword(
                    vaultPath: vault.path,
                    masterPassword: pwd,
                  );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Dimentica master password'),
            onTap: () async {
              final vault = ref.read(currentVaultProvider);
              if (vault == null) return;
              await ref.read(authServiceProvider).forget(vaultPath: vault.path);
            },
          ),
        ],
      ),
    );
  }

  Future<String?> _promptPwd(BuildContext context) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Master password'),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          autofocus: true,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, ctrl.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
