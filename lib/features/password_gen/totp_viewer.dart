import 'dart:async';

import 'package:base32/base32.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otp/otp.dart';

import '../../core/auth/clipboard_guard.dart';

/// Parser di URI `otpauth://totp/...` + viewer con countdown animato.
///
/// Sicurezza:
/// - Il secret non viene mai mostrato; solo il codice TOTP corrente.
/// - Tap-to-copy passa dal `ClipboardGuard` per la pulizia automatica.
class TotpUri {
  TotpUri({
    required this.secret,
    required this.algorithm,
    required this.digits,
    required this.period,
  });

  final String secret;
  final Algorithm algorithm;
  final int digits;
  final int period;

  static TotpUri? tryParse(String input) {
    try {
      final uri = Uri.parse(input);
      if (uri.scheme != 'otpauth') return null;
      if (uri.host != 'totp') return null;
      final secret = uri.queryParameters['secret'];
      if (secret == null || secret.isEmpty) return null;
      // Valida base32:
      base32.decode(secret.replaceAll('=', '').toUpperCase());
      final alg = switch ((uri.queryParameters['algorithm'] ?? 'SHA1').toUpperCase()) {
        'SHA256' => Algorithm.SHA256,
        'SHA512' => Algorithm.SHA512,
        _ => Algorithm.SHA1,
      };
      final digits = int.tryParse(uri.queryParameters['digits'] ?? '6') ?? 6;
      final period = int.tryParse(uri.queryParameters['period'] ?? '30') ?? 30;
      return TotpUri(
        secret: secret,
        algorithm: alg,
        digits: digits,
        period: period,
      );
    } on Object {
      return null;
    }
  }

  String currentCode() {
    return OTP.generateTOTPCodeString(
      secret,
      DateTime.now().millisecondsSinceEpoch,
      length: digits,
      interval: period,
      algorithm: algorithm,
      isGoogle: true,
    );
  }
}

class TotpViewer extends ConsumerStatefulWidget {
  const TotpViewer({super.key, required this.otpAuthUri});
  final String otpAuthUri;
  @override
  ConsumerState<TotpViewer> createState() => _TotpViewerState();
}

class _TotpViewerState extends ConsumerState<TotpViewer> {
  Timer? _timer;
  TotpUri? _parsed;
  String _code = '------';
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _parsed = TotpUri.tryParse(widget.otpAuthUri);
    _tick();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick() {
    final p = _parsed;
    if (p == null) return;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final remaining = p.period - (now % p.period);
    setState(() {
      _code = p.currentCode();
      _progress = remaining / p.period;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_parsed == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('OTP URI non valido'),
        ),
      );
    }
    return Card(
      child: ListTile(
        leading: SizedBox(
          height: 36,
          width: 36,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              CircularProgressIndicator(value: _progress, strokeWidth: 3),
              const Icon(Icons.timer_outlined, size: 18),
            ],
          ),
        ),
        title: Text(
          _code,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 24,
            letterSpacing: 4,
          ),
        ),
        subtitle: Text(
            'TOTP · ${_parsed!.algorithm.name} · ${_parsed!.digits} cifre'),
        trailing: IconButton(
          icon: const Icon(Icons.copy_outlined),
          onPressed: () async {
            await ref.read(clipboardGuardProvider).copySensitive(_code);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Codice copiato')),
              );
            }
          },
        ),
      ),
    );
  }
}
