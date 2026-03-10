import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> openPdfBytes(List<int> bytes) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/resume.pdf');
  await file.writeAsBytes(bytes);
  final uri = Uri.file(file.path);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
