import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shared auth field styling used by login and signup flows.
InputDecoration authFieldDecoration(
  String label,
  IconData icon, {
  Widget? suffix,
  bool renderAsModal = false,
  String? counterText,
  TextStyle? labelStyle,
  TextStyle? floatingLabelStyle,
  bool isDense = false,
}) {
  final fill = renderAsModal ? const Color(0xFFF8F9FA) : Colors.white;
  final enabledBorderColor =
      renderAsModal ? Colors.grey[300]! : const Color(0xFFD8E1EC);
  return InputDecoration(
    labelText: label,
    labelStyle: labelStyle ??
        const TextStyle(
          color: Color(0xFF64748B),
          fontWeight: FontWeight.w500,
        ),
    floatingLabelStyle: floatingLabelStyle,
    prefixIcon: Icon(icon, color: const Color(0xFF2563EB)),
    suffixIcon: suffix,
    filled: true,
    fillColor: fill,
    isDense: isDense,
    counterText: counterText,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: enabledBorderColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: enabledBorderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.6),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFDC2626)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.6),
    ),
  );
}

Widget authErrorBanner(String message, VoidCallback onDismiss) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFFEE2E2),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFFCA5A5)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.error_outline_rounded,
            color: Color(0xFF991B1B), size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: Color(0xFF991B1B),
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: onDismiss,
          child: const Icon(Icons.close_rounded,
              color: Color(0xFF991B1B), size: 18),
        ),
      ],
    ),
  );
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
