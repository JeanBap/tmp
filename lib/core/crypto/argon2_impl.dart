import 'dart:typed_data';

import 'package:argon2_ffi_base/argon2_ffi_base.dart';
import 'package:pointycastle/key_derivators/argon2.dart' as pc;
import 'package:pointycastle/pointycastle.dart' as pc;

/// Implementazione di `Argon2` per il pacchetto `kdbx` usando PointyCastle.
///
/// Nota di sicurezza:
/// - PointyCastle è 100% Dart: nessuna FFI, ma è significativamente più lento
///   di una implementazione nativa. Per build di produzione conviene sostituire
///   con `argon2_ffi` (Flutter plugin con bindings nativi).
/// - I parametri di costo (iterations, memory, parallelism) sono letti dal
///   file KDBX stesso: noi qui non li forziamo, li onoriamo.
class PointyCastleArgon2 extends Argon2Base {
  @override
  Uint8List argon2(Argon2Arguments args) {
    final argon2Type = args.type == Argon2Arguments.ARGON2_id
        ? pc.Argon2Parameters.ARGON2_id
        : pc.Argon2Parameters.ARGON2_d;
    final params = pc.Argon2Parameters(
      argon2Type,
      args.salt,
      desiredKeyLength: args.length,
      version: args.version == Argon2Arguments.VERSION_10
          ? pc.Argon2Parameters.ARGON2_VERSION_10
          : pc.Argon2Parameters.ARGON2_VERSION_13,
      iterations: args.iterations,
      memory: args.memory ~/ 1024, // bytes -> KiB (PointyCastle aspetta KiB)
      lanes: args.parallelism,
    );
    final gen = pc.Argon2BytesGenerator()..init(params);
    final out = Uint8List(args.length);
    gen.deriveKey(Uint8List.fromList(args.password), 0, out, 0);
    return out;
  }
}
