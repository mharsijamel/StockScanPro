import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_service.dart';
import '../models/auth_models.dart';

enum AuthStatus { Uninitialized, Authenticated, Unauthenticated, Authenticating }

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  AuthStatus _status = AuthStatus.Uninitialized;
  String? _token;
  AuthRequest? _credentials;

  AuthStatus get status => _status;
  String? get token => _token;
  AuthRequest? get credentials => _credentials;

  AuthProvider() {
    _loadTokenAndCredentials();
  }

  Future<void> _loadTokenAndCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    final credentialsJson = prefs.getString('credentials');

    if (_token != null && credentialsJson != null) {
      _credentials = AuthRequest(
        url: json.decode(credentialsJson)['url'],
        database: json.decode(credentialsJson)['database'],
        login: json.decode(credentialsJson)['login'],
        password: '' // Ne pas garder le mot de passe en clair
      );
      _status = AuthStatus.Authenticated;
    } else {
      _status = AuthStatus.Unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(AuthRequest credentials) async {
    log('🔑 AuthProvider: Starting login process');
    log('🌐 AuthProvider: URL: ${credentials.url}');
    log('🗄️ AuthProvider: Database: ${credentials.database}');
    log('👤 AuthProvider: Login: ${credentials.login}');
    
    _status = AuthStatus.Authenticating;
    notifyListeners();
    log('📱 AuthProvider: Status set to Authenticating');

    try {
      log('📞 AuthProvider: Calling API service...');
      AuthResponse response = await _apiService.login(credentials);
      log('💬 AuthProvider: API response received');
      log('📈 AuthProvider: Response status: ${response.status}');
      
      if (response.status == 'success' && response.token != null) {
        log('✅ AuthProvider: Login successful');
        _token = response.token;
        _credentials = credentials;
        _status = AuthStatus.Authenticated;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        // On sauvegarde les credentials pour les réutiliser, sauf le mot de passe
        await prefs.setString('credentials', json.encode(credentials.toJson()));
        
        log('💾 AuthProvider: Credentials saved to storage');
        notifyListeners();
        return true;
      } else {
        log('❌ AuthProvider: Login failed - ${response.message ?? "Unknown error"}');
        _status = AuthStatus.Unauthenticated;
        notifyListeners();
        return false;
      }
    } catch (e) {
      log('💥 AuthProvider: Exception during login: $e');
      _status = AuthStatus.Unauthenticated;
      notifyListeners();
      rethrow; // Re-throw to let the UI handle the specific error
    }
  }

  Future<void> logout() async {
    _token = null;
    _credentials = null;
    _status = AuthStatus.Unauthenticated;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('credentials');

    notifyListeners();
  }
}
