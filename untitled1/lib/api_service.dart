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
