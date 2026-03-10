import 'dart:io';

import 'package:file_picker/file_picker.dart';

import 'pdf_picker_result.dart';

/// Picks a PDF file using the file_picker plugin (mobile/desktop).
Future<PdfPickResult?> pickPdf() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['pdf'],
    withData: true,
    withReadStream: false,
  );
  if (result == null || result.files.isEmpty) return null;

  final file = result.files.single;
  final name = file.name;

  if (file.path != null && file.path!.isNotEmpty) {
    if (await File(file.path!).exists()) {
      return PdfPickResult(path: file.path, name: name);
    }
  }
  if (file.bytes != null && file.bytes!.isNotEmpty) {
    return PdfPickResult(bytes: file.bytes!, name: name);
  }
  return null;
}
