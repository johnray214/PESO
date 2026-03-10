/// Result of picking a PDF file. On mobile/desktop [path] is set; on web [bytes] is set.
class PdfPickResult {
  final String? path;
  final List<int>? bytes;
  final String name;

  const PdfPickResult({this.path, this.bytes, required this.name});
}
