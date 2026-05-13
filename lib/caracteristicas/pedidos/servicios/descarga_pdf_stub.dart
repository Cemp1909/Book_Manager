import 'dart:typed_data';

import 'package:printing/printing.dart';

Future<void> downloadPdfBytes({
  required Uint8List bytes,
  required String filename,
}) async {
  await Printing.sharePdf(bytes: bytes, filename: filename);
}
