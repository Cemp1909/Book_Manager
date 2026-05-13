// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:convert';
import 'dart:typed_data';

import 'dart:html' as html;

Future<void> downloadPdfBytes({
  required Uint8List bytes,
  required String filename,
}) async {
  final data = base64Encode(bytes);
  final anchor = html.AnchorElement(
    href: 'data:application/pdf;base64,$data',
  )
    ..download = filename
    ..style.display = 'none';

  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();
}
