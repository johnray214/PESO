import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'user_session.dart';

class ApiService {
  static const String baseUrl =
      'http://10.77.187.42:8000/api';

  /// True when [baseUrl] points at a machine-local / emulator-typical host.
  ///
  /// Connection failures here mean "API unreachable" (wrong host on emulator,
  /// backend stopped, etc.), not loss of internet — so the global offline modal
  /// should not treat them as "no Wi‑Fi / no internet".
  static bool get isTargetingLocalDevHost {
    final uri = Uri.tryParse(baseUrl);
    if (uri == null) return false;
    final host = uri.host.toLowerCase();
    if (host == 'localhost' || host == '127.0.0.1' || host == '::1') {
      return true;
    }
    // Android emulator: host loopback maps here, not to 127.0.0.1 on device.
    if (host == '10.0.2.2') return true;
    // Common LAN dev (Laravel on another machine).
    if (host.startsWith('192.168.')) return true;
    return false;
  }

  /// e.g. http://127.0.0.1:8000 — for `/storage/...` URLs.
  static String get apiOrigin {
    final uri = Uri.parse(baseUrl);
    return Uri(
      scheme: uri.scheme,
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
    ).toString();
  }

  static String publicStorageUrl(String relativePath) {
    if (relativePath.isEmpty) return '';
    final clean = relativePath.replaceFirst(RegExp(r'^/+'), '');
    return '$apiOrigin/storage/$clean';
  }

  /// Relative public-disk path or already-absolute URL (from API `employer_photo_url`).
  ///
  /// Laravel builds absolute URLs with the **incoming request host** (`PublicStorageUrl`).
  /// If that host (e.g. `127.0.0.1`) does not match [baseUrl] (e.g. `10.0.2.2` on Android
  /// emulator, or a LAN IP on a device), [Image.network] fails silently → initials only.
  /// For paths under `/storage`, we always use [apiOrigin] so images match the API host.
  static String? storageOrAbsoluteUrl(String? ref) {
    if (ref == null) return null;
    final t = ref.trim();
    if (t.isEmpty) return null;

    if (t.startsWith('http://') || t.startsWith('https://')) {
      final uri = Uri.tryParse(t);
      if (uri != null && uri.path.startsWith('/storage')) {
        final origin = Uri.parse(apiOrigin);
        return Uri(
          scheme: origin.scheme,
          host: origin.host,
          port: origin.hasPort ? origin.port : null,
          path: uri.path,
          query: uri.hasQuery ? uri.query : null,
        ).toString();
      }
      return t;
    }

    return publicStorageUrl(t);
  }

  static void Function()? onNetworkError;

  static Map<String, dynamic> _handleError(Object e, {String? customMessage}) {
    // Check if it's a network-related failure
    final isNetwork = e is SocketException ||
        e is TimeoutException ||
        e.toString().contains('SocketException') ||
        e.toString().contains('Connection failed');

    if (isNetwork) {
      // Local API: "connection refused" / timeouts are almost never "no internet".
      if (!isTargetingLocalDevHost) {
        onNetworkError?.call();
      }
      return {
        'success': false,
        'message': isTargetingLocalDevHost
            ? 'Cannot reach the server. On Android emulator use 10.0.2.2 '
                'instead of 127.0.0.1, or use your PC\'s LAN IP — and ensure '
                'the API is running.'
            : 'No internet connection. Please check your network and try again.',
        'is_network_error': true,
      };
    }

    return {
      'success': false,
      'message': customMessage ?? 'Connection error: Service temporarily unavailable.',
    };
  }

  static Future<Map<String, dynamic>> checkJobseekerEmail(String email) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/jobseeker/check-email?email=$email'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      // For this one, we might not want to show the global modal if it's just a quick check,
      // but the user wants to change "all of them", so let's be consistent.
      return _handleError(e, customMessage: 'Check email failed');
    }
  }

  static Future<Map<String, dynamic>> register({
    required String firstName,
    String? middleInitial,
    required String lastName,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String contact,
    String? address,
    required String sex, // 'male' | 'female'
    String? dateOfBirth, // 'YYYY-MM-DD'
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/jobseeker/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'first_name': firstName,
              'middle_initial': middleInitial,
              'last_name': lastName,
              'email': email,
              'password': password,
              'password_confirmation': passwordConfirmation,
              'contact': contact,
              'address': address,
              'sex': sex,
              'date_of_birth': dateOfBirth,
            }),
          )
          .timeout(const Duration(seconds: 25));

      return jsonDecode(response.body);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// Sends a password reset link to the jobseeker email (Laravel Password broker).
  static Future<Map<String, dynamic>> forgotJobseekerPassword({
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/jobseeker/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email.trim()}),
      );
      final body = response.body.trim();
      if (body.isEmpty) {
        return {
          'success': false,
          'message': 'Empty response from server (${response.statusCode})',
        };
      }
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        return {'success': false, 'message': 'Invalid server response'};
      }
      final map = Map<String, dynamic>.from(decoded);
      if (map['success'] == null) {
        map['success'] =
            response.statusCode >= 200 && response.statusCode < 300;
      }
      return map;
    } catch (e) {
      return _handleError(e);
    }
  }

  /// Completes password reset (same contract as Vue `JobseekerReset.vue`).
  static Future<Map<String, dynamic>> resetJobseekerPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/jobseeker/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
          'token': token,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      );
      final body = response.body.trim();
      if (body.isEmpty) {
        return {
          'success': false,
          'message': 'Empty response from server (${response.statusCode})',
        };
      }
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        return {'success': false, 'message': 'Invalid server response'};
      }
      final map = Map<String, dynamic>.from(decoded);
      if (map['success'] == null) {
        map['success'] =
            response.statusCode >= 200 && response.statusCode < 300;
      }
      return map;
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/jobseeker/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> verifyJobseekerOtp({
    required String email,
    required String otpCode,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/jobseeker/verify-otp'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'otp_code': otpCode,
            }),
          )
          .timeout(const Duration(seconds: 20));
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> resendJobseekerOtp({
    required String email,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/jobseeker/resend-otp'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 20));
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Resend request timed out. Please try again shortly.',
      };
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> logout(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/jobseeker/logout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// Authenticated jobseeker: change password (`current_password`, `password`, `password_confirmation`).
  static Future<Map<String, dynamic>> changeJobseekerPassword({
    required String token,
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/jobseeker/profile/password'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'current_password': currentPassword,
              'password': password,
              'password_confirmation': passwordConfirmation,
            }),
          )
          .timeout(const Duration(seconds: 25));

      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'success': false, 'message': 'Unexpected response from server.'};
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> requestJobseekerEmailChangeOtp({
    required String token,
    required String newEmail,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/jobseeker/profile/email/request-otp'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'new_email': newEmail.trim()}),
          )
          .timeout(const Duration(seconds: 20));
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> confirmJobseekerEmailChangeOtp({
    required String token,
    required String newEmail,
    required String otpCode,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/jobseeker/profile/email/confirm-otp'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'new_email': newEmail.trim(),
              'otp_code': otpCode.trim(),
            }),
          )
          .timeout(const Duration(seconds: 20));
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> getUser(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/jobseeker/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<List<dynamic>> getProvinces() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/locations/provinces'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data['data'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      _handleError(e, customMessage: 'Error fetching provinces');
      return [];
    }
  }

  static Future<List<dynamic>> getCities(int provinceId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/locations/cities/$provinceId'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data['data'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      _handleError(e, customMessage: 'Error fetching cities');
      return [];
    }
  }

  static Future<List<dynamic>> getBarangays(int cityId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/locations/barangays/$cityId'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data['data'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      _handleError(e, customMessage: 'Error fetching barangays');
      return [];
    }
  }

  // ─── Events ──────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getEvents() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/public/events'),
        headers: {'Content-Type': 'application/json'},
      );
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>)
        return {'success': false, 'message': 'Invalid response'};

      final data = decoded['data'];
      if (decoded['success'] == true &&
          data is Map<String, dynamic> &&
          data['data'] is List) {
        return {
          'success': true,
          'data': data['data'],
          'meta': {
            'current_page': data['current_page'],
            'last_page': data['last_page'],
            'total': data['total'],
          },
        };
      }

      return decoded;
    } catch (e) {
      return _handleError(e);
    }
  }

  /// Public events + registered event IDs when jobseeker is logged in.
  static Future<Map<String, dynamic>> getEventsWithRegistration() async {
    final base = await getEvents();
    if (base['success'] != true) return base;
    final token = UserSession().token;
    if (token == null || token.isEmpty) return base;
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/jobseeker/events/registered-ids'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> &&
          decoded['success'] == true &&
          decoded['data'] is List) {
        base['registered_ids'] = decoded['data'];
      }
    } catch (_) {
      /* ignore */
    }
    return base;
  }

  static Future<Map<String, dynamic>> registerForEvent({
    required String token,
    required int eventId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/jobseeker/events/$eventId/register'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> unregisterFromEvent({
    required String token,
    required int eventId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/jobseeker/events/$eventId/register'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return _handleError(e);
    }
  }

  // ─── Job Listings ────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getJobListings() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/public/jobs'),
        headers: {'Content-Type': 'application/json'},
      );
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>)
        return {'success': false, 'message': 'Invalid response'};

      // Normalize Laravel pagination shape:
      // { success: true, data: { data: [...] , ...pagination } }
      final data = decoded['data'];
      if (decoded['success'] == true &&
          data is Map<String, dynamic> &&
          data['data'] is List) {
        return {
          'success': true,
          'data': data['data'],
          'meta': {
            'current_page': data['current_page'],
            'last_page': data['last_page'],
            'total': data['total'],
          },
        };
      }

      return decoded;
    } catch (e) {
      return _handleError(e);
    }
  }

  // ─── Applications & Saved Jobs ───────────────────────────────────────────────

  static Future<Map<String, dynamic>> getApplications(String token) async {
    try {
      final uri = Uri.parse('$baseUrl/jobseeker/applications').replace(
        queryParameters: {
          '_ts': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
        },
      );
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return {'success': false, 'message': 'Invalid response'};
      }
      final data = decoded['data'];
      if (decoded['success'] == true &&
          data is Map<String, dynamic> &&
          data['data'] is List) {
        return {
          'success': true,
          'data': data['data'],
        };
      }
      return decoded;
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> applyToJob({
    required String token,
    required int jobListingId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/jobseeker/applications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'job_listing_id': jobListingId}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> getSavedJobs(String token) async {
    try {
      final uri = Uri.parse('$baseUrl/jobseeker/saved-jobs').replace(
        queryParameters: {
          '_ts': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
        },
      );
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return {'success': false, 'message': 'Invalid response'};
      }
      final data = decoded['data'];
      if (decoded['success'] == true &&
          data is Map<String, dynamic> &&
          data['data'] is List) {
        return {
          'success': true,
          'data': data['data'],
        };
      }
      return decoded;
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> saveJob({
    required String token,
    required int jobListingId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/jobseeker/saved-jobs'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'job_listing_id': jobListingId}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> unsaveJob({
    required String token,
    required int jobListingId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/jobseeker/saved-jobs/$jobListingId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return jsonDecode(response.body);
    } catch (e) {
      return _handleError(e);
    }
  }

  // ─── Profile ─────────────────────────────────────────────────────────────────

  /// Get current user's avatar image bytes. Returns null if none or error.
  static Future<List<int>?> getAvatarBytes(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/jobseeker/profile/avatar'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode != 200) return null;
      final bytes = response.bodyBytes;
      return bytes.isEmpty ? null : bytes;
    } catch (_) {
      return null;
    }
  }

  /// Upload avatar from file path (mobile/desktop).
  static Future<Map<String, dynamic>> uploadAvatar({
    required String token,
    required String filePath,
    required String fileName,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/jobseeker/profile/avatar'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        await http.MultipartFile.fromPath('avatar', filePath,
            filename: fileName),
      );
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      final body = response.body.trim();
      if (response.statusCode != 200) {
        return {
          'success': false,
          'message':
              response.statusCode == 422 ? 'Invalid image' : 'Upload failed'
        };
      }
      try {
        return jsonDecode(body) as Map<String, dynamic>;
      } catch (_) {
        return {'success': false, 'message': 'Invalid response'};
      }
    } catch (e) {
      return _handleError(e);
    }
  }

  /// Upload avatar from bytes (web).
  static Future<Map<String, dynamic>> uploadAvatarBytes({
    required String token,
    required List<int> fileBytes,
    required String fileName,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/jobseeker/profile/avatar'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        http.MultipartFile.fromBytes('avatar', fileBytes, filename: fileName),
      );
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      final body = response.body.trim();
      if (response.statusCode != 200) {
        return {
          'success': false,
          'message':
              response.statusCode == 422 ? 'Invalid image' : 'Upload failed'
        };
      }
      try {
        return jsonDecode(body) as Map<String, dynamic>;
      } catch (_) {
        return {'success': false, 'message': 'Invalid response'};
      }
    } catch (e) {
      return _handleError(e);
    }
  }

  static Map<String, dynamic> _parseResumeResponse(http.Response response) {
    final body = response.body.trim();
    if (body.isEmpty) {
      return {
        'success': false,
        'message': 'Server returned empty response (${response.statusCode})',
      };
    }
    if (body.startsWith('<')) {
      return {
        'success': false,
        'message': response.statusCode >= 500
            ? 'Server error (${response.statusCode}). Check that the backend is running and the database is migrated.'
            : 'Server returned an error page (${response.statusCode}). Check the API URL and backend.',
      };
    }
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return {
        'success': false,
        'message': 'Invalid server response (${response.statusCode})',
      };
    }
  }

  /// Upload resume from a file path (mobile/desktop).
  static Future<Map<String, dynamic>> uploadResume({
    required String token,
    required String filePath,
    required String fileName,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/jobseeker/profile/resume'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        await http.MultipartFile.fromPath('resume', filePath,
            filename: fileName),
      );
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      return _parseResumeResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// Get a one-time URL to view the resume. Returns map with 'url' (if success) or 'error'.
  static Future<Map<String, dynamic>> getResumeViewUrl(String token) async {
    try {
      final profile = await getUser(token);
      if (profile['success'] != true || profile['data'] == null) {
        return {'error': profile['message'] ?? 'Could not load profile'};
      }
      final data = profile['data'] as Map<String, dynamic>;
      final path = data['resume_path'] as String?;
      if (path == null || path.isEmpty) {
        return {'error': 'No resume on file'};
      }
      return {'url': publicStorageUrl(path)};
    } catch (e) {
      return {'error': 'Connection error: $e'};
    }
  }

  /// Download own document PDF (auth). [type]: resume | certificate | clearance
  static Future<http.Response> fetchJobseekerDocument({
    required String token,
    required String type,
  }) async {
    return http.get(
      Uri.parse('$baseUrl/jobseeker/profile/documents/$type'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/pdf,*/*',
      },
    );
  }

  /// Upload resume from bytes (used on web where file path is not available).
  static Future<Map<String, dynamic>> uploadResumeBytes({
    required String token,
    required List<int> fileBytes,
    required String fileName,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/jobseeker/profile/resume'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        http.MultipartFile.fromBytes('resume', fileBytes, filename: fileName),
      );
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      return _parseResumeResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// Certificate / diploma (PDF or image, max 5MB server-side).
  static Future<Map<String, dynamic>> uploadCertificate({
    required String token,
    required String filePath,
    required String fileName,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/jobseeker/profile/certificate'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        await http.MultipartFile.fromPath('certificate', filePath,
            filename: fileName),
      );
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      return _parseResumeResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> uploadCertificateBytes({
    required String token,
    required List<int> fileBytes,
    required String fileName,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/jobseeker/profile/certificate'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        http.MultipartFile.fromBytes('certificate', fileBytes,
            filename: fileName),
      );
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      return _parseResumeResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> uploadBarangayClearance({
    required String token,
    required String filePath,
    required String fileName,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/jobseeker/profile/barangay-clearance'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        await http.MultipartFile.fromPath('barangay_clearance', filePath,
            filename: fileName),
      );
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      return _parseResumeResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> uploadBarangayClearanceBytes({
    required String token,
    required List<int> fileBytes,
    required String fileName,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/jobseeker/profile/barangay-clearance'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        http.MultipartFile.fromBytes('barangay_clearance', fileBytes,
            filename: fileName),
      );
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      return _parseResumeResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> submitSatisfactionRating(
      String token, int rating) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/jobseeker/satisfaction-rating'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'rating': rating}),
      );
      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      return jsonResponse;
    } catch (e) {
      return _handleError(e, customMessage: 'Network error submitting rating.');
    }
  }

  static Future<Map<String, dynamic>> updateProfile({
    required String token,
    String? firstName,
    String? middleInitial,
    String? lastName,
    String? email,
    String? contact,
    String? address,
    String? provinceCode,
    String? provinceName,
    String? cityCode,
    String? cityName,
    String? barangayCode,
    String? barangayName,
    String? streetAddress,
    String? sex,
    String? dateOfBirth,
    String? bio,
    String? educationLevel,
    String? jobExperience,
    bool? isOnboardingDone,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (firstName != null && firstName.isNotEmpty) {
        body['first_name'] = firstName;
      }
      if (middleInitial != null) {
        body['middle_initial'] = middleInitial.isEmpty ? null : middleInitial;
      }
      if (lastName != null && lastName.isNotEmpty) {
        body['last_name'] = lastName;
      }
      if (email != null && email.isNotEmpty) body['email'] = email;
      if (contact != null) body['contact'] = contact;
      if (address != null) body['address'] = address;
      if (provinceCode != null) body['province_code'] = provinceCode;
      if (provinceName != null) body['province_name'] = provinceName;
      if (cityCode != null) body['city_code'] = cityCode;
      if (cityName != null) body['city_name'] = cityName;
      if (barangayCode != null) body['barangay_code'] = barangayCode;
      if (barangayName != null) body['barangay_name'] = barangayName;
      if (streetAddress != null) body['street_address'] = streetAddress;
      if (sex != null) body['sex'] = sex;
      if (dateOfBirth != null) body['date_of_birth'] = dateOfBirth;
      if (bio != null) body['bio'] = bio;
      if (educationLevel != null) body['education_level'] = educationLevel;
      if (jobExperience != null) body['job_experience'] = jobExperience;
      if (isOnboardingDone != null) {
        body['is_onboarding_done'] = isOnboardingDone;
      }

      final response = await http.put(
        Uri.parse('$baseUrl/jobseeker/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return _handleError(e);
    }
  }

  // ─── Skills ──────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> updateSkills({
    required String token,
    required List<String> skills,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/jobseeker/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'skills': skills}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> getJobById(
    String token,
    int id,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/jobseeker/jobs/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> getMatchedJobs(
    String token, {
    List<String>? skills,
  }) async {
    try {
      final hasSkills = skills != null && skills.isNotEmpty;
      final uri = Uri.parse(
        hasSkills
            ? '$baseUrl/jobseeker/jobs?skills=${Uri.encodeQueryComponent(skills.join(','))}'
            : '$baseUrl/jobseeker/jobs',
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      // Normalize Laravel paginated shape:
      // { success: true, data: { data: [...] } } -> { success: true, data: [...] }
      if (data['success'] == true) {
        final raw = data['data'];
        if (raw is Map<String, dynamic> && raw['data'] is List) {
          return {
            'success': true,
            'data': raw['data'],
            'meta': raw,
          };
        }
      }

      return data;
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> getSkillCatalog() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/jobs-skills/catalog'),
        headers: {'Content-Type': 'application/json'},
      );
      return jsonDecode(response.body);
    } catch (e) {
      return _handleError(e);
    }
  }

  // ─── Skills Catalog (new catalog from `skills` table) ──────────────────

  static Future<Map<String, dynamic>> getPublicSkills({String? q}) async {
    try {
      final uri = Uri.parse(q != null && q.trim().isNotEmpty
          ? '$baseUrl/public/skills?q=${Uri.encodeQueryComponent(q.trim())}'
          : '$baseUrl/public/skills');

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> getJobseekerSkills(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/jobseeker/skills'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> saveJobseekerSkills({
    required String token,
    required List<int> skillIds,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/jobseeker/skills'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'skill_ids': skillIds,
        }),
      );
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return _handleError(e);
    }
  }

  // ─── Locations ────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getAllLocations() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/locations/all'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return {
          'provinces': data['data']['provinces'] as List<dynamic>,
          'cities': data['data']['cities'] as List<dynamic>,
          'barangays': data['data']['barangays'] as List<dynamic>,
        };
      }
      return {
        'provinces': [],
        'cities': [],
        'barangays': [],
      };
    } catch (e) {
      _handleError(e, customMessage: 'Error fetching all locations');
      return {
        'provinces': [],
        'cities': [],
        'barangays': [],
      };
    }
  }

  // ─── Jobseeker Notifications ─────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getJobseekerNotifications({
    required String token,
    int page = 1,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/jobseeker/notifications?page=$page'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<int> getJobseekerUnreadNotificationCount(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/jobseeker/notifications/unread-count'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] == true &&
          data['data'] is Map<String, dynamic> &&
          (data['data'] as Map<String, dynamic>)['unread_count'] is int) {
        return (data['data'] as Map<String, dynamic>)['unread_count'] as int;
      }
      return 0;
    } catch (e) {
      _handleError(e);
      return 0;
    }
  }

  static Future<Map<String, dynamic>> getJobseekerNotification({
    required String token,
    required int id,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/jobseeker/notifications/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<bool> deleteJobseekerNotification({
    required String token,
    required int id,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/jobseeker/notifications/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['success'] == true;
    } catch (e) {
      _handleError(e);
      return false;
    }
  }

  static Future<bool> deleteAllJobseekerNotifications(String token) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/jobseeker/notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['success'] == true;
    } catch (e) {
      _handleError(e);
      return false;
    }
  }

  // ─── Map ─────────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getMapEmployers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/public/map/employers'),
        headers: {'Content-Type': 'application/json'},
      );
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return _handleError(e);
    }
  }

  /// Send the FCM device token to the Laravel backend (Step 9)
  static Future<Map<String, dynamic>> updateFCMToken(
      String token, String fcmToken) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/jobseeker/save-fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'fcm_token': fcmToken}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return _handleError(e);
    }
  }
}
