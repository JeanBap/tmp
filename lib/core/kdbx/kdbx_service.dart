import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kdbx/kdbx.dart';
import 'package:logging/logging.dart';

import '../crypto/argon2_impl.dart';

final _log = Logger('KdbxService');

/// Servizio principale per leggere/creare/salvare file KDBX (KeePass).
///
/// Note di sicurezza:
/// - La master password e gli altri segreti non vengono mai loggati.
/// - Il file in memoria (`KdbxFile`) contiene `ProtectedValue` che mantengono
///   i campi sensibili criptati a riposo finché non vengono letti esplicitamente.
/// - Il salvataggio è atomico: scriviamo su un file temporaneo e poi rinominiamo,
///   per evitare corruzioni in caso di kill dell'app durante la scrittura.
class KdbxService {
  KdbxService()
      : _format = KdbxFormat(const PointyCastleArgon2());

  final KdbxFormat _format;

  /// Crea un nuovo database KDBX vuoto, in memoria.
  KdbxFile createNew({
    required String name,
    required String masterPassword,
  }) {
    final credentials = Credentials(ProtectedValue.fromString(masterPassword));
    final file = _format.create(credentials, name);
    _log.fine('Created new KDBX in-memory: $name');
    return file;
  }

  /// Apre un file KDBX da disco.
  Future<KdbxFile> openFile({
    required String path,
    required String masterPassword,
  }) async {
    final bytes = await File(path).readAsBytes();
    return openBytes(bytes: bytes, masterPassword: masterPassword);
  }

  /// Apre un KDBX a partire dai byte (utile per file passati via Intent).
  Future<KdbxFile> openBytes({
    required Uint8List bytes,
    required String masterPassword,
  }) async {
    final credentials = Credentials(ProtectedValue.fromString(masterPassword));
    try {
      final file = await _format.read(bytes, credentials);
      _log.fine('Opened KDBX (entries=${file.body.rootGroup.getAllEntries().length})');
      return file;
    } on KdbxInvalidKeyException {
      // Riemettiamo come eccezione "neutra" senza dettagli sensibili.
      throw const WrongMasterPasswordException();
    }
  }

  /// Salva il file KDBX su disco in modo atomico.
  Future<void> save(KdbxFile file, String path) async {
    final bytes = await file.save();
    final tmp = File('$path.tmp');
    await tmp.writeAsBytes(bytes, flush: true);
    await tmp.rename(path);
    _log.fine('Saved KDBX to $path (${bytes.length} bytes)');
  }
}

/// Eccezione sollevata quando la master password è errata.
/// Volutamente generica per evitare leak di informazioni.
class WrongMasterPasswordException implements Exception {
  const WrongMasterPasswordException();
  @override
  String toString() => 'WrongMasterPasswordException';
}

final kdbxServiceProvider = Provider<KdbxService>((ref) => KdbxService());

/// File KDBX attualmente sbloccato.
/// `null` significa: app bloccata o nessun vault aperto.
class CurrentVault {
  const CurrentVault({required this.file, required this.path});
  final KdbxFile file;
  final String path;
}

final currentVaultProvider = StateProvider<CurrentVault?>((ref) => null);
