import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    int? age,
    String? gender,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
          'age': age,
          'gender': gender,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> logout(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> getUser(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
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
      print('Error fetching provinces: $e');
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
      print('Error fetching cities: $e');
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
      print('Error fetching barangays: $e');
      return [];
    }
  }

  // ─── Events ──────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getEvents() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/events'),
        headers: {'Content-Type': 'application/json'},
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  // ─── Job Listings ────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getJobListings() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/jobs'),
        headers: {'Content-Type': 'application/json'},
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  // ─── Applications & Saved Jobs ───────────────────────────────────────────────

  static Future<Map<String, dynamic>> getApplications(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/applications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> applyToJob({
    required String token,
    required int jobListingId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/applications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'job_listing_id': jobListingId}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> getSavedJobs(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/saved-jobs'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> saveJob({
    required String token,
    required int jobListingId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/saved-jobs'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'job_listing_id': jobListingId}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> unsaveJob({
    required String token,
    required int jobListingId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/saved-jobs/$jobListingId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  // ─── Profile ─────────────────────────────────────────────────────────────────

  /// Get current user's avatar image bytes. Returns null if none or error.
  static Future<List<int>?> getAvatarBytes(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/avatar'),
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
        Uri.parse('$baseUrl/user/avatar'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        await http.MultipartFile.fromPath('avatar', filePath, filename: fileName),
      );
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      final body = response.body.trim();
      if (response.statusCode != 200) {
        return {'success': false, 'message': response.statusCode == 422 ? 'Invalid image' : 'Upload failed'};
      }
      try {
        return jsonDecode(body) as Map<String, dynamic>;
      } catch (_) {
        return {'success': false, 'message': 'Invalid response'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
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
        Uri.parse('$baseUrl/user/avatar'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        http.MultipartFile.fromBytes('avatar', fileBytes, filename: fileName),
      );
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      final body = response.body.trim();
      if (response.statusCode != 200) {
        return {'success': false, 'message': response.statusCode == 422 ? 'Invalid image' : 'Upload failed'};
      }
      try {
        return jsonDecode(body) as Map<String, dynamic>;
      } catch (_) {
        return {'success': false, 'message': 'Invalid response'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
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
        Uri.parse('$baseUrl/user/resume'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        await http.MultipartFile.fromPath('resume', filePath, filename: fileName),
      );
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      return _parseResumeResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  /// Get a one-time URL to view the resume. Returns map with 'url' (if success) or 'error'.
  static Future<Map<String, dynamic>> getResumeViewUrl(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/resume/view-url'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      final body = response.body.trim();
      if (body.isEmpty) {
        return {'error': 'Empty response (${response.statusCode})'};
      }
      if (response.statusCode != 200) {
        String msg = 'Server error (${response.statusCode})';
        if (body.startsWith('{')) {
          try {
            final data = jsonDecode(body) as Map<String, dynamic>?;
            if (data != null && data['message'] != null) {
              msg = data['message'] as String;
            }
          } catch (_) {}
        }
        return {'error': msg};
      }
      final data = jsonDecode(body) as Map<String, dynamic>?;
      if (data == null || data['success'] != true) {
        return {'error': data?['message'] as String? ?? 'Could not get view link'};
      }
      final url = data['url'] as String?;
      if (url == null || url.isEmpty) return {'error': 'No URL in response'};
      return {'url': url};
    } catch (e) {
      return {'error': 'Connection error: $e'};
    }
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
        Uri.parse('$baseUrl/user/resume'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        http.MultipartFile.fromBytes('resume', fileBytes, filename: fileName),
      );
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      return _parseResumeResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> updateProfile({
    required String token,
    String? name,
    String? email,
    String? phone,
    String? address,
    int? age,
    String? gender,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null && name.isNotEmpty) body['name'] = name;
      if (email != null && email.isNotEmpty) body['email'] = email;
      if (phone != null) body['phone'] = phone;
      if (address != null) body['address'] = address;
      if (age != null) body['age'] = age;
      if (gender != null) body['gender'] = gender;

      final response = await http.put(
        Uri.parse('$baseUrl/user/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  // ─── Skills ──────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> updateSkills({
    required String token,
    required List<String> skills,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/user/skills'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'skills': skills}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> getMatchedJobs(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/jobs-matched'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
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
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
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
      print('Error fetching all locations: $e');
      return {
        'provinces': [],
        'cities': [],
        'barangays': [],
      };
    }
  }
}
