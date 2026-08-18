import 'dart:async';
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'user_session.dart';
import 'job_action_service.dart';
import 'main.dart';

/// Displays the interactive Job Offer Decision Bottom Sheet (Accept / Reject Offer).
Future<String?> showJobOfferDecisionSheet({
  required BuildContext context,
  required int applicationId,
  required String jobTitle,
  required String companyName,
  required String startDate,
  required String salary,
  required String employmentType,
  String? initialResponse, // 'accepted' | 'declined' | null
  VoidCallback? onResponseSubmitted,
}) async {
  String? selectedResponse = initialResponse;
  bool isSubmitting = false;

  List<TextSpan> parseMessageWithBold(String message) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*(.*?)\*\*');
    int lastIndex = 0;

    for (final match in regex.allMatches(message)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(text: message.substring(lastIndex, match.start)));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: Color(0xFF0F172A),
        ),
      ));
      lastIndex = match.end;
    }

    if (lastIndex < message.length) {
      spans.add(TextSpan(text: message.substring(lastIndex)));
    }

    return spans;
  }

  return await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setModalState) {
        Future<void> handleResponse(String response) async {
          if (isSubmitting || selectedResponse != null) {
            return;
          }

          final isAccept = response == 'accepted';
          final confirmed = await showAppDialog<bool>(
            context: context,
            type: isAccept ? AppDialogType.confirm : AppDialogType.destructive,
            icon: isAccept ? Icons.check_circle_rounded : Icons.cancel_outlined,
            title: isAccept ? 'Accept Job Offer?' : 'Decline Job Offer?',
            message: isAccept
                ? 'You are accepting the offer from $companyName for the $jobTitle role. This will notify the employer and move forward with your hiring.'
                : 'Are you sure you want to decline the offer from $companyName for the $jobTitle role? This action cannot be undone.',
            confirmLabel: isAccept ? 'Confirm & Accept' : 'Decline Offer',
            cancelLabel: isAccept ? 'Cancel' : 'Keep Offer',
            onConfirm: () => Navigator.of(context).pop(true),
            onCancel: () => Navigator.of(context).pop(false),
          );

          if (confirmed != true || !ctx.mounted) return;

          setModalState(() => isSubmitting = true);

          final token = UserSession().token;
          if (token == null || token.isEmpty) {
            setModalState(() => isSubmitting = false);
            return;
          }

          final result = await ApiService.respondToJobOffer(
            token: token,
            applicationId: applicationId,
            response: response,
          );

          if (!ctx.mounted) return;

          if (result['success'] == true) {
            JobActionService().recordOfferResponse(applicationId, response);
            setModalState(() {
              selectedResponse = response;
              isSubmitting = false;
            });
            CustomToast.show(
              context,
              message: response == 'accepted'
                  ? 'Offer accepted successfully.'
                  : 'Offer rejected successfully.',
              type: response == 'accepted'
                  ? ToastType.success
                  : ToastType.info,
            );
            onResponseSubmitted?.call();
          } else {
            setModalState(() => isSubmitting = false);
            CustomToast.show(
              context,
              message: result['message']?.toString() ??
                  'Failed to submit your offer response. Please try again.',
              type: ToastType.error,
            );
          }
        }

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.76,
          minChildSize: 0.48,
          maxChildSize: 0.92,
          builder: (_, scrollCtrl) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: ListView(
              controller: scrollCtrl,
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(ctx).bottom + 16,
              ),
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Icon(Icons.gavel_rounded, color: Colors.white, size: 28),
                      SizedBox(height: 10),
                      Text(
                        'Job Offer Received',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF475569),
                        height: 1.5,
                      ),
                      children: parseMessageWithBold(
                        '**$companyName** offered you the **$jobTitle** role. Please review and choose one response below.',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Start Date: $startDate',
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF334155))),
                        const SizedBox(height: 4),
                        Text('Salary: $salary',
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF334155))),
                        const SizedBox(height: 4),
                        Text('Employment Type: $employmentType',
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF334155))),
                      ],
                    ),
                  ),
                ),
                if (selectedResponse != null)
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 10, left: 20, right: 20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: selectedResponse == 'accepted'
                            ? const Color(0xFFECFDF5)
                            : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selectedResponse == 'accepted'
                              ? const Color(0xFFA7F3D0)
                              : const Color(0xFFFECACA),
                        ),
                      ),
                      child: Text(
                        selectedResponse == 'accepted'
                            ? 'You accepted this offer.'
                            : 'You rejected this offer.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: selectedResponse == 'accepted'
                              ? const Color(0xFF047857)
                              : const Color(0xFFB91C1C),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: (isSubmitting ||
                                  selectedResponse != null)
                              ? null
                              : () => handleResponse('declined'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: selectedResponse == null
                                ? const Color(0xFFB91C1C)
                                : const Color(0xFF94A3B8),
                            side: BorderSide(
                              color: selectedResponse == null
                                  ? const Color(0xFFFCA5A5)
                                  : const Color(0xFFE2E8F0),
                            ),
                            backgroundColor: selectedResponse == 'declined'
                                ? const Color(0xFFFEF2F2)
                                : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            selectedResponse == 'declined'
                                ? 'Rejected'
                                : 'Reject Offer',
                            style:
                                const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: (isSubmitting ||
                                  selectedResponse != null)
                              ? null
                              : () => handleResponse('accepted'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selectedResponse == 'accepted'
                                ? const Color(0xFF047857)
                                : (selectedResponse == null
                                    ? const Color(0xFF059669)
                                    : const Color(0xFFCBD5E1)),
                            foregroundColor: selectedResponse == null
                                ? Colors.white
                                : const Color(0xFF475569),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  selectedResponse == 'accepted'
                                      ? 'Accepted'
                                      : 'Accept Offer',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
