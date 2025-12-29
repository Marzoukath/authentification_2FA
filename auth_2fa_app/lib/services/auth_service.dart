import '../models/user.dart';
import '../models/api_response.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  Future<ApiResponse> register({
    required String name,
    required String email,
    String? phone,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await _apiService.register(
      name: name,
      email: email,
      phone: phone,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );

    if (response.success && response.data != null) {
      await _storageService.saveToken(response.data['token']);
      await _storageService.saveUser(response.data['user']);
    }

    return response;
  }

  Future<ApiResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiService.login(email: email, password: password);

    if (response.success && !response.requires2fa!) {
      await _storageService.saveToken(response.data['token']);
      await _storageService.saveUser(response.data['user']);
    }

    return response;
  }

  Future<ApiResponse> verify2FA({
    required int userId,
    required String code,
  }) async {
    final response = await _apiService.verify2FA(userId: userId, code: code);

    if (response.success && response.data != null) {
      await _storageService.saveToken(response.data['token']);
      await _storageService.saveUser(response.data['user']);
    }

    return response;
  }

  Future<ApiResponse> verifyTOTP({
    required int userId,
    required String code,
  }) async {
    final response = await _apiService.verify2FA(userId: userId, code: code);

    if (response.success && response.data != null) {
      await _storageService.saveToken(response.data['token']);
      await _storageService.saveUser(response.data['user']);
    }

    return response;
  }

  Future<ApiResponse> verifySMS({
    required int userId,
    required String code,
  }) async {
    final response = await _apiService.verify2FA(userId: userId, code: code);

    if (response.success && response.data != null) {
      await _storageService.saveToken(response.data['token']);
      await _storageService.saveUser(response.data['user']);
    }

    return response;
  }

  Future<void> logout() async {
    await _apiService.logout();
    await _storageService.clearAll();
  }

  Future<User?> getCurrentUser() async {
    final userData = await _storageService.getUser();
    if (userData != null) {
      return User.fromJson(userData);
    }
    return null;
  }

  Future<bool> isLoggedIn() async {
    return await _storageService.hasToken();
  }
}
