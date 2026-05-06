import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'api_service.dart';
import 'main.dart';
import 'document_open_io.dart' if (dart.library.html) 'document_open_web.dart' as doc_open;
import 'pdf_picker_result.dart';
import 'pick_pdf_io.dart' if (dart.library.html) 'pick_pdf_web.dart' as pdf_picker;
import 'user_session.dart';

enum _DocKind { resume, certificate, clearance }

/// Job seeker: Resume/CV, Certificate/Diploma, Barangay clearance — synced with admin "Files" tab.
class MyDocumentsPage extends StatefulWidget {
  const MyDocumentsPage({super.key});

  @override
  State<MyDocumentsPage> createState() => _MyDocumentsPageState();
}

class _MyDocumentsPageState extends State<MyDocumentsPage> {
  bool _loadingProfile = true;
  String? _resumePath;
  String? _certificatePath;
  String? _barangayClearancePath;

  PdfPickResult? _pendingResume;
  PdfPickResult? _pendingCertificate;
  PdfPickResult? _pendingClearance;

  _DocKind? _uploadingKind;
  _DocKind? _openingKind;

  static const _kBlue = Color(0xFF2563EB);
  static const _kIndigo = Color(0xFF4F46E5);
  static const _kEmerald = Color(0xFF059669);
  static const _kSlate900 = Color(0xFF0F172A);
  static const _kSlate600 = Color(0xFF475569);
  static const _kSlate500 = Color(0xFF64748B);
  static const _kPageBg = Color(0xFFF1F5F9);

  @override
  void initState() {
    super.initState();
    _loadPaths();
  }

  String? _pathForKind(_DocKind k) {
    switch (k) {
      case _DocKind.resume:
        return _resumePath;
      case _DocKind.certificate:
        return _certificatePath;
      case _DocKind.clearance:
        return _barangayClearancePath;
    }
  }

  PdfPickResult? _pendingForKind(_DocKind k) {
    switch (k) {
      case _DocKind.resume:
        return _pendingResume;
      case _DocKind.certificate:
        return _pendingCertificate;
      case _DocKind.clearance:
        return _pendingClearance;
    }
  }

  void _setPending(_DocKind k, PdfPickResult? v) {
    setState(() {
      switch (k) {
        case _DocKind.resume:
          _pendingResume = v;
        case _DocKind.certificate:
          _pendingCertificate = v;
        case _DocKind.clearance:
          _pendingClearance = v;
      }
    });
  }

  Future<void> _loadPaths() async {
    final token = UserSession().token;
    if (token == null || token.isEmpty) {
      if (mounted) setState(() => _loadingProfile = false);
      return;
    }
    final result = await ApiService.getUser(token);
    if (!mounted) return;
    if (result['success'] == true && result['data'] != null) {
      final user = result['data'] as Map<String, dynamic>;
      setState(() {
        _resumePath = user['resume_path'] as String?;
        _certificatePath = user['certificate_path'] as String?;
        _barangayClearancePath = user['barangay_clearance_path'] as String?;
        _loadingProfile = false;
      });
    } else {
      setState(() => _loadingProfile = false);
    }
  }

  String _basename(String? path) {
    if (path == null || path.isEmpty) return '';
    return path.split(RegExp(r'[/\\]')).last;
  }

  Future<void> _pickForKind(_DocKind kind) async {
    final token = UserSession().token;
    if (token == null || token.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to upload documents')),
        );
      }
      return;
    }

    final existing = _pathForKind(kind);
    if (existing != null && existing.isNotEmpty && _pendingForKind(kind) == null) {
      final replace = await showAppDialog<bool>(
        context: context,
        type: AppDialogType.warning,
        icon: Icons.swap_horiz_rounded,
        title: 'Replace This File?',
        message:
            'A file is already on file for ${_labelForKind(kind)}. Uploading a new file will replace it.',
        confirmLabel: 'Choose File',
        onConfirm: () => Navigator.pop(context, true),
        onCancel: () => Navigator.pop(context, false),
      );
      if (replace != true || !mounted) return;
    }

    try {
      if (!kIsWeb) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (!mounted) return;
      }

      final PdfPickResult? picked = await pdf_picker.pickPdf();

      if (!mounted) return;
      if (picked == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No PDF selected')),
        );
        return;
      }
      _setPending(kind, picked);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _uploadPending(_DocKind kind) async {
    final token = UserSession().token;
    final pending = _pendingForKind(kind);
    if (token == null || pending == null) return;

    setState(() => _uploadingKind = kind);

    Future<Map<String, dynamic>> doUpload() async {
      if (pending.bytes != null) {
        switch (kind) {
          case _DocKind.resume:
            return ApiService.uploadResumeBytes(
              token: token,
              fileBytes: pending.bytes!,
              fileName: pending.name,
            );
          case _DocKind.certificate:
            return ApiService.uploadCertificateBytes(
              token: token,
              fileBytes: pending.bytes!,
              fileName: pending.name,
            );
          case _DocKind.clearance:
            return ApiService.uploadBarangayClearanceBytes(
              token: token,
              fileBytes: pending.bytes!,
              fileName: pending.name,
            );
        }
      }
      final path = pending.path!;
      switch (kind) {
        case _DocKind.resume:
          return ApiService.uploadResume(
            token: token,
            filePath: path,
            fileName: pending.name,
          );
        case _DocKind.certificate:
          return ApiService.uploadCertificate(
            token: token,
            filePath: path,
            fileName: pending.name,
          );
        case _DocKind.clearance:
          return ApiService.uploadBarangayClearance(
            token: token,
            filePath: path,
            fileName: pending.name,
          );
      }
    }

    try {
      final uploadResult = await doUpload();
      if (!mounted) return;
      final ok = uploadResult['success'] == true;
      setState(() {
        _uploadingKind = null;
        if (ok) {
          if (kind == _DocKind.resume) {
            _pendingResume = null;
          } else if (kind == _DocKind.certificate) {
            _pendingCertificate = null;
          } else {
            _pendingClearance = null;
          }
        }
      });
      if (ok) {
        await _loadPaths();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_labelForKind(kind)} uploaded successfully'),
              backgroundColor: const Color(0xFF16A34A),
            ),
          );
        }
      } else {
        final msg = uploadResult['message'] as String? ?? 'Upload failed';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: const Color(0xFFDC2626)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingKind = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _viewDocument(_DocKind kind) async {
    final path = _pathForKind(kind);
    if (path == null || path.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No file on record')),
        );
      }
      return;
    }
    final token = UserSession().token;
    if (token == null || token.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to view documents')),
        );
      }
      return;
    }
    final type = switch (kind) {
      _DocKind.resume => 'resume',
      _DocKind.certificate => 'certificate',
      _DocKind.clearance => 'clearance',
    };
    setState(() => _openingKind = kind);
    try {
      final res = await ApiService.fetchJobseekerDocument(token: token, type: type);
      if (!mounted) return;
      if (res.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              res.statusCode == 404
                  ? 'File not found on server'
                  : 'Could not open document (${res.statusCode})',
            ),
          ),
        );
        return;
      }
      await doc_open.openPdfBytes(res.bodyBytes, _basename(path));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _openingKind = null);
    }
  }

  static String _labelForKind(_DocKind k) {
    switch (k) {
      case _DocKind.resume:
        return 'Resume / CV';
      case _DocKind.certificate:
        return 'Certificate / Diploma';
      case _DocKind.clearance:
        return 'Barangay clearance';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kPageBg,
      body: RefreshIndicator(
        color: _kBlue,
        onRefresh: _loadPaths,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              floating: true,
              pinned: true,
              elevation: 0,
              backgroundColor: _kPageBg,
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                color: _kSlate900,
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: const Text(
                'My documents',
                style: TextStyle(
                  color: _kSlate900,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              centerTitle: true,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _kBlue.withValues(alpha: 0.12),
                            _kIndigo.withValues(alpha: 0.06),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _kBlue.withValues(alpha: 0.15)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'APPLICATION DOCUMENTS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: _kBlue.withValues(alpha: 0.85),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Upload and keep these files current.',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _kSlate900,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'PESO staff and employers may review them during hiring. '
                            'All documents must be PDF only. Max 5 MB each.',
                            style: TextStyle(
                              fontSize: 13,
                              color: _kSlate600,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
                    ),
                  ],
                ),
              ),
            ),
            if (_loadingProfile)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator(color: _kBlue)),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildDocCard(
                      kind: _DocKind.resume,
                      accent: _kBlue,
                      icon: Icons.description_rounded,
                      title: 'Resume / CV',
                      hint: 'PDF format (required for most applications)',
                    )
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 100.ms)
                        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
                    const SizedBox(height: 14),
                    _buildDocCard(
                      kind: _DocKind.certificate,
                      accent: _kIndigo,
                      icon: Icons.workspace_premium_rounded,
                      title: 'Certificate / Diploma',
                      hint: 'PDF — educational or training credentials',
                    )
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 200.ms)
                        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
                    const SizedBox(height: 14),
                    _buildDocCard(
                      kind: _DocKind.clearance,
                      accent: _kEmerald,
                      icon: Icons.verified_user_rounded,
                      title: 'Barangay clearance',
                      hint: 'PDF — valid barangay clearance',
                    )
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 300.ms)
                        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocCard({
    required _DocKind kind,
    required Color accent,
    required IconData icon,
    required String title,
    required String hint,
  }) {
    final path = _pathForKind(kind);
    final uploaded = path != null && path.isNotEmpty;
    final pending = _pendingForKind(kind);
    final uploading = _uploadingKind == kind;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: accent, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _kSlate900,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: uploaded
                                  ? const Color(0xFFDCFCE7)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              uploaded ? 'Uploaded' : 'Missing',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: uploaded
                                    ? const Color(0xFF166534)
                                    : _kSlate500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hint,
                        style: const TextStyle(
                          fontSize: 13,
                          color: _kSlate500,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (uploaded && pending == null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.insert_drive_file_rounded, color: accent, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _basename(path),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _kSlate900,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (pending != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: accent.withValues(alpha: 0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pending.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _kSlate900,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Ready to upload',
                      style: TextStyle(fontSize: 12, color: _kSlate500),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: uploading ? null : () => _setPending(kind, null),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _kSlate600,
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: uploading ? null : () => _uploadPending(kind),
                            icon: uploading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.cloud_upload_rounded, size: 20),
                            label: Text(uploading ? 'Uploading…' : 'Upload'),
                            style: FilledButton.styleFrom(
                              backgroundColor: accent,
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
            const SizedBox(height: 16),
            Row(
              children: [
                if (uploaded && pending == null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _openingKind == kind
                          ? null
                          : () => _viewDocument(kind),
                      icon: _openingKind == kind
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.open_in_new_rounded, size: 20),
                      label: Text(_openingKind == kind ? 'Opening…' : 'View'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: accent,
                        side: BorderSide(color: accent.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                if (uploaded && pending == null) const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: uploading ? null : () => _pickForKind(kind),
                    icon: Icon(
                      uploaded ? Icons.sync_rounded : Icons.add_rounded,
                      size: 20,
                    ),
                    label: Text(uploaded ? 'Replace' : 'Upload file'),
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
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
    );
  }
}
