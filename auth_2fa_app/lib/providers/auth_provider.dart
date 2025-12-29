import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  Future<void> loadUser() async {
    _user = await _authService.getCurrentUser();
    notifyListeners();
  }

  Future<bool> register({
    required String name,
    required String email,
    String? phone,
    required String password,
    required String passwordConfirmation,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _authService.register(
      name: name,
      email: email,
      phone: phone,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );

    _isLoading = false;

    if (response.success) {
      _user = User.fromJson(response.data['user']);
      notifyListeners();
      return true;
    } else {
      _errorMessage = response.message ?? 'Erreur d\'inscription';
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _authService.login(email: email, password: password);

    _isLoading = false;

    if (response.success) {
      if (response.requires2fa!) {
        notifyListeners();
        return {
          'success': true,
          'requires_2fa': true,
          'method': response.twoFactorMethod,
          'user_id': response.userId,
        };
      } else {
        _user = User.fromJson(response.data['user']);
        notifyListeners();
        return {'success': true, 'requires_2fa': false};
      }
    } else {
      _errorMessage = response.message ?? 'Erreur de connexion';
      notifyListeners();
      return {'success': false, 'message': _errorMessage};
    }
  }

  Future<bool> verify2FA({required int userId, required String code}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _authService.verify2FA(userId: userId, code: code);

    _isLoading = false;

    if (response.success) {
      _user = User.fromJson(response.data['user']);
      notifyListeners();
      return true;
    } else {
      _errorMessage = response.message ?? 'Code invalide';
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyTOTP({required int userId, required String code}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _authService.verifyTOTP(userId: userId, code: code);

    _isLoading = false;

    if (response.success) {
      _user = User.fromJson(response.data['user']);
      notifyListeners();
      return true;
    } else {
      // Gestion spécifique des erreurs TOTP
      if (response.message != null) {
        if (response.message!.contains('expiré') ||
            response.message!.contains('trop ancien')) {
          _errorMessage = 'Le code TOTP a expiré. Générez un nouveau code.';
        } else if (response.message!.contains('invalide') ||
            response.message!.contains('incorrect')) {
          _errorMessage =
              'Code incorrect. Vérifiez votre application d\'authentification.';
        } else {
          _errorMessage = response.message!;
        }
      } else {
        _errorMessage = 'Code TOTP invalide';
      }
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifySMS({required int userId, required String code}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _authService.verifySMS(userId: userId, code: code);

    _isLoading = false;

    if (response.success) {
      _user = User.fromJson(response.data['user']);
      notifyListeners();
      return true;
    } else {
      // Gestion spécifique des erreurs SMS
      if (response.message != null) {
        if (response.message!.contains('expiré')) {
          _errorMessage = 'Le code SMS a expiré. Demandez un nouveau code.';
        } else if (response.message!.contains('déjà utilisé') ||
            response.message!.contains('consommé')) {
          _errorMessage =
              'Ce code a déjà été utilisé. Demandez un nouveau code.';
        } else if (response.message!.contains('invalide') ||
            response.message!.contains('incorrect')) {
          _errorMessage = 'Code SMS incorrect. Vérifiez le code reçu.';
        } else {
          _errorMessage = response.message!;
        }
      } else {
        _errorMessage = 'Code SMS invalide';
      }
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await _authService.logout();

    _user = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
