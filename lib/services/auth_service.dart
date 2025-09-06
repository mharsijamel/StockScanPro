import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';
import '../constants/app_constants.dart';

class AuthService {
  final ApiService _apiService;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  AuthService(this._apiService);
  
  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    try {
      final token = await _secureStorage.read(key: AppConstants.tokenKey);
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
  
  // Get stored username
  Future<String?> getUsername() async {
    try {
      return await _secureStorage.read(key: AppConstants.usernameKey);
    } catch (e) {
      return null;
    }
  }
  
  // Get stored token
  Future<String?> getToken() async {
    try {
      return await _secureStorage.read(key: AppConstants.tokenKey);
    } catch (e) {
      return null;
    }
  }
  
  // Login method
  Future<bool> login(String username, String password) async {
    try {
      final response = await _apiService.post(
        AppConstants.authEndpoint,
        data: {
          'username': username,
          'password': password,
        },
      );
      
      if (response['success'] == true && response['token'] != null) {
        // Store authentication data
        await _secureStorage.write(
          key: AppConstants.tokenKey,
          value: response['token'],
        );
        await _secureStorage.write(
          key: AppConstants.usernameKey,
          value: username,
        );
        
        if (response['user_id'] != null) {
          await _secureStorage.write(
            key: AppConstants.userIdKey,
            value: response['user_id'].toString(),
          );
        }
        
        return true;
      }
      
      return false;
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }
  
  // Logout method
  Future<void> logout() async {
    try {
      // Clear all stored authentication data
      await _secureStorage.delete(key: AppConstants.tokenKey);
      await _secureStorage.delete(key: AppConstants.usernameKey);
      await _secureStorage.delete(key: AppConstants.userIdKey);
      
      // Optional: Call logout endpoint if available
      // await _apiService.post('/auth/logout');
    } catch (e) {
      // Even if logout fails, clear local data
      await _secureStorage.deleteAll();
    }
  }
  
  // Refresh token if needed
  Future<bool> refreshToken() async {
    try {
      final currentToken = await getToken();
      if (currentToken == null) return false;
      
      // Implement token refresh logic if your API supports it
      // For now, just check if current token is still valid
      return await isAuthenticated();
    } catch (e) {
      return false;
    }
  }
}
