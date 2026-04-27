import 'package:flutter/material.dart';
import 'api_service.dart';
import 'user_session.dart';

/// Centralized singleton for managing job save/apply actions across the app.
/// All pages should use this service to ensure state consistency.
class JobActionService extends ChangeNotifier {
  static final JobActionService _instance = JobActionService._internal();
  factory JobActionService() => _instance;
  JobActionService._internal();

  final Set<String> _savedJobIds = {};
  final Set<String> _appliedJobIds = {};

  Set<String> get savedJobIds => Set.unmodifiable(_savedJobIds);
  Set<String> get appliedJobIds => Set.unmodifiable(_appliedJobIds);

  bool isSaved(String jobId) => _savedJobIds.contains(jobId);
  bool isApplied(String jobId) => _appliedJobIds.contains(jobId);

  /// Returns true when the current user has an uploaded resume on file.
  Future<bool> hasResumeOnFile() async {
    final token = UserSession().token;
    if (token == null || token.isEmpty) return false;

    final userResult = await ApiService.getUser(token);
    if (userResult['success'] != true) return false;
    final data = userResult['data'];
    if (data is! Map<String, dynamic>) return false;
    final resumePath = (data['resume_path'] as String?)?.trim() ?? '';
    return resumePath.isNotEmpty;
  }

  /// Load saved and applied jobs from backend on app start or login.
  Future<void> loadFromBackend() async {
    final token = UserSession().token;
    if (token == null || token.isEmpty) {
      _savedJobIds.clear();
      _appliedJobIds.clear();
      notifyListeners();
      return;
    }

    try {
      final appsResult = await ApiService.getApplications(token);
      final savedResult = await ApiService.getSavedJobs(token);

      final applied = <String>{};
      final saved = <String>{};

      if (appsResult['success'] == true) {
        final list = appsResult['data'] as List<dynamic>? ?? [];
        for (final item in list) {
          final map = item as Map<String, dynamic>;
          final id = map['job_listing_id'];
          if (id != null) applied.add(id.toString());
        }
      }

      if (savedResult['success'] == true) {
        final list = savedResult['data'] as List<dynamic>? ?? [];
        for (final item in list) {
          final map = item as Map<String, dynamic>;
          final id = map['job_listing_id'];
          if (id != null) saved.add(id.toString());
        }
      }

      _appliedJobIds
        ..clear()
        ..addAll(applied);
      _savedJobIds
        ..clear()
        ..addAll(saved);
      notifyListeners();
    } catch (_) {
      // Ignore errors silently; UI can still function
    }
  }

  /// Apply to a job. Returns success message or null on failure.
  Future<String?> applyToJob(String jobId, String jobTitle) async {
    final token = UserSession().token;
    if (token == null || token.isEmpty) {
      return 'Please sign in to apply for jobs.';
    }

    final id = int.tryParse(jobId);
    if (id == null) return 'Invalid job ID.';

    if (_appliedJobIds.contains(jobId)) {
      return 'You already applied to this job.';
    }

    final result = await ApiService.applyToJob(token: token, jobListingId: id);

    if (result['success'] == true) {
      _appliedJobIds.add(jobId);
      notifyListeners();
      return null; // success
    } else {
      return result['message'] as String? ?? 'Failed to submit application.';
    }
  }

  /// Save a job. Returns success message or null on failure.
  Future<String?> saveJob(String jobId) async {
    final token = UserSession().token;
    if (token == null || token.isEmpty) {
      return 'Please sign in to save jobs.';
    }

    final id = int.tryParse(jobId);
    if (id == null) return 'Invalid job ID.';

    if (_savedJobIds.contains(jobId)) {
      return 'Job already saved.';
    }

    final result = await ApiService.saveJob(token: token, jobListingId: id);

    if (result['success'] == true) {
      _savedJobIds.add(jobId);
      notifyListeners();
      return null; // success
    } else {
      return result['message'] as String? ?? 'Failed to save job.';
    }
  }

  /// Unsave a job. Returns success message or null on failure.
  Future<String?> unsaveJob(String jobId) async {
    final token = UserSession().token;
    if (token == null || token.isEmpty) {
      return 'Please sign in.';
    }

    final id = int.tryParse(jobId);
    if (id == null) return 'Invalid job ID.';

    final result = await ApiService.unsaveJob(token: token, jobListingId: id);

    if (result['success'] == true) {
      _savedJobIds.remove(jobId);
      notifyListeners();
      return null; // success
    } else {
      return result['message'] as String? ?? 'Failed to unsave job.';
    }
  }

  /// Toggle save state (save if not saved, unsave if saved).
  Future<String?> toggleSave(String jobId) async {
    if (_savedJobIds.contains(jobId)) {
      return await unsaveJob(jobId);
    } else {
      return await saveJob(jobId);
    }
  }

  void clear() {
    _savedJobIds.clear();
    _appliedJobIds.clear();
    notifyListeners();
  }
}
