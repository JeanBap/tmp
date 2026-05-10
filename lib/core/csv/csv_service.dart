import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kdbx/kdbx.dart';
import 'package:path_provider/path_provider.dart';

/// Servizio Import/Export CSV.
///
/// AVVERTENZA DI SICUREZZA:
/// - Un CSV è un file in CHIARO. Le password vi vengono esportate non cifrate.
/// - L'utente va sempre avvisato prima di esportare; idealmente si dovrebbe
///   richiedere conferma biometrica e mostrare un disclaimer.
class CsvService {
  static const _headers = <String>[
    'Title', 'Username', 'Password', 'URL', 'Notes', 'Group',
  ];

  Future<File> exportVault(KdbxFile file) async {
    final rows = <List<String>>[_headers];
    for (final entry in file.body.rootGroup.getAllEntries()) {
      rows.add(<String>[
        entry.getString(KdbxKeyCommon.TITLE)?.getText() ?? '',
        entry.getString(KdbxKeyCommon.USER_NAME)?.getText() ?? '',
        entry.getString(KdbxKeyCommon.PASSWORD)?.getText() ?? '',
        entry.getString(KdbxKeyCommon.URL)?.getText() ?? '',
        entry.getString(KdbxKey('Notes'))?.getText() ?? '',
        entry.parent?.name.get() ?? '',
      ]);
    }
    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getApplicationDocumentsDirectory();
    final out = File('${dir.path}/vault_export_${DateTime.now().millisecondsSinceEpoch}.csv');
    await out.writeAsString(csv, flush: true);
    return out;
  }

  /// Importa un CSV nel vault. Ritorna il numero di voci importate.
  /// Atteso schema KeePass standard (Title,Username,Password,URL,Notes,Group).
  Future<int> importIntoVault(KdbxFile file) async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['csv'],
    );
    final path = picked?.files.single.path;
    if (path == null) return 0;
    final raw = await File(path).readAsString();
    final rows = const CsvToListConverter(eol: '\n').convert(raw);
    if (rows.isEmpty) return 0;

    // Header detection (case-insensitive title at col 0)
    int start = 0;
    final first = rows.first;
    if (first.isNotEmpty &&
        first.first.toString().toLowerCase().contains('title')) {
      start = 1;
    }
    var count = 0;
    for (var i = start; i < rows.length; i++) {
      final r = rows[i];
      if (r.isEmpty) continue;
      String at(int idx) =>
          (idx < r.length ? r[idx].toString() : '').trim();
      final parent = file.body.rootGroup;
      final entry = KdbxEntry.create(file, parent);
      parent.addEntry(entry);
      entry.setString(KdbxKeyCommon.TITLE, PlainValue(at(0)));
      entry.setString(KdbxKeyCommon.USER_NAME, PlainValue(at(1)));
      entry.setString(
        KdbxKeyCommon.PASSWORD,
        ProtectedValue.fromString(at(2)),
      );
      entry.setString(KdbxKeyCommon.URL, PlainValue(at(3)));
      entry.setString(KdbxKey('Notes'), PlainValue(at(4)));
      count++;
    }
    return count;
  }
}

final csvServiceProvider = Provider<CsvService>((ref) => CsvService());
