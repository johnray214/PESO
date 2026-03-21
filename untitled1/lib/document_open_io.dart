import 'dart:io';

import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

/// Open PDF bytes in the system viewer (mobile/desktop).
Future<void> openPdfBytes(List<int> bytes, String suggestedName) async {
  final dir = await getTemporaryDirectory();
  var safe = suggestedName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  if (safe.isEmpty) safe = 'document';
  final name = safe.toLowerCase().endsWith('.pdf') ? safe : '$safe.pdf';
  final file = File('${dir.path}/peso_view_$name');
  await file.writeAsBytes(bytes, flush: true);
  await OpenFile.open(file.path);
}
