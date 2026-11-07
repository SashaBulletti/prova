import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Un'etichetta da stampare: QR + testo.
class LabelEntry {
  const LabelEntry({
    required this.code,
    required this.title,
    required this.lines,
    required this.color,
  });

  /// Contenuto del QR.
  final String code;

  /// Riga grande (es. "Pomarola" o "Libero").
  final String title;

  /// Righe piccole (es. "Scaffale Blu · Piano 2", "Posto 3").
  final List<String> lines;

  /// Colore del piano (striscia a sinistra), in formato 0xAARRGGBB.
  final int color;
}

/// Crea un PDF A4 con le etichette in griglia (3 colonne × 7 righe),
/// con il bordo tratteggiato per ritagliarle.
Future<Uint8List> buildLabelsPdf({required String title, required List<LabelEntry> entries}) async {
  final regular = pw.Font.ttf(await rootBundle.load('assets/fonts/AtkinsonHyperlegibleNext-Regular.ttf'));
  final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/AtkinsonHyperlegibleNext-Bold.ttf'));

  const cols = 3;
  const rows = 7;
  const perPage = cols * rows;
  final doc = pw.Document(title: title, creator: 'Trovo');
  final format = PdfPageFormat.a4;
  const margin = 8 * PdfPageFormat.mm;
  final cellW = (format.width - 2 * margin) / cols;
  final cellH = (format.height - 2 * margin - 8 * PdfPageFormat.mm) / rows;
  final qrSize = cellH - 6 * PdfPageFormat.mm;

  for (var start = 0; start < entries.length; start += perPage) {
    final page = entries.sublist(start, (start + perPage).clamp(0, entries.length));
    doc.addPage(pw.Page(
      pageFormat: format,
      margin: const pw.EdgeInsets.all(margin),
      theme: pw.ThemeData.withFont(base: regular, bold: bold),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            height: 8 * PdfPageFormat.mm,
            child: pw.Text('Trovo · $title', style: pw.TextStyle(font: bold, fontSize: 10, color: PdfColors.grey700)),
          ),
          pw.Wrap(
            children: [
              for (final e in page)
                pw.Container(
                  width: cellW,
                  height: cellH,
                  padding: const pw.EdgeInsets.all(3 * PdfPageFormat.mm),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400, width: 0.6, style: pw.BorderStyle.dashed),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Container(width: 2.2 * PdfPageFormat.mm, height: qrSize, color: PdfColor.fromInt(e.color)),
                      pw.SizedBox(width: 2 * PdfPageFormat.mm),
                      pw.BarcodeWidget(
                        barcode: pw.Barcode.qrCode(),
                        data: e.code,
                        width: qrSize,
                        height: qrSize,
                        drawText: false,
                      ),
                      pw.SizedBox(width: 2.5 * PdfPageFormat.mm),
                      pw.Expanded(
                        child: pw.Column(
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(e.title, maxLines: 2, style: pw.TextStyle(font: bold, fontSize: 12)),
                            pw.SizedBox(height: 2),
                            for (final l in e.lines)
                              pw.Text(l, maxLines: 2, style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    ));
  }
  return doc.save();
}
