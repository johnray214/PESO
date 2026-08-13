import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

/// Label above auth input field matching Design 2 spec.
Widget buildAuthFieldLabel(String label) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6, left: 2),
    child: Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF1E293B),
      ),
    ),
  );
}

/// Shared auth field styling used by login and signup flows.
InputDecoration authFieldDecoration(
  dynamic icon, {
  String? labelText,
  String? hintText,
  Widget? suffix,
  bool renderAsModal = false,
  String? counterText,
  TextStyle? labelStyle,
  TextStyle? floatingLabelStyle,
  bool isDense = false,
}) {
  final fill = renderAsModal ? const Color(0xFFF8F9FA) : const Color(0xFFF8FAFC);
  final enabledBorderColor = const Color(0xFFE2E8F0);
  return InputDecoration(
    floatingLabelBehavior: FloatingLabelBehavior.never,
    labelText: labelText,
    hintText: hintText,
    hintStyle: GoogleFonts.poppins(
      color: const Color(0xFF94A3B8),
      fontWeight: FontWeight.w400,
      fontSize: 13.5,
    ),
    labelStyle: labelStyle ??
        GoogleFonts.poppins(
          color: const Color(0xFF64748B),
          fontWeight: FontWeight.w500,
          fontSize: 13.5,
        ),
    floatingLabelStyle: floatingLabelStyle ??
        GoogleFonts.poppins(
          color: const Color(0xFF2563EB),
          fontWeight: FontWeight.w600,
          fontSize: 12.5,
        ),
    prefixIcon: Padding(
      padding: const EdgeInsets.only(left: 14, right: 10),
      child: icon is Widget
          ? icon
          : icon is IconData
              ? Icon(icon, color: const Color(0xFF2563EB), size: 20)
              : HugeIcon(
                  icon: icon as List<List<dynamic>>,
                  color: const Color(0xFF2563EB),
                  size: 20,
                  strokeWidth: 2.0,
                ),
    ),
    prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
    suffixIcon: suffix,
    filled: true,
    fillColor: fill,
    isDense: isDense,
    counterText: counterText,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: enabledBorderColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: enabledBorderColor, width: 1.2),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.8),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.2),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.8),
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
        const HugeIcon(
          icon: HugeIcons.strokeRoundedAlertCircle,
          color: Color(0xFF991B1B),
          size: 18,
          strokeWidth: 2.0,
        ),
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
          child: const HugeIcon(
            icon: HugeIcons.strokeRoundedCancel01,
            color: Color(0xFF991B1B),
            size: 18,
            strokeWidth: 2.0,
          ),
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
