import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kdbx/kdbx.dart';

import '../../core/kdbx/kdbx_service.dart';

class EntryFormScreen extends ConsumerStatefulWidget {
  const EntryFormScreen({super.key, required this.entryUuid});

  /// `null` = creazione, altrimenti modifica.
  final String? entryUuid;

  @override
  ConsumerState<EntryFormScreen> createState() => _EntryFormState();
}

class _EntryFormState extends ConsumerState<EntryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _user = TextEditingController();
  final _password = TextEditingController();
  final _url = TextEditingController();
  final _notes = TextEditingController();
  final _otp = TextEditingController();
  KdbxEntry? _existing;

  @override
  void initState() {
    super.initState();
    final vault = ref.read(currentVaultProvider);
    if (widget.entryUuid != null && vault != null) {
      _existing = vault.file.body.rootGroup
          .getAllEntries()
          .firstWhere(
            (e) => e.uuid.uuid == widget.entryUuid,
            orElse: () => throw StateError('entry not found'),
          );
      _title.text = _existing!.getString(KdbxKeyCommon.TITLE)?.getText() ?? '';
      _user.text = _existing!.getString(KdbxKeyCommon.USER_NAME)?.getText() ?? '';
      _password.text = _existing!.getString(KdbxKeyCommon.PASSWORD)?.getText() ?? '';
      _url.text = _existing!.getString(KdbxKeyCommon.URL)?.getText() ?? '';
      _notes.text = _existing!.getString(KdbxKey('Notes'))?.getText() ?? '';
      _otp.text = _existing!.getString(KdbxKey('otp'))?.getText() ?? '';
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _user.dispose();
    _password.dispose();
    _url.dispose();
    _notes.dispose();
    _otp.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final vault = ref.read(currentVaultProvider);
    if (vault == null) return;

    KdbxEntry entry;
    if (_existing == null) {
      final parent = vault.file.body.rootGroup;
      entry = KdbxEntry.create(vault.file, parent);
      parent.addEntry(entry);
    } else {
      entry = _existing!;
    }
    entry.setString(KdbxKeyCommon.TITLE, PlainValue(_title.text));
    entry.setString(KdbxKeyCommon.USER_NAME, PlainValue(_user.text));
    entry.setString(
      KdbxKeyCommon.PASSWORD,
      ProtectedValue.fromString(_password.text),
    );
    entry.setString(KdbxKeyCommon.URL, PlainValue(_url.text));
    entry.setString(KdbxKey('Notes'), PlainValue(_notes.text));
    if (_otp.text.trim().isNotEmpty) {
      entry.setString(KdbxKey('otp'), ProtectedValue.fromString(_otp.text.trim()));
    }

    await ref.read(kdbxServiceProvider).save(vault.file, vault.path);
    if (mounted) context.go('/entries');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_existing == null ? 'Nuova voce' : 'Modifica voce'),
        actions: <Widget>[
          IconButton(icon: const Icon(Icons.check), onPressed: _save),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Titolo'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Obbligatorio' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _user,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _url,
              decoration: const InputDecoration(labelText: 'URL'),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              decoration: const InputDecoration(labelText: 'Note'),
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _otp,
              decoration: const InputDecoration(
                labelText: 'OTP URI (otpauth://...)',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
