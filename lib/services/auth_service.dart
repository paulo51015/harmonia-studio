import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

/// Serviço de Autenticação e Segurança com persistência local via SharedPreferences.
/// Credenciais padrão iniciais: Usuário 'admin' / Senha '123456'.
class AuthService extends ChangeNotifier {
  static const String _keyPassword = 'harmonia_auth_password';
  static const String _keyUserSession = 'harmonia_auth_session';
  static const String defaultUsername = 'admin';
  static const String defaultPassword = '123456';

  UserModel? _currentUser;
  bool _isAuthenticated = false;
  bool _isInitialized = false;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isInitialized => _isInitialized;

  AuthService() {
    _init();
  }

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Se for a primeira inicialização, salva a senha padrão
      if (!prefs.containsKey(_keyPassword)) {
        await prefs.setString(_keyPassword, defaultPassword);
      }

      final sessionData = prefs.getString(_keyUserSession);
      if (sessionData != null) {
        final map = jsonDecode(sessionData) as Map<String, dynamic>;
        _currentUser = UserModel.fromMap(map);
        _isAuthenticated = true;
      }
    } catch (e) {
      debugPrint('Erro ao inicializar AuthService: $e');
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Realiza login comparando com a senha persistida no dispositivo.
  Future<bool> login(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final savedPassword = prefs.getString(_keyPassword) ?? defaultPassword;

    // Normaliza username para 'admin'
    final cleanUsername = username.trim().toLowerCase();

    if (cleanUsername == defaultUsername && password == savedPassword) {
      _currentUser = UserModel(
        username: defaultUsername,
        displayName: 'Produtor Admin',
        role: 'Master Producer & Instructor',
        lastLogin: DateTime.now(),
      );
      _isAuthenticated = true;

      // Salva sessão
      await prefs.setString(
        _keyUserSession,
        jsonEncode(_currentUser!.toMap()),
      );

      notifyListeners();
      return true;
    }

    return false;
  }

  /// Altera a senha e salva de forma persistente no SharedPreferences.
  Future<({bool success, String? messageKey})> changePassword(
    String currentPassword,
    String newPassword,
    String confirmNewPassword,
  ) async {
    if (newPassword != confirmNewPassword) {
      return (success: false, messageKey: 'password_mismatch');
    }

    if (newPassword.length < 6) {
      return (success: false, messageKey: 'password_too_short');
    }

    final prefs = await SharedPreferences.getInstance();
    final savedPassword = prefs.getString(_keyPassword) ?? defaultPassword;

    if (currentPassword != savedPassword) {
      return (success: false, messageKey: 'invalid_credentials');
    }

    // Salva a nova senha
    await prefs.setString(_keyPassword, newPassword);
    notifyListeners();
    return (success: true, messageKey: 'password_changed_success');
  }

  /// Encerra a sessão ativa.
  Future<void> logout() async {
    _currentUser = null;
    _isAuthenticated = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserSession);

    notifyListeners();
  }
}
