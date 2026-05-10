import 'package:flutter_test/flutter_test.dart';
import 'package:kdbx/kdbx.dart';
import 'package:password_manager/core/kdbx/kdbx_service.dart';

void main() {
  // Smoke test del round-trip create -> save bytes -> open.
  // Verifica che la pipeline KdbxService + Argon2 (PointyCastle) lavori
  // end-to-end senza FFI nativa.
  test('KDBX round-trip create/save/open', () async {
    final svc = KdbxService();
    final file = svc.createNew(name: 'unit-test', masterPassword: 'correct horse battery staple');
    // Aggiungi una voce
    final entry = file.body.rootGroup.createEntry();
    entry.setString(KdbxKeyCommon.TITLE, PlainValue('Hello'));
    entry.setString(
      KdbxKeyCommon.PASSWORD,
      ProtectedValue.fromString('S3cr3t!'),
    );

    final bytes = await file.save();
    final reopened =
        await svc.openBytes(bytes: bytes, masterPassword: 'correct horse battery staple');
    final loaded = reopened.body.rootGroup.getAllEntries().single;
    expect(loaded.getString(KdbxKeyCommon.TITLE)?.getText(), 'Hello');
    expect(loaded.getString(KdbxKeyCommon.PASSWORD)?.getText(), 'S3cr3t!');
  }, timeout: const Timeout(Duration(minutes: 2))); // Argon2 in pure-Dart è lento.

  test('KDBX open con password sbagliata solleva WrongMasterPasswordException',
      () async {
    final svc = KdbxService();
    final file = svc.createNew(name: 'unit-test', masterPassword: 'right');
    final bytes = await file.save();
    expect(
      () => svc.openBytes(bytes: bytes, masterPassword: 'wrong'),
      throwsA(isA<WrongMasterPasswordException>()),
    );
  }, timeout: const Timeout(Duration(minutes: 2)));
}
