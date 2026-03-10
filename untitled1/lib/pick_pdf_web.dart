import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'pdf_picker_result.dart';

/// Picks a PDF file using the browser's file input (avoids file_picker on web).
Future<PdfPickResult?> pickPdf() async {
  final input = html.FileUploadInputElement()
    ..accept = '.pdf,application/pdf'
    ..style.display = 'none';

  html.document.body?.append(input);
  final completer = Completer<PdfPickResult?>();

  void cleanup() {
    input.remove();
  }

  input.onChange.listen((_) async {
    if (completer.isCompleted) return;
    if (input.files == null || input.files!.isEmpty) {
      completer.complete(null);
      cleanup();
      return;
    }
    final file = input.files!.first;
    if (!file.name.toLowerCase().endsWith('.pdf')) {
      completer.complete(null);
      cleanup();
      return;
    }
    final reader = html.FileReader();
    reader.onLoadEnd.listen((_) {
      try {
        if (!completer.isCompleted) {
          final result = reader.result;
          List<int>? bytes;
          if (result != null) {
            if (result is ByteBuffer) {
              bytes = result.asUint8List();
            } else if (result is Uint8List) {
              bytes = result;
            }
          }
          if (bytes != null && bytes.isNotEmpty) {
            completer.complete(PdfPickResult(bytes: bytes, name: file.name));
          } else {
            completer.complete(null);
          }
        }
      } catch (_) {
        if (!completer.isCompleted) completer.complete(null);
      }
      cleanup();
    });
    reader.onError.listen((_) {
      if (!completer.isCompleted) completer.complete(null);
      cleanup();
    });
    reader.readAsArrayBuffer(file);
  });

  input.click();

  // If user cancels the dialog, we may never get an event; complete with null after a timeout
  return completer.future.timeout(
    const Duration(seconds: 120),
    onTimeout: () {
      if (!completer.isCompleted) completer.complete(null);
      cleanup();
      return null;
    },
  );
}
