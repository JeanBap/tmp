import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';

/// Wrapper sicuro per copiare segreti negli appunti.
///
/// Sicurezza:
/// - Imposta `ClipboardData` con `text` semplice (l'API attuale di Flutter non
///   permette flag specifici per "sensitive content" lato Dart — su Android
///   reali andrebbero usati `EXTRA_IS_SENSITIVE` via platform channel).
/// - Schedula la cancellazione degli appunti dopo N secondi (default 30s).
/// - Prima di cancellare, verifica che il contenuto sia ancora quello che
///   abbiamo scritto noi, per non sovrascrivere ciò che l'utente nel frattempo
///   ha copiato altrove.
class ClipboardGuard {
  ClipboardGuard(this._ref);
  final Ref _ref;
  Timer? _timer;
  String? _lastWritten;

  Future<void> copySensitive(String value) async {
    _timer?.cancel();
    _lastWritten = value;
    await Clipboard.setData(ClipboardData(text: value));
    final secs = _ref.read(clipboardClearSecondsProvider);
    if (secs <= 0) return;
    _timer = Timer(Duration(seconds: secs), _clearIfUnchanged);
  }

  Future<void> _clearIfUnchanged() async {
    final current = await Clipboard.getData(Clipboard.kTextPlain);
    if (current?.text == _lastWritten) {
      await Clipboard.setData(const ClipboardData(text: ''));
    }
    _lastWritten = null;
  }
}

final clipboardGuardProvider =
    Provider<ClipboardGuard>((ref) => ClipboardGuard(ref));
