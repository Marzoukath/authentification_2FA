import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/api_response.dart';
import 'storage_service.dart';
import '../utils/environment_config.dart';

class ApiService {
  static String get baseUrl => EnvironmentConfig.getBaseUrl();

  final StorageService _storageService = StorageService();

  Future<Map<String, String>> _getHeaders({bool requiresAuth = false}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth) {
      final token = await _storageService.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Future<ApiResponse> register({
    required String name,
    required String email,
    String? phone,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      );

      return ApiResponse.fromJson(jsonDecode(response.body));
    } catch (e) {
      return ApiResponse(success: false, message: 'Erreur de connexion: $e');
    }
  }

  Future<ApiResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: await _getHeaders(),
        body: jsonEncode({'email': email, 'password': password}),
      );

      return ApiResponse.fromJson(jsonDecode(response.body));
    } catch (e) {
      return ApiResponse(success: false, message: 'Erreur de connexion: $e');
    }
  }

  Future<ApiResponse> verify2FA({
    required int userId,
    required String code,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/2fa/verify'),
        headers: await _getHeaders(),
        body: jsonEncode({'user_id': userId, 'code': code}),
      );

      return ApiResponse.fromJson(jsonDecode(response.body));
    } catch (e) {
      return ApiResponse(success: false, message: 'Erreur de vérification: $e');
    }
  }

  Future<ApiResponse> sendVerificationCode(int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/2fa/send-code'),
        headers: await _getHeaders(),
        body: jsonEncode({'user_id': userId}),
      );

      return ApiResponse.fromJson(jsonDecode(response.body));
    } catch (e) {
      return ApiResponse(success: false, message: 'Erreur d\'envoi: $e');
    }
  }

  Future<ApiResponse> logout() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: await _getHeaders(requiresAuth: true),
      );

      return ApiResponse.fromJson(jsonDecode(response.body));
    } catch (e) {
      return ApiResponse(success: false, message: 'Erreur de déconnexion: $e');
    }
  }

  Future<ApiResponse> getUser() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user'),
        headers: await _getHeaders(requiresAuth: true),
      );

      return ApiResponse.fromJson(jsonDecode(response.body));
    } catch (e) {
      return ApiResponse(success: false, message: 'Erreur de récupération: $e');
    }
  }

  Future<ApiResponse> enable2FATOTP() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/2fa/totp/enable'),
        headers: await _getHeaders(requiresAuth: true),
      );

      return ApiResponse.fromJson(jsonDecode(response.body));
    } catch (e) {
      return ApiResponse(success: false, message: 'Erreur: $e');
    }
  }

  Future<ApiResponse> confirm2FATOTP(String code) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/2fa/totp/confirm'),
        headers: await _getHeaders(requiresAuth: true),
        body: jsonEncode({'code': code}),
      );

      return ApiResponse.fromJson(jsonDecode(response.body));
    } catch (e) {
      return ApiResponse(success: false, message: 'Erreur: $e');
    }
  }

  Future<ApiResponse> enable2FASMS(String phone) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/2fa/sms/enable'),
        headers: await _getHeaders(requiresAuth: true),
        body: jsonEncode({'phone': phone}),
      );

      return ApiResponse.fromJson(jsonDecode(response.body));
    } catch (e) {
      return ApiResponse(success: false, message: 'Erreur: $e');
    }
  }

  Future<ApiResponse> confirm2FASMS(String code) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/2fa/sms/confirm'),
        headers: await _getHeaders(requiresAuth: true),
        body: jsonEncode({'code': code}),
      );

      return ApiResponse.fromJson(jsonDecode(response.body));
    } catch (e) {
      return ApiResponse(success: false, message: 'Erreur: $e');
    }
  }

  Future<ApiResponse> enable2FAEmail() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/2fa/email/enable'),
        headers: await _getHeaders(requiresAuth: true),
      );

      return ApiResponse.fromJson(jsonDecode(response.body));
    } catch (e) {
      return ApiResponse(success: false, message: 'Erreur: $e');
    }
  }

  Future<ApiResponse> confirm2FAEmail(String code) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/2fa/email/confirm'),
        headers: await _getHeaders(requiresAuth: true),
        body: jsonEncode({'code': code}),
      );

      return ApiResponse.fromJson(jsonDecode(response.body));
    } catch (e) {
      return ApiResponse(success: false, message: 'Erreur: $e');
    }
  }

  Future<ApiResponse> disable2FA() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/2fa/disable'),
        headers: await _getHeaders(requiresAuth: true),
      );

      return ApiResponse.fromJson(jsonDecode(response.body));
    } catch (e) {
      return ApiResponse(success: false, message: 'Erreur: $e');
    }
  }

  Future<ApiResponse> get2FAStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/2fa/status'),
        headers: await _getHeaders(requiresAuth: true),
      );

      return ApiResponse.fromJson(jsonDecode(response.body));
    } catch (e) {
      return ApiResponse(success: false, message: 'Erreur: $e');
    }
  }
}
