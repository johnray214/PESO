import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'job_models.dart';
import 'user_session.dart';
import 'api_service.dart';
import '_error_state_widget.dart';
import 'job_action_service.dart';
import 'skills_profile_page.dart';
import 'resume_upload_page.dart';

// ─── Profile Tab ──────────────────────────────────────────────────────────────
class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  int _appliedCount = 0;
  int _interviewCount = 0;
  int _savedCount = 0;
  List<int>? _avatarBytes;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    final token = UserSession().token;
    if (token == null || UserSession().avatarPath == null) return;
    final bytes = await ApiService.getAvatarBytes(token);
    if (mounted) setState(() => _avatarBytes = bytes);
  }

  String _getGreeting() => '${getPhilippinesGreeting()}, ${UserSession().displayName}.';

  Future<void> _loadStats() async {
    final token = UserSession().token;
    if (token == null || token.isEmpty) {
      setState(() {
        _appliedCount = 0;
        _interviewCount = 0;
        _savedCount = 0;
      });
      return;
    }

    try {
      final appsResult = await ApiService.getApplications(token);
      final savedResult = await ApiService.getSavedJobs(token);

      int applied = 0;
      int interview = 0;
      int saved = 0;

      if (appsResult['success'] == true) {
        final list = appsResult['data'] as List<dynamic>? ?? [];
        applied = list.length;
        interview = list.where((item) {
          final map = item as Map<String, dynamic>;
          final status = (map['status'] as String? ?? '').trim();
          return status == 'Processing';
        }).length;
      }

      if (savedResult['success'] == true) {
        final list = savedResult['data'] as List<dynamic>? ?? [];
        saved = list.length;
      }

      if (!mounted) return;
      setState(() {
        _appliedCount = applied;
        _interviewCount = interview;
        _savedCount = saved;
      });
    } catch (_) {
      // Keep existing counts on error; profile still loads.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  // Greeting and title
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _getGreeting(),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text('👋', style: TextStyle(fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Discover Opportunities',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Profile Avatar with Edit Button
                    Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: _avatarBytes != null && _avatarBytes!.isNotEmpty
                                ? Image.memory(
                                    Uint8List.fromList(_avatarBytes!),
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  )
                                : Center(
                                    child: Text(
                                      UserSession().initials,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 36,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        // Edit button
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: GestureDetector(
                            onTap: () => _showEditProfileSheet(context),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.edit_rounded,
                                size: 16,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // User name
                    Text(
                      UserSession().displayName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),

                    const SizedBox(height: 2),

                    // Email
                    Text(
                      UserSession().email ?? '',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Status chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Text(
                        UserSession().gender != null
                            ? 'Registered Job Seeker · ${UserSession().gender}'
                            : 'Registered Job Seeker',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Stats row
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem(
                            '$_appliedCount',
                            'Applied',
                          ),
                          Container(width: 1, height: 40, color: const Color(0xFFE2E8F0)),
                          _buildStatItem(
                            '$_interviewCount',
                            'Processing',
                          ),
                          Container(width: 1, height: 40, color: const Color(0xFFE2E8F0)),
                          _buildStatItem(
                            '$_savedCount',
                            'Saved',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Menu items
                    _buildMenuItem(
                      icon: Icons.folder_outlined,
                      title: 'My Applications',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const MyApplicationsPage(),
                          ),
                        );
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.bookmark_outline_rounded,
                      title: 'Saved Jobs',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const SavedJobsPage(),
                          ),
                        );
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.psychology_outlined,
                      title: 'Skills Profile',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const SkillsProfilePage(),
                          ),
                        );
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.upload_file_rounded,
                      title: 'My Resume',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ResumeUploadPage(),
                          ),
                        );
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.settings_outlined,
                      title: 'Settings',
                      onTap: () {},
                    ),
                    _buildMenuItem(
                      icon: Icons.help_outline_rounded,
                      title: 'Help & Support',
                      onTap: () {},
                    ),

                    const SizedBox(height: 8),

                    // Sign Out button
                    _buildMenuItem(
                      icon: Icons.logout_rounded,
                      title: 'Sign Out',
                      isSignOut: true,
                      onTap: () => _confirmSignOut(context),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const EditProfileSheet(),
    ).then((_) {
      if (mounted) {
        _loadAvatar();
        setState(() {});
      }
    });
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Sign Out',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF2563EB)),
      ),
    );

    // Call logout API (best-effort — clear session either way)
    final token = UserSession().token;
    if (token != null && token.isNotEmpty) {
      await ApiService.logout(token);
    }

    UserSession().clear();

    if (!mounted) return;
    Navigator.pop(context); // close loading
    // Return all the way to the initial landing page
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSignOut = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSignOut ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSignOut ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isSignOut
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF64748B),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isSignOut
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF0F172A),
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: isSignOut
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Edit Profile Sheet ───────────────────────────────────────────────────────
class EditProfileSheet extends StatefulWidget {
  const EditProfileSheet({super.key});

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  bool _isSaving = false;
  List<int>? _avatarBytes;
  Uint8List? _pickedImageBytes;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: UserSession().name ?? '');
    _emailController = TextEditingController(text: UserSession().email ?? '');
    _phoneController = TextEditingController(text: UserSession().phone ?? '');
    _addressController = TextEditingController(text: UserSession().address ?? '');
    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    final token = UserSession().token;
    if (token == null || UserSession().avatarPath == null) return;
    final bytes = await ApiService.getAvatarBytes(token);
    if (mounted) setState(() => _avatarBytes = bytes);
  }

  Future<void> _pickImage() async {
    try {
      Uint8List? bytes;
      if (kIsWeb) {
        // On web, image_picker throws MissingPluginException; use file_picker instead
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          withData: true,
          withReadStream: false,
        );
        if (result == null || result.files.isEmpty || !mounted) return;
        final file = result.files.single;
        if (file.bytes != null && file.bytes!.isNotEmpty) {
          bytes = file.bytes;
        }
      } else {
        final picker = ImagePicker();
        final xFile = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 512,
          maxHeight: 512,
          imageQuality: 85,
        );
        if (xFile == null || !mounted) return;
        bytes = await xFile.readAsBytes();
      }
      if (bytes != null && bytes.isNotEmpty && mounted) {
        setState(() => _pickedImageBytes = bytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick image: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDec(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
      prefixIcon: Icon(icon, color: const Color(0xFF2563EB)),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        color: Color(0xFF2563EB),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Edit Profile',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close_rounded, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar edit (tap to change photo)
                        Center(
                          child: GestureDetector(
                            onTap: _isSaving ? null : _pickImage,
                            child: Stack(
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF2563EB).withOpacity(0.3),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: _pickedImageBytes != null
                                        ? Image.memory(
                                            _pickedImageBytes!,
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                          )
                                        : _avatarBytes != null && _avatarBytes!.isNotEmpty
                                            ? Image.memory(
                                                Uint8List.fromList(_avatarBytes!),
                                                width: 100,
                                                height: 100,
                                                fit: BoxFit.cover,
                                              )
                                            : Center(
                                                child: Text(
                                                  UserSession().initials,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 36,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2563EB),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_rounded,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Form fields
                        TextFormField(
                          controller: _nameController,
                          decoration: _fieldDec('Full Name', Icons.person_outline_rounded),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Please enter your name';
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _emailController,
                          decoration: _fieldDec('Email', Icons.email_outlined),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Please enter your email';
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _phoneController,
                          decoration: _fieldDec('Phone Number', Icons.phone_outlined),
                          keyboardType: TextInputType.phone,
                          validator: (v) {
                            final value = v?.trim() ?? '';
                            if (value.isEmpty) return null; // optional
                            final phPattern = RegExp(r'^0\d{10}$');
                            if (!phPattern.hasMatch(value)) {
                              return 'Enter 11-digit PH number (e.g. 09XXXXXXXXX)';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _addressController,
                          decoration: _fieldDec('Address', Icons.location_on_outlined),
                        ),

                        const SizedBox(height: 30),

                        // Save button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _isSaving
                                ? null
                                : () async {
                                    if (!_formKey.currentState!.validate()) return;
                                    setState(() => _isSaving = true);

                                    final token = UserSession().token ?? '';
                                    if (_pickedImageBytes != null) {
                                      final uploadResult = await ApiService.uploadAvatarBytes(
                                        token: token,
                                        fileBytes: _pickedImageBytes!,
                                        fileName: 'avatar.jpg',
                                      );
                                      if (uploadResult['success'] != true && mounted) {
                                        setState(() => _isSaving = false);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              uploadResult['message'] as String? ?? 'Failed to upload photo',
                                            ),
                                          ),
                                        );
                                        return;
                                      }
                                    }

                                    final result = await ApiService.updateProfile(
                                      token: token,
                                      name: _nameController.text.trim(),
                                      email: _emailController.text.trim(),
                                      phone: _phoneController.text.trim(),
                                      address: _addressController.text.trim(),
                                    );

                                    if (!mounted) return;
                                    setState(() => _isSaving = false);

                                    if (result['success'] == true) {
                                      final updatedUser =
                                          result['data'] as Map<String, dynamic>? ?? {};
                                      UserSession().updateFromUser(updatedUser);
                                      if (_pickedImageBytes != null) {
                                        final userResult = await ApiService.getUser(token);
                                        if (userResult['success'] == true && userResult['data'] != null) {
                                          UserSession().updateFromUser(userResult['data'] as Map<String, dynamic>);
                                        }
                                      }
                                      if (!mounted) return;
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: const Row(
                                            children: [
                                              Icon(Icons.check_circle_rounded,
                                                  color: Colors.white, size: 18),
                                              SizedBox(width: 8),
                                              Text('Profile updated successfully!'),
                                            ],
                                          ),
                                          backgroundColor: const Color(0xFF10B981),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            result['message'] as String? ??
                                                'Failed to update profile.',
                                          ),
                                          backgroundColor: const Color(0xFFEF4444),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  const Color(0xFF2563EB).withOpacity(0.6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text(
                                    'Save Changes',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Cancel button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF64748B),
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Application Model ────────────────────────────────────────────────────────

class _Application {
  final Job job;
  final String appliedDate;
  final String status;
  final Color statusColor;
  final IconData statusIcon;

  const _Application({
    required this.job,
    required this.appliedDate,
    required this.status,
    required this.statusColor,
    this.statusIcon = Icons.info_outline_rounded,
  });
}

// Legacy demo lists kept for reference only have been removed

// ─── Saved Job Model ──────────────────────────────────────────────────────────

class _SavedJob {
  final Job job;
  final String savedDate;

  const _SavedJob({required this.job, required this.savedDate});
}

// See SavedJobsPage which now loads from backend instead of demo data.

// ─── My Applications Page ────────────────────────────────────────────────────

class MyApplicationsPage extends StatefulWidget {
  const MyApplicationsPage({super.key});

  @override
  State<MyApplicationsPage> createState() => _MyApplicationsPageState();
}

class _MyApplicationsPageState extends State<MyApplicationsPage> {
  final List<_Application> _applications = [];
  bool _isLoading = true;
  String? _errorMessage;
  final _jobActionService = JobActionService();

  @override
  void initState() {
    super.initState();
    _fetchApplications();
    _jobActionService.addListener(_onJobActionsChanged);
  }

  void _onJobActionsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _jobActionService.removeListener(_onJobActionsChanged);
    super.dispose();
  }

  Future<void> _fetchApplications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final token = UserSession().token;
    if (token == null || token.isEmpty) {
      setState(() {
        _applications.clear();
        _isLoading = false;
      });
      return;
    }

    final result = await ApiService.getApplications(token);
    if (!mounted) return;

    if (result['success'] == true) {
      final list = result['data'] as List<dynamic>? ?? [];
      final apps = <_Application>[];
      for (final item in list) {
        final map = item as Map<String, dynamic>;
        final jobData = (map['job_listing'] ?? map['job']) as Map<String, dynamic>? ?? {};
        final job = Job.fromJson(jobData);
        final createdAt =
            DateTime.tryParse(map['applied_at'] as String? ?? map['created_at'] as String? ?? '') ??
                DateTime.now();
        final appliedDate = 'Applied ${createdAt.month}/${createdAt.day}/${createdAt.year}';
        final status = (map['status'] as String? ?? 'Registration').trim();
        // Backward compatibility: map old statuses to new
        final normalizedStatus = switch (status) {
          'Submitted' => 'Registration',
          'Under Review' => 'Processing',
          'Interview Scheduled' => 'Hired',
          'Decision' => 'Processing',
          _ => status,
        };

        Color statusColor;
        IconData statusIcon;
        switch (normalizedStatus) {
          case 'Registration':
            statusColor = const Color(0xFF3B82F6);
            statusIcon = Icons.app_registration_rounded;
            break;
          case 'Processing':
            statusColor = const Color(0xFFF97316);
            statusIcon = Icons.hourglass_top_rounded;
            break;
          case 'Accepted':
            statusColor = const Color(0xFF22C55E);
            statusIcon = Icons.check_circle_rounded;
            break;
          case 'Denied':
            statusColor = const Color(0xFFEF4444);
            statusIcon = Icons.cancel_rounded;
            break;
          case 'Hired':
          case 'Placement':
            statusColor = const Color(0xFF22C55E);
            statusIcon = Icons.work_rounded;
            break;
          default:
            statusColor = const Color(0xFF3B82F6);
            statusIcon = Icons.app_registration_rounded;
        }

        apps.add(_Application(
          job: job,
          appliedDate: appliedDate,
          status: normalizedStatus,
          statusColor: statusColor,
          statusIcon: statusIcon,
        ));
      }

      setState(() {
        _applications
          ..clear()
          ..addAll(apps);
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = result['message'] as String? ?? 'Failed to load applications.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: const Text(
          'My Applications',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE2E8F0)),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2563EB)),
            )
          : _errorMessage != null
              ? ErrorState(
                  message: _errorMessage!,
                  onRetry: _fetchApplications,
                )
              : _applications.isEmpty
                  ? const _EmptyListState(
                      icon: Icons.description_outlined,
                      title: 'No applications yet',
                      subtitle: 'Apply to jobs and your applications will appear here.',
                    )
                  : RefreshIndicator(
                      color: const Color(0xFF2563EB),
                      onRefresh: _fetchApplications,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                        itemCount: _applications.length,
                        itemBuilder: (context, index) {
                          final app = _applications[index];
                          return _ApplicationCard(application: app);
                        },
                      ),
                    ),
    );
  }
}

// ─── Application Card ────────────────────────────────────────────────────────

class _ApplicationCard extends StatelessWidget {
  final _Application application;

  const _ApplicationCard({required this.application});

  @override
  Widget build(BuildContext context) {
    final job = application.job;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openApplicationDetail(context, application),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row: avatar + title + status pill
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: job.companyColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          job.companyInitial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            job.company,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF2563EB),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 12, color: Color(0xFF94A3B8)),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  job.location,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: application.statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: application.statusColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(application.statusIcon,
                              size: 11, color: application.statusColor),
                          const SizedBox(width: 4),
                          Text(
                            application.status,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: application.statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 10),

                // Bottom row: salary, type chip, applied date
                Row(
                  children: [
                    Icon(Icons.payments_outlined,
                        size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      '${job.salaryMin} – ${job.salaryMax}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        job.employmentType,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.access_time_rounded,
                        size: 12, color: Colors.grey[400]),
                    const SizedBox(width: 3),
                    Text(
                      application.appliedDate,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _openApplicationDetail(BuildContext context, _Application application) {
  final job = application.job;
  final banner = _ApplicationStatusBanner(application: application);
  final jobActionService = JobActionService();
  showJobDetailSheet(
    context,
    job,
    headerBanner: banner,
    isApplied: true,
    isSaved: jobActionService.isSaved(job.id),
    onSave: () async {
      final error = await jobActionService.toggleSave(job.id);
      if (context.mounted) {
        if (error == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(jobActionService.isSaved(job.id)
                  ? 'Job saved successfully.'
                  : 'Job removed from saved.'),
              backgroundColor: jobActionService.isSaved(job.id)
                  ? const Color(0xFF2563EB)
                  : const Color(0xFF64748B),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    },
  );
}

// ─── Saved Jobs Page ─────────────────────────────────────────────────────────

class SavedJobsPage extends StatefulWidget {
  const SavedJobsPage({super.key});

  @override
  State<SavedJobsPage> createState() => _SavedJobsPageState();
}

class _SavedJobsPageState extends State<SavedJobsPage> {
  final List<_SavedJob> _savedJobs = [];
  bool _isLoading = true;
  String? _errorMessage;
  final _jobActionService = JobActionService();

  @override
  void initState() {
    super.initState();
    _fetchSavedJobs();
    _jobActionService.addListener(_onJobActionsChanged);
  }

  void _onJobActionsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _jobActionService.removeListener(_onJobActionsChanged);
    super.dispose();
  }

  Future<void> _fetchSavedJobs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final token = UserSession().token;
    if (token == null || token.isEmpty) {
      setState(() {
        _savedJobs.clear();
        _isLoading = false;
      });
      return;
    }

    final result = await ApiService.getSavedJobs(token);
    if (!mounted) return;

    if (result['success'] == true) {
      final list = result['data'] as List<dynamic>? ?? [];
      final items = <_SavedJob>[];

      for (final item in list) {
        final map = item as Map<String, dynamic>;
        final jobData =
            (map['job_listing'] ?? map['job']) as Map<String, dynamic>? ?? {};
        final job = Job.fromJson(jobData);
        final createdAt =
            DateTime.tryParse(map['created_at'] as String? ?? '') ??
                DateTime.now();
        final savedDate = 'Saved ${createdAt.month}/${createdAt.day}/${createdAt.year}';

        items.add(_SavedJob(job: job, savedDate: savedDate));
      }

      setState(() {
        _savedJobs
          ..clear()
          ..addAll(items);
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = result['message'] as String? ?? 'Failed to load saved jobs.';
        _isLoading = false;
      });
    }
  }

  Future<void> _applyToJob(String jobId, String jobTitle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Application'),
        content: Text(
          'Apply for $jobTitle?',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final error = await _jobActionService.applyToJob(jobId, jobTitle);
    if (!mounted) return;

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('Applied to $jobTitle!'),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> _unsaveJob(String jobId) async {
    final error = await _jobActionService.unsaveJob(jobId);
    if (!mounted) return;

    if (error == null) {
      _fetchSavedJobs();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Job removed from saved.'),
          backgroundColor: const Color(0xFF64748B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: const Text(
          'Saved Jobs',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE2E8F0)),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2563EB)),
            )
          : _errorMessage != null
              ? ErrorState(
                  message: _errorMessage!,
                  onRetry: _fetchSavedJobs,
                )
              : _savedJobs.isEmpty
                  ? const _EmptyListState(
                      icon: Icons.bookmark_outline_rounded,
                      title: 'No saved jobs',
                      subtitle:
                          'Tap the bookmark on jobs you like to see them here.',
                    )
                  : RefreshIndicator(
                      color: const Color(0xFF2563EB),
                      onRefresh: _fetchSavedJobs,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                        itemCount: _savedJobs.length,
                        itemBuilder: (context, index) {
                          final saved = _savedJobs[index];
                          final isApplied = _jobActionService.isApplied(saved.job.id);
                          return _SavedJobCard(
                            savedJob: saved,
                            isApplied: isApplied,
                            onApply: () => _applyToJob(saved.job.id, saved.job.title),
                            onUnsave: () => _unsaveJob(saved.job.id),
                          );
                        },
                      ),
                    ),
    );
  }
}

// ─── Saved Job Card ───────────────────────────────────────────────────────────

class _SavedJobCard extends StatelessWidget {
  final _SavedJob savedJob;
  final bool isApplied;
  final VoidCallback onApply;
  final VoidCallback onUnsave;

  const _SavedJobCard({
    required this.savedJob,
    required this.isApplied,
    required this.onApply,
    required this.onUnsave,
  });

  @override
  Widget build(BuildContext context) {
    final job = savedJob.job;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            final jobActionService = JobActionService();
            showJobDetailSheet(
              context,
              job,
              isSaved: true,
              isApplied: jobActionService.isApplied(job.id),
              onApply: onApply,
              onSave: onUnsave,
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: avatar + title + match badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: job.companyColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          job.companyInitial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            job.company,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF2563EB),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 12, color: Color(0xFF94A3B8)),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  job.location,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (job.matchPercentage > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded,
                                size: 12, color: Colors.white),
                            Text(
                              '${job.matchPercentage}%',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 10),

                // Bottom: salary + type + actions
                Row(
                  children: [
                    Icon(Icons.payments_outlined,
                        size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      '${job.salaryMin} – ${job.salaryMax}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        job.employmentType,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: onUnsave,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFFECACA),
                          ),
                        ),
                        child: const Icon(
                          Icons.bookmark_remove_rounded,
                          size: 16,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: isApplied ? null : onApply,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isApplied
                              ? const Color(0xFF10B981)
                              : const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isApplied
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.send_rounded,
                              size: 13,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isApplied ? 'Applied' : 'Apply Now',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Saved date
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(Icons.bookmark_rounded,
                          size: 12, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        savedJob.savedDate,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Application Status Banner ────────────────────────────────────────────────

class _ApplicationStatusBanner extends StatelessWidget {
  final _Application application;

  const _ApplicationStatusBanner({required this.application});

  @override
  Widget build(BuildContext context) {
    final steps = ['Registration', 'Processing', 'Placement/Hired'];
    final statusToStep = {
      'Registration': 0,
      'Processing': 1,
      'Accepted': 1,
      'Denied': 1,
      'Hired': 2,
      'Placement': 2,
    };
    final currentStep = statusToStep[application.status] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: application.statusColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: application.statusColor.withOpacity(0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status header
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: application.statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(application.statusIcon,
                    size: 16, color: application.statusColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Application Status',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      application.status,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: application.statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                application.appliedDate,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Progress timeline
          Row(
            children: List.generate(steps.length, (index) {
              final isDone = index <= currentStep;
              final isLast = index == steps.length - 1;
              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: isDone
                                  ? application.statusColor
                                  : const Color(0xFFE2E8F0),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: isDone
                                  ? const Icon(Icons.check_rounded,
                                      size: 12, color: Colors.white)
                                  : Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF94A3B8),
                                          fontWeight: FontWeight.w700),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            steps[index],
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: isDone
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isDone
                                  ? application.statusColor
                                  : const Color(0xFF94A3B8),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          height: 2,
                          margin: const EdgeInsets.only(bottom: 18),
                          color: index < currentStep
                              ? application.statusColor
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),

          const SizedBox(height: 12),

          // Next steps advice
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 16, color: application.statusColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getNextStepAdvice(application.status),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF475569),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getNextStepAdvice(String status) {
    switch (status) {
      case 'Registration':
        return 'Your application has been registered. It will be processed by the employer for acceptance or denial.';
      case 'Processing':
        return 'Your application is being reviewed. The employer will decide to accept or deny. This typically takes 3–5 business days.';
      case 'Accepted':
        return 'Congratulations! You have been accepted. Awaiting placement confirmation.';
      case 'Denied':
        return 'Your application was not accepted for this position. Keep applying to other opportunities.';
      case 'Hired':
      case 'Placement':
        return 'Congratulations! You have been hired/placed. Follow up with the employer for onboarding details.';
      default:
        return 'You will be notified via email once there are updates to your application.';
    }
  }
}

// ─── Shared Empty State Widget ─────────────────────────────────────────────────

class _EmptyListState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyListState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 56,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
