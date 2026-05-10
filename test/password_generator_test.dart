import 'package:flutter_test/flutter_test.dart';
import 'package:password_manager/core/crypto/password_generator.dart';

void main() {
  group('PasswordGenerator', () {
    final gen = PasswordGenerator();

    test('rispetta la lunghezza richiesta nel range 4..64', () {
      for (final n in <int>[4, 8, 16, 32, 64]) {
        final out = gen.generate(length: n);
        expect(out.length, n);
      }
    });

    test('clampa lunghezze fuori range', () {
      expect(gen.generate(length: 1).length, 4);
      expect(gen.generate(length: 1000).length, 64);
    });

    test('include almeno un carattere per ogni classe abilitata', () {
      final out = gen.generate(
        length: 32,
        upper: true,
        lower: true,
        digits: true,
        symbols: true,
      );
      expect(out.contains(RegExp('[A-Z]')), isTrue);
      expect(out.contains(RegExp('[a-z]')), isTrue);
      expect(out.contains(RegExp(r'\d')), isTrue);
      expect(out.contains(RegExp(r'[!@#\$%^&*()\-_=+\[\]{};:,.<>?/~`|]')), isTrue);
    });

    test('passphrase: numero di parole corretto', () async {
      final p = await gen.generatePassphrase(wordCount: 4);
      expect(p.split('-').length, 4);
    });

    test('passphrase: clamping del wordCount', () async {
      final p = await gen.generatePassphrase(wordCount: 100);
      expect(p.split('-').length, 8);
    });
  });
}
