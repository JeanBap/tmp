import 'package:flutter_test/flutter_test.dart';
import 'package:otp/otp.dart';
import 'package:password_manager/features/password_gen/totp_viewer.dart';

void main() {
  group('TotpUri.tryParse', () {
    test('parsa otpauth standard', () {
      final p = TotpUri.tryParse(
          'otpauth://totp/Acme:alice@example.com?secret=JBSWY3DPEHPK3PXP&issuer=Acme&algorithm=SHA1&digits=6&period=30');
      expect(p, isNotNull);
      expect(p!.secret, 'JBSWY3DPEHPK3PXP');
      expect(p.algorithm, Algorithm.SHA1);
      expect(p.digits, 6);
      expect(p.period, 30);
    });

    test('default digits/period', () {
      final p = TotpUri.tryParse(
          'otpauth://totp/foo?secret=JBSWY3DPEHPK3PXP');
      expect(p, isNotNull);
      expect(p!.digits, 6);
      expect(p.period, 30);
    });

    test('SHA256 / SHA512', () {
      expect(TotpUri.tryParse('otpauth://totp/x?secret=JBSWY3DPEHPK3PXP&algorithm=SHA256')?.algorithm,
          Algorithm.SHA256);
      expect(TotpUri.tryParse('otpauth://totp/x?secret=JBSWY3DPEHPK3PXP&algorithm=SHA512')?.algorithm,
          Algorithm.SHA512);
    });

    test('rifiuta URI non otpauth o senza secret', () {
      expect(TotpUri.tryParse('https://example.com'), isNull);
      expect(TotpUri.tryParse('otpauth://totp/foo'), isNull);
      expect(TotpUri.tryParse('otpauth://hotp/foo?secret=JBSWY3DPEHPK3PXP'),
          isNull);
    });

    test('produce un codice di lunghezza richiesta', () {
      final p = TotpUri.tryParse(
          'otpauth://totp/x?secret=JBSWY3DPEHPK3PXP&digits=8')!;
      expect(p.currentCode().length, 8);
    });
  });
}
