import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kdbx/kdbx.dart';

import '../../core/auth/clipboard_guard.dart';
import '../../core/kdbx/kdbx_service.dart';
import '../password_gen/totp_viewer.dart';

class EntryDetailScreen extends ConsumerStatefulWidget {
  const EntryDetailScreen({super.key, required this.entryUuid});
  final String entryUuid;
  @override
  ConsumerState<EntryDetailScreen> createState() => _EntryDetailState();
}

class _EntryDetailState extends ConsumerState<EntryDetailScreen> {
  bool _showPassword = false;

  KdbxEntry? _find(WidgetRef ref) {
    final vault = ref.read(currentVaultProvider);
    if (vault == null) return null;
    for (final e in vault.file.body.rootGroup.getAllEntries()) {
      if (e.uuid.uuid == widget.entryUuid) return e;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final entry = _find(ref);
    if (entry == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Voce non trovata')),
      );
    }
    final title = entry.getString(KdbxKeyCommon.TITLE)?.getText() ?? '';
    final user = entry.getString(KdbxKeyCommon.USER_NAME)?.getText() ?? '';
    final password = entry.getString(KdbxKeyCommon.PASSWORD)?.getText() ?? '';
    final url = entry.getString(KdbxKeyCommon.URL)?.getText() ?? '';
    final notes = entry.getString(KdbxKeyCommon.NOTES)?.getText() ?? '';
    final otpUri = entry.getString(KdbxKey('otp'))?.getText() ??
        entry.getString(KdbxKey('TOTP Seed'))?.getText() ??
        '';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.go('/entries/${widget.entryUuid}/edit'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          if (user.isNotEmpty)
            _Field(label: 'Username', value: user, onCopy: () => _copy(user)),
          _Field(
            label: 'Password',
            value: _showPassword ? password : '•' * password.length,
            sensitive: true,
            onCopy: () => _copy(password),
            trailing: IconButton(
              icon: Icon(_showPassword
                  ? Icons.visibility_off
                  : Icons.visibility),
              onPressed: () => setState(() => _showPassword = !_showPassword),
            ),
          ),
          if (url.isNotEmpty)
            _Field(label: 'URL', value: url, onCopy: () => _copy(url)),
          if (notes.isNotEmpty)
            _Field(label: 'Note', value: notes, onCopy: () => _copy(notes)),
          if (otpUri.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: TotpViewer(otpAuthUri: otpUri),
            ),
          // Campi personalizzati
          for (final k in entry.stringEntries
              .where((kv) => !_isStandard(kv.key)))
            _Field(
              label: k.key.key,
              value: k.value?.getText() ?? '',
              sensitive: k.value?.isProtected ?? false,
              onCopy: () => _copy(k.value?.getText() ?? ''),
            ),
        ],
      ),
    );
  }

  bool _isStandard(KdbxKey k) {
    return <String>{'Title', 'UserName', 'Password', 'URL', 'Notes', 'otp'}
        .contains(k.key);
  }

  Future<void> _copy(String value) async {
    await ref.read(clipboardGuardProvider).copySensitive(value);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Copiato. Sarà cancellato automaticamente.')),
      );
    }
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.value,
    required this.onCopy,
    this.sensitive = false,
    this.trailing,
  });
  final String label;
  final String value;
  final bool sensitive;
  final VoidCallback onCopy;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(label, style: Theme.of(context).textTheme.labelMedium),
        subtitle: Text(
          value,
          style: TextStyle(
            fontFamily: sensitive ? 'monospace' : null,
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (trailing != null) trailing!,
            IconButton(
              icon: const Icon(Icons.copy_outlined),
              onPressed: onCopy,
            ),
          ],
        ),
      ),
    );
  }
}
