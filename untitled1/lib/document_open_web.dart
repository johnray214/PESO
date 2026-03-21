// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;
import 'dart:typed_data';

/// Open PDF in a new browser tab (web).
Future<void> openPdfBytes(List<int> bytes, String _) async {
  final blob = html.Blob([Uint8List.fromList(bytes)], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, '_blank');
}
