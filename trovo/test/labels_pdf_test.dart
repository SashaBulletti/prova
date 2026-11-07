import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trovo/scan_codes.dart';
import 'package:trovo/services/labels_pdf.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('il foglio A4 delle etichette QR si crea', () async {
    final entries = [
      for (var p = 1; p <= 25; p++)
        LabelEntry(
          code: TrovoCode.forSlot('livello-prova', p),
          title: p == 3 ? 'Libero' : 'Pomarola di casa $p',
          lines: ['Scaffale Blu · Piano 2', 'Posto $p · Dispensa'],
          color: 0xFFFFB870,
        ),
    ];
    final bytes = await buildLabelsPdf(title: 'Etichette dei posti', entries: entries);
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    final out = Platform.environment['TROVO_PDF_OUT'];
    if (out != null) File(out).writeAsBytesSync(bytes);
  });
}
