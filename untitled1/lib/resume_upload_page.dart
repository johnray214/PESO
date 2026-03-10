import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';

import 'api_service.dart';
import 'pdf_picker_result.dart';
import 'pick_pdf_io.dart' if (dart.library.html) 'pick_pdf_web.dart' as pdf_picker;
import 'user_session.dart';

/// Page for uploading and managing the user's resume (PDF).
class ResumeUploadPage extends StatefulWidget {
  const ResumeUploadPage({super.key});

  @override
  State<ResumeUploadPage> createState() => _ResumeUploadPageState();
}

class _ResumeUploadPageState extends State<ResumeUploadPage> {
  bool _loading = false;
  String? _message;
  bool _isSuccess = false;
  String? _currentResumeName;
  PdfPickResult? _pendingFile;
  bool _viewingResume = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentResume();
  }

  Future<void> _loadCurrentResume() async {
    final token = UserSession().token;
    if (token == null || token.isEmpty) return;
    final result = await ApiService.getUser(token);
    if (result['success'] == true && result['data'] != null) {
      final user = result['data'] as Map<String, dynamic>;
      final path = user['resume_path'] as String?;
      if (mounted) {
        setState(() {
          _currentResumeName = path != null && path.isNotEmpty
              ? path.split(RegExp(r'[/\\]')).last
              : null;
        });
      }
    }
  }

  Future<void> _askThenPickFile() async {
    final token = UserSession().token;
    if (token == null || token.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to upload a resume')),
        );
      }
      return;
    }

    if (_currentResumeName != null && _pendingFile == null) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Replace your resume?'),
          content: const Text(
            'You already have a resume on file. Choosing a new file will replace it. Do you want to continue?',
            style: TextStyle(color: Color(0xFF64748B), height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Choose new file'),
            ),
          ],
        ),
      );
      if (replace != true || !mounted) return;
    }

    await _pickFile();
  }

  Future<void> _pickFile() async {
    try {
      if (!kIsWeb) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (!mounted) return;
      }

      final result = await pdf_picker.pickPdf();
      if (!mounted) return;
      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No PDF file selected')),
        );
        return;
      }

      setState(() {
        _pendingFile = result;
        _message = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _clearPending() {
    setState(() {
      _pendingFile = null;
      _message = null;
    });
  }

  Future<void> _uploadPending() async {
    final token = UserSession().token;
    final pending = _pendingFile;
    if (token == null || pending == null) return;

    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      final Map<String, dynamic> uploadResult;
      if (pending.bytes != null) {
        uploadResult = await ApiService.uploadResumeBytes(
          token: token,
          fileBytes: pending.bytes!,
          fileName: pending.name,
        );
      } else {
        uploadResult = await ApiService.uploadResume(
          token: token,
          filePath: pending.path!,
          fileName: pending.name,
        );
      }

      if (!mounted) return;
      setState(() {
        _loading = false;
        _isSuccess = uploadResult['success'] == true;
        _message = uploadResult['message'] as String? ??
            (_isSuccess ? 'Resume uploaded successfully' : 'Upload failed');
        if (_isSuccess) _pendingFile = null;
      });

      if (_isSuccess) {
        await _loadCurrentResume();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Resume uploaded successfully'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _isSuccess = false;
          _message = 'Error: ${e.toString()}';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _viewResume() async {
    final token = UserSession().token;
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to view your resume')),
      );
      return;
    }

    setState(() => _viewingResume = true);
    try {
      final result = await ApiService.getResumeViewUrl(token);
      if (!mounted) return;

      final error = result['error'] as String?;
      final url = result['url'] as String?;

      if (error != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'OK',
                onPressed: () {},
              ),
            ),
          );
        }
        setState(() => _viewingResume = false);
        return;
      }

      if (url == null || url.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not load resume')),
          );
        }
        setState(() => _viewingResume = false);
        return;
      }

      final uri = Uri.parse(url);
      bool opened = false;
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.platformDefault);
          opened = true;
        }
      } catch (_) {}
      if (!opened) {
        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          opened = true;
        } catch (_) {}
      }
      if (!opened && mounted) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Open resume'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Copy this link and open it in your browser to view your resume:',
                  style: TextStyle(color: Color(0xFF64748B), height: 1.4),
                ),
                const SizedBox(height: 12),
                SelectableText(
                  url,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF2563EB)),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  launchUrl(uri, mode: LaunchMode.platformDefault);
                },
                child: const Text('Try opening again'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _viewingResume = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
          color: const Color(0xFF0F172A),
        ),
        title: const Text(
          'My Resume',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.picture_as_pdf_rounded,
                      size: 56,
                      color: const Color(0xFF2563EB),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Upload your resume in PDF format',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Employers can view your resume when you apply for jobs.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (_currentResumeName != null && _pendingFile == null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: Color(0xFF2563EB), size: 20),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _currentResumeName!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF0F172A),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 44,
                        child: OutlinedButton.icon(
                          onPressed: _viewingResume ? null : _viewResume,
                          icon: _viewingResume
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.visibility_rounded, size: 20),
                          label: Text(_viewingResume ? 'Opening…' : 'View resume'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2563EB),
                            side: const BorderSide(color: Color(0xFF2563EB)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (_pendingFile != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.insert_drive_file_rounded,
                              color: Color(0xFF2563EB), size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _pendingFile!.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Ready to upload. Tap below to confirm.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _loading ? null : _clearPending,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF64748B),
                                side: const BorderSide(color: Color(0xFF94A3B8)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _loading ? null : _uploadPending,
                              icon: _loading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.cloud_upload_rounded, size: 20),
                              label: Text(_loading ? 'Uploading…' : 'Upload resume'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              if (_message != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _message!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: _isSuccess
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFDC2626),
                    ),
                  ),
                ),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _askThenPickFile,
                  icon: const Icon(Icons.add_rounded, size: 22),
                  label: Text(
                    _currentResumeName != null && _pendingFile == null
                        ? 'Choose PDF & Upload'
                        : 'Choose PDF & Upload',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
