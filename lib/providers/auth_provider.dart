import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;
  String? _username;
  
  AuthProvider(this._authService);
  
  // Getters
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get username => _username;
  
  // Check authentication status on app start
  Future<bool> checkAuthenticationStatus() async {
    _setLoading(true);
    
    try {
      final isAuth = await _authService.isAuthenticated();
      if (isAuth) {
        _username = await _authService.getUsername();
      }
      _isAuthenticated = isAuth;
      _error = null;
      return isAuth;
    } catch (e) {
      _error = e.toString();
      _isAuthenticated = false;
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Login method
  Future<bool> login(String username, String password) async {
    _setLoading(true);
    _error = null;
    
    try {
      final success = await _authService.login(username, password);
      if (success) {
        _isAuthenticated = true;
        _username = username;
      }
      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Logout method
  Future<void> logout() async {
    _setLoading(true);
    
    try {
      await _authService.logout();
      _isAuthenticated = false;
      _username = null;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }
  
  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
