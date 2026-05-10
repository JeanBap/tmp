import 'dart:typed_data';

import 'package:argon2_ffi_base/argon2_ffi_base.dart';
import 'package:pointycastle/key_derivators/argon2.dart' as pc;
import 'package:pointycastle/pointycastle.dart' as pc;

/// Pure-Dart implementazione di `Argon2` per il pacchetto `kdbx` (PointyCastle).
///
/// I parametri di costo (type, version, iterations, memory, parallelism)
/// arrivano dal file KDBX stesso e vengono onorati 1:1.
class PointyCastleArgon2 extends Argon2 {
  const PointyCastleArgon2();

  @override
  bool get isFfi => false;

  @override
  bool get isImplemented => true;

  @override
  Uint8List argon2(Argon2Arguments args) {
    final params = pc.Argon2Parameters(
      args.type,
      args.salt,
      desiredKeyLength: args.length,
      iterations: args.iterations,
      memory: args.memory,
      lanes: args.parallelism,
      version: args.version,
    );
    final gen = pc.Argon2BytesGenerator()..init(params);
    return gen.process(args.key);
  }

  @override
  Future<Uint8List> argon2Async(Argon2Arguments args) async => argon2(args);
}
