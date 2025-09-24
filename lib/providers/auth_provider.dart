import 'dart:convert';
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
    _status = AuthStatus.Authenticating;
    notifyListeners();

    try {
      AuthResponse response = await _apiService.login(credentials);
      if (response.status == 'success' && response.token != null) {
        _token = response.token;
        _credentials = credentials;
        _status = AuthStatus.Authenticated;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        // On sauvegarde les credentials pour les réutiliser, sauf le mot de passe
        await prefs.setString('credentials', json.encode(credentials.toJson()));
        
        notifyListeners();
        return true;
      } else {
        _status = AuthStatus.Unauthenticated;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _status = AuthStatus.Unauthenticated;
      notifyListeners();
      return false;
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
