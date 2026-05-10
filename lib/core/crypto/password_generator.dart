import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Generatore di password e passphrase crittograficamente sicuro.
///
/// Sicurezza:
/// - Usiamo `Random.secure()` (CSPRNG di sistema). Mai `Random()` di default.
/// - Per le passphrase carichiamo una wordlist locale; se manca, fallback su
///   un dizionario minimale embeddato.
/// - Niente log dei valori generati.
class PasswordGenerator {
  PasswordGenerator({Random? rng}) : _rng = rng ?? Random.secure();

  final Random _rng;

  static const _lower = 'abcdefghijklmnopqrstuvwxyz';
  static const _upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const _digits = '0123456789';
  static const _symbols = '!@#\$%^&*()-_=+[]{};:,.<>?/~`|';

  /// Genera una password di [length] caratteri (clamp 4..64).
  String generate({
    required int length,
    bool upper = true,
    bool lower = true,
    bool digits = true,
    bool symbols = true,
  }) {
    final n = length.clamp(4, 64);
    final pool = StringBuffer();
    if (upper) pool.write(_upper);
    if (lower) pool.write(_lower);
    if (digits) pool.write(_digits);
    if (symbols) pool.write(_symbols);
    if (pool.isEmpty) pool.write(_lower); // fallback

    final chars = pool.toString();
    final out = List<String>.generate(
      n,
      (_) => chars[_rng.nextInt(chars.length)],
    );

    // Garantisce almeno un carattere per ogni classe selezionata.
    int idx = 0;
    void forceClass(bool enabled, String set) {
      if (!enabled) return;
      if (out.any(set.contains)) return;
      out[idx++ % n] = set[_rng.nextInt(set.length)];
    }

    forceClass(upper, _upper);
    forceClass(lower, _lower);
    forceClass(digits, _digits);
    forceClass(symbols, _symbols);

    return out.join();
  }

  /// Genera una passphrase di [wordCount] parole (clamp 3..8) separate da
  /// [separator]. Se [capitalize] è true, ogni parola comincia in maiuscolo.
  Future<String> generatePassphrase({
    required int wordCount,
    String separator = '-',
    bool capitalize = true,
    String locale = 'en',
  }) async {
    final n = wordCount.clamp(3, 8);
    final words = await _loadWordlist(locale);
    final picked = List<String>.generate(
      n,
      (_) {
        final w = words[_rng.nextInt(words.length)];
        return capitalize ? '${w[0].toUpperCase()}${w.substring(1)}' : w;
      },
    );
    return picked.join(separator);
  }

  Future<List<String>> _loadWordlist(String locale) async {
    try {
      final raw = await rootBundle.loadString('assets/wordlists/$locale.txt');
      final list = raw
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (list.length >= 200) return list;
    } catch (_) {
      // fallback sotto
    }
    return _fallbackWords;
  }

  static const _fallbackWords = <String>[
    'apple','river','mountain','silver','cloud','forest','ocean','window',
    'lemon','tiger','planet','garden','marble','signal','shadow','breeze',
    'pepper','rocket','candle','engine','spider','ginger','velvet','copper',
    'meadow','harbor','bottle','pillar','ribbon','spiral','thunder','violet',
    'cobalt','ember','falcon','glacier','hazel','iris','jasper','kite',
    'lantern','mango','nectar','onyx','pebble','quartz','raven','saffron',
    'topaz','umber','vortex','willow','xenon','yarrow','zephyr','amber',
  ];
}

final passwordGeneratorProvider =
    Provider<PasswordGenerator>((ref) => PasswordGenerator());
