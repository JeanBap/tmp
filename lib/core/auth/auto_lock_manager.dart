import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../kdbx/kdbx_service.dart';
import '../providers/settings_provider.dart';

final _log = Logger('AutoLockManager');

/// Gestore di Auto-Lock per il vault.
///
/// Sicurezza:
/// - Si osservano due segnali: ciclo di vita dell'app (`AppLifecycleState`)
///   e inattività dell'utente (timer resettato a ogni interazione).
/// - Quando l'app va in `paused` / `hidden` / `inactive` viene lanciato il
///   timer di lock; se l'utente non rientra in `resumed` entro il timeout
///   il vault è bloccato.
/// - Quando l'app è in foreground ma non viene toccata per `timeout`,
///   il vault viene bloccato comunque (idle).
/// - Lock = rimuovere il `KdbxFile` dalla memoria: lo state provider passa a
///   `null` e il GoRouter ridireziona automaticamente a `/unlock`.
///   I `ProtectedValue` interni vengono comunque GC-ati.
class AutoLockManager with WidgetsBindingObserver {
  AutoLockManager(this._ref);

  final Ref _ref;
  Timer? _idleTimer;
  Timer? _backgroundTimer;

  void start() {
    WidgetsBinding.instance.addObserver(this);
    _resetIdleTimer();
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _idleTimer?.cancel();
    _backgroundTimer?.cancel();
  }

  /// Da chiamare a ogni gesto utente significativo (es. da un `Listener`
  /// avvolto attorno al `MaterialApp.router`).
  void notifyInteraction() {
    _resetIdleTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.inactive:
        _startBackgroundTimer();
      case AppLifecycleState.resumed:
        _backgroundTimer?.cancel();
        _resetIdleTimer();
      case AppLifecycleState.detached:
        _lockNow('detached');
    }
  }

  Duration get _timeout {
    final secs = _ref.read(autoLockTimeoutSecondsProvider);
    return Duration(seconds: secs);
  }

  void _resetIdleTimer() {
    _idleTimer?.cancel();
    final t = _timeout;
    if (t == Duration.zero) return; // 0 = disabilitato
    _idleTimer = Timer(t, () => _lockNow('idle'));
  }

  void _startBackgroundTimer() {
    _backgroundTimer?.cancel();
    final t = _timeout;
    if (t == Duration.zero) return;
    _backgroundTimer = Timer(t, () => _lockNow('background'));
  }

  void _lockNow(String reason) {
    final current = _ref.read(currentVaultProvider);
    if (current == null) return;
    _log.info('Locking vault (reason=$reason)');
    _ref.read(currentVaultProvider.notifier).state = null;
  }
}

final autoLockManagerProvider = Provider<AutoLockManager>((ref) {
  final manager = AutoLockManager(ref);
  manager.start();
  ref.onDispose(manager.dispose);
  return manager;
});
