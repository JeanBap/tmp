import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kdbx/kdbx.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Servizio di export PDF (vault completo o singola voce).
///
/// SICUREZZA:
/// - Anche il PDF è in chiaro come il CSV: avvisare sempre l'utente.
/// - Su Android consigliato esportare in cartelle private dell'app
///   (`getApplicationDocumentsDirectory`) e non in `Downloads` pubblici.
class PdfService {
  Future<File> exportVault(KdbxFile file) async {
    final doc = pw.Document();
    final entries = file.body.rootGroup.getAllEntries().toList();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) => <pw.Widget>[
          pw.Header(level: 0, child: pw.Text('Vault Export')),
          pw.Paragraph(
            text:
                'ATTENZIONE: questo documento contiene credenziali in chiaro.',
          ),
          pw.Table.fromTextArray(
            headers: const <String>['Titolo', 'Username', 'Password', 'URL'],
            data: <List<String>>[
              for (final e in entries)
                <String>[
                  e.getString(KdbxKeyCommon.TITLE)?.getText() ?? '',
                  e.getString(KdbxKeyCommon.USER_NAME)?.getText() ?? '',
                  e.getString(KdbxKeyCommon.PASSWORD)?.getText() ?? '',
                  e.getString(KdbxKeyCommon.URL)?.getText() ?? '',
                ],
            ],
          ),
        ],
      ),
    );
    final dir = await getApplicationDocumentsDirectory();
    final out = File(
        '${dir.path}/vault_export_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await out.writeAsBytes(await doc.save(), flush: true);
    return out;
  }

  Future<void> printEntry(KdbxEntry entry) async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: <pw.Widget>[
            pw.Header(
              level: 0,
              child: pw.Text(
                entry.getString(KdbxKeyCommon.TITLE)?.getText() ?? '',
              ),
            ),
            pw.Paragraph(
                text:
                    'Username: ${entry.getString(KdbxKeyCommon.USER_NAME)?.getText() ?? ''}'),
            pw.Paragraph(
                text:
                    'Password: ${entry.getString(KdbxKeyCommon.PASSWORD)?.getText() ?? ''}'),
            pw.Paragraph(
                text:
                    'URL: ${entry.getString(KdbxKeyCommon.URL)?.getText() ?? ''}'),
            pw.Paragraph(
                text:
                    'Note: ${entry.getString(KdbxKey('Notes'))?.getText() ?? ''}'),
          ],
        ),
      ),
    );
    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }
}

final pdfServiceProvider = Provider<PdfService>((ref) => PdfService());
