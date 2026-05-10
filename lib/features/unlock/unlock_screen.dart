import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_service.dart';
import '../../core/kdbx/kdbx_service.dart';
import '../../core/router.dart';
import '../../l10n/generated/app_localizations.dart';

/// Schermata di sblocco del vault.
///
/// Sicurezza:
/// - La master password viene gestita in memoria stretta (TextEditingController)
///   e mai loggata.
/// - In caso di password errata mostriamo un messaggio generico
///   (`errorWrongPassword`) senza differenziare tra "password sbagliata" e
///   "file corrotto", per evitare oracoli.
/// - Il bottone biometrico è attivo solo se l'utente ha precedentemente
///   memorizzato la master password per quel vault.
class UnlockScreen extends ConsumerStatefulWidget {
  const UnlockScreen({super.key});
  @override
  ConsumerState<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends ConsumerState<UnlockScreen> {
  final _ctrl = TextEditingController();
  bool _busy = false;
  String? _error;
  bool _canBiometric = false;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final vaultPath = ref.read(selectedVaultPathProvider);
    if (vaultPath == null) return;
    final svc = ref.read(authServiceProvider);
    final available = await svc.isBiometricAvailable();
    final has = await svc.hasRemembered(vaultPath: vaultPath);
    if (mounted) setState(() => _canBiometric = available && has);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit(String password) async {
    final t = AppLocalizations.of(context);
    final vaultPath = ref.read(selectedVaultPathProvider);
    if (vaultPath == null) {
      context.go('/vault');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final svc = ref.read(kdbxServiceProvider);
      final file = await svc.openFile(path: vaultPath, masterPassword: password);
      ref.read(currentVaultProvider.notifier).state =
          CurrentVault(file: file, path: vaultPath);
      if (mounted) context.go('/');
    } on WrongMasterPasswordException {
      if (mounted) setState(() => _error = t.errorWrongPassword);
    } on Object {
      if (mounted) setState(() => _error = t.errorGeneric);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _biometricUnlock() async {
    final vaultPath = ref.read(selectedVaultPathProvider);
    if (vaultPath == null) return;
    final svc = ref.read(authServiceProvider);
    final pwd = await svc.retrieveMasterPassword(vaultPath: vaultPath);
    if (pwd == null) return;
    await _submit(pwd);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.actionUnlock)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: _ctrl,
              obscureText: true,
              autofocus: true,
              decoration: InputDecoration(
                labelText: t.unlockEnterMasterPassword,
                errorText: _error,
              ),
              onSubmitted: _busy ? null : _submit,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : () => _submit(_ctrl.text),
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(t.actionUnlock),
            ),
            if (_canBiometric) ...<Widget>[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.fingerprint),
                label: Text(t.unlockBiometric),
                onPressed: _busy ? null : _biometricUnlock,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
