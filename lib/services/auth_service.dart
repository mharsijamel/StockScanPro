import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import '../constants/app_constants.dart';
import '../config/app_config.dart';

class AuthService {
  final ApiService _apiService;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Simple in-memory storage for web (temporary solution)
  static final Map<String, String> _webStorage = {};

  AuthService(this._apiService);

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    try {
      String? token;
      if (kIsWeb) {
        token = _webStorage[AppConstants.tokenKey];
      } else {
        token = await _secureStorage.read(key: AppConstants.tokenKey);
      }
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Get stored username
  Future<String?> getUsername() async {
    try {
      if (kIsWeb) {
        return _webStorage[AppConstants.usernameKey];
      } else {
        return await _secureStorage.read(key: AppConstants.usernameKey);
      }
    } catch (e) {
      return null;
    }
  }

  // Get stored token
  Future<String?> getToken() async {
    try {
      if (kIsWeb) {
        return _webStorage[AppConstants.tokenKey];
      } else {
        return await _secureStorage.read(key: AppConstants.tokenKey);
      }
    } catch (e) {
      return null;
    }
  }

  // Get stored session cookie for Odoo requests
  Future<String?> getSessionCookie() async {
    try {
      if (kIsWeb) {
        return _webStorage['session_cookie'];
      } else {
        return await _secureStorage.read(key: 'session_cookie');
      }
    } catch (e) {
      return null;
    }
  }

  // Login method with real Odoo authentication
  Future<Map<String, dynamic>> loginWithDatabase(
      String username, String password, String database) async {
    try {
      print('\n🚀 === LOGIN ATTEMPT DEBUG INFO ===');
      print('📅 Timestamp: ${DateTime.now().toIso8601String()}');
      print('🌐 Base URL: ${AppConfig.currentBaseUrl}');
      print(
          '🔗 Auth URL: ${AppConfig.currentBaseUrl}/web/session/authenticate');
      print('👤 Username: $username');
      print(
          '🔐 Password: ${password.replaceAll(RegExp(r'.'), '*')} (${password.length} chars)');
      print('🗄️ Database: $database');
      print('===================================\n');

      print('🔐 Tentative de connexion: $username sur $database');

      // Mode démo pour les tests
      if (username == 'demo' && password == 'demo') {
        print('\n🎥 === DEMO MODE ACTIVATED ===');
        print('📅 Timestamp: ${DateTime.now().toIso8601String()}');
        print('👤 Username: $username');
        print(
            '🔐 Password: ${password.replaceAll(RegExp(r'.'), '*')} (${password.length} chars)');
        print('🗄️ Database: $database');
        print('✅ Mode démo activé');

        final token = 'demo_token_${DateTime.now().millisecondsSinceEpoch}';
        print(
            '🎫 Demo Token: ${token.substring(0, 12)}...${token.substring(token.length - 4)} (${token.length} chars)');
        print('===============================\n');
        final demoUser = {
          'id': 1,
          'name': 'Utilisateur Démo',
          'login': 'demo',
          'email': 'demo@example.com',
          'database': database,
          'access_rights': {
            'stock.picking': ['read', 'write', 'create'],
            'stock.move': ['read', 'write'],
            'product.product': ['read'],
            'stock.production.lot': ['read', 'write', 'create'],
          }
        };

        if (kIsWeb) {
          _webStorage[AppConstants.tokenKey] = token;
          _webStorage[AppConstants.usernameKey] = username;
          _webStorage[AppConstants.userIdKey] = '1';
          _webStorage['is_demo_mode'] = 'true';
          _webStorage['database'] = database;
          _webStorage['user_data'] = json.encode(demoUser);
        } else {
          await _secureStorage.write(key: AppConstants.tokenKey, value: token);
          await _secureStorage.write(
              key: AppConstants.usernameKey, value: username);
          await _secureStorage.write(key: AppConstants.userIdKey, value: '1');
          await _secureStorage.write(key: 'is_demo_mode', value: 'true');
          await _secureStorage.write(key: 'database', value: database);
          await _secureStorage.write(
              key: 'user_data', value: json.encode(demoUser));
        }

        print('✅ Demo login successful - returning demo response\n');
        return {
          'success': true,
          'message': 'Connexion démo réussie',
          'user': demoUser,
          'token': token,
        };
      }

      // Authentification réelle avec Odoo
      print('🌐 Connexion à Odoo...');
      final response = await _authenticateOdoo(username, password, database);

      if (response['success'] == true) {
        print('✅ Authentification Odoo réussie');
        final userData = response['user'];
        final sessionId = response['session_id'];

        print('\n🎉 === LOGIN SUCCESS DEBUG INFO ===');
        print(
            '🎫 Session ID: ${sessionId?.substring(0, 8)}...${sessionId?.substring(sessionId.length - 4)} (${sessionId?.length} chars)');
        print('👤 User ID: ${userData['id']}');
        print('👤 User Name: ${userData['name']}');
        print('👤 User Login: ${userData['login']}');
        print('🗄️ Database: $database');
        print('===================================\n');

        // Add database to user data
        userData['database'] = database;
        userData['access_rights'] = {
          'stock.picking': ['read', 'write', 'create'],
          'stock.move': ['read', 'write'],
          'product.product': ['read'],
          'stock.production.lot': ['read', 'write', 'create'],
        };

        // Store authentication data
        final actualSessionId = response['session_id'];
        final sessionCookie = response['session_cookie'];

        if (kIsWeb) {
          _webStorage[AppConstants.tokenKey] = actualSessionId;
          _webStorage[AppConstants.usernameKey] = username;
          _webStorage[AppConstants.userIdKey] = userData['id'].toString();
          _webStorage['user_name'] = userData['name'] ?? username;
          _webStorage['user_email'] = userData['email'] ?? '';
          _webStorage['is_demo_mode'] = 'false';
          _webStorage['database'] = database;
          _webStorage['user_data'] = json.encode(userData);
          _webStorage['session_cookie'] = sessionCookie ?? '';
        } else {
          await _secureStorage.write(
              key: AppConstants.tokenKey, value: actualSessionId);
          await _secureStorage.write(
              key: AppConstants.usernameKey, value: username);
          await _secureStorage.write(
              key: AppConstants.userIdKey, value: userData['id'].toString());
          await _secureStorage.write(
              key: 'user_name', value: userData['name'] ?? username);
          await _secureStorage.write(
              key: 'user_email', value: userData['email'] ?? '');
          await _secureStorage.write(key: 'is_demo_mode', value: 'false');
          await _secureStorage.write(key: 'database', value: database);
          await _secureStorage.write(
              key: 'user_data', value: json.encode(userData));
          // Store the session cookie for subsequent requests
          await _secureStorage.write(
              key: 'session_cookie', value: sessionCookie ?? '');
        }

        print('✅ Login successful - returning success response\n');
        return {
          'success': true,
          'message': 'Connexion Odoo réussie',
          'user': userData,
          'token': actualSessionId, // Use REAL Odoo session
        };
      } else {
        print('\n❌ === LOGIN FAILURE DEBUG INFO ===');
        print('🔗 URL attempted: ${AppConfig.currentBaseUrl}/api/auth/login');
        print('👤 Username: $username');
        print('🗄️ Database: $database');
        print('❌ Error message: ${response['message']}');
        print('❌ Full response: $response');
        print('===================================\n');

        print('❌ Échec authentification: ${response['message']}');
        return {
          'success': false,
          'message': response['message'] ?? 'Erreur de connexion Odoo',
        };
      }
    } catch (e, stackTrace) {
      print('\n💥 === LOGIN EXCEPTION DEBUG INFO ===');
      print('🔗 URL attempted: ${AppConfig.currentBaseUrl}/api/auth/login');
      print('👤 Username: $username');
      print('🔐 Password length: ${password.length} chars');
      print('🗄️ Database: $database');
      print('❌ Exception: $e');
      print('❌ Exception type: ${e.runtimeType}');
      print('❌ Stack trace: $stackTrace');
      if (e.toString().contains('SocketException')) {
        print('❌ Network error - check internet connection and server URL');
      } else if (e.toString().contains('TimeoutException')) {
        print('❌ Request timeout - server may be slow or unreachable');
      } else if (e.toString().contains('FormatException')) {
        print(
            '❌ Invalid response format - server may not be responding correctly');
      }
      print('=====================================\n');

      print('❌ Erreur login: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion: ${e.toString()}',
      };
    }
  }

  // Méthode de compatibilité
  Future<bool> login(String username, String password) async {
    final result = await loginWithDatabase(username, password, 'demo');
    return result['success'] == true;
  }

  // Get user information
  Future<Map<String, String?>> getUserInfo() async {
    try {
      if (kIsWeb) {
        return {
          'username': _webStorage[AppConstants.usernameKey],
          'user_name': _webStorage['user_name'],
          'user_email': _webStorage['user_email'],
          'user_id': _webStorage[AppConstants.userIdKey],
          'is_demo_mode': _webStorage['is_demo_mode'],
        };
      } else {
        return {
          'username': await _secureStorage.read(key: AppConstants.usernameKey),
          'user_name': await _secureStorage.read(key: 'user_name'),
          'user_email': await _secureStorage.read(key: 'user_email'),
          'user_id': await _secureStorage.read(key: AppConstants.userIdKey),
          'is_demo_mode': await _secureStorage.read(key: 'is_demo_mode'),
        };
      }
    } catch (e) {
      return {};
    }
  }

  // Check if in demo mode
  Future<bool> isDemoMode() async {
    try {
      String? demoMode;
      if (kIsWeb) {
        demoMode = _webStorage['is_demo_mode'];
      } else {
        demoMode = await _secureStorage.read(key: 'is_demo_mode');
      }
      return demoMode == 'true';
    } catch (e) {
      return false;
    }
  }

  // Authentification directe avec Odoo - CORRECT SESSION PATTERN
  Future<Map<String, dynamic>> _authenticateOdoo(
      String username, String password, String database) async {
    try {
      final baseUrl = AppConfig.currentBaseUrl;
      final url = '$baseUrl/web/session/authenticate';

      print('\n🌐 === AUTHENTICATION DEBUG INFO ===');
      print('🔗 Base URL: $baseUrl');
      print('🔗 Full URL: $url');
      print('👤 Username: $username');
      print(
          '🔐 Password: ${password.replaceAll(RegExp(r'.'), '*')} (${password.length} chars)');
      print('🗄️ Database: $database');
      print('📅 Timestamp: ${DateTime.now().toIso8601String()}');
      print('=================================\n');

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'Flutter App',
      };

      // Use STANDARD Odoo session authentication format
      final requestBody = {
        'jsonrpc': '2.0',
        'method': 'call',
        'params': {
          'db': database,
          'login': username,
          'password': password,
        }
      };

      print('📤 Request Headers: $headers');
      print(
          '📤 Request Body: ${json.encode(requestBody).replaceAll(password, '***HIDDEN***')}\n');

      final response = await http
          .post(
            Uri.parse(url),
            headers: headers,
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Headers: ${response.headers}');
      print('📥 Response Body: ${response.body}\n');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Check for JSON-RPC error first
        if (data['error'] != null) {
          final errorMsg = data['error']['message'] ?? 'Authentication failed';
          print('❌ JSON-RPC Error: $errorMsg\n');
          return {
            'success': false,
            'message': errorMsg,
          };
        }

        // Parse successful Odoo session response
        if (data['result'] != null) {
          final result = data['result'];

          // Odoo session response contains user info directly
          final userId = result['uid'];
          final userName = result['name'] ?? result['username'] ?? username;
          final userLogin = result['username'] ?? username;
          final sessionId = result['session_id'];

          print('✅ Authentication successful!');
          print('👤 User ID: $userId');
          print('👤 User Name: $userName');
          print('👤 User Login: $userLogin');
          if (sessionId != null) {
            print(
                '🎫 Session ID: ${sessionId.substring(0, 8)}...${sessionId.substring(sessionId.length - 4)} (${sessionId.length} chars)');
          }

          // Extract cookies from response headers
          final setCookieHeader = response.headers['set-cookie'];
          String? odooSessionCookie;
          if (setCookieHeader != null) {
            // Parse the session cookie from Set-Cookie header
            final cookies = setCookieHeader.split(';');
            for (final cookie in cookies) {
              if (cookie.trim().startsWith('session_id=')) {
                odooSessionCookie = cookie.trim();
                print(
                    '🍪 Extracted session cookie: ${odooSessionCookie.substring(0, 20)}...');
                break;
              }
            }
          }
          print('');

          if (userId == null || userId == false) {
            print('❌ Authentication failed - no user ID in response!');
            return {
              'success': false,
              'message': 'Identifiants incorrects',
            };
          }

          // Use the REAL Odoo session_id instead of generating our own
          final actualSessionId = sessionId ??
              odooSessionCookie?.split('=')[1] ??
              'fallback_session';

          print(
              '🔑 Using Odoo session ID: ${actualSessionId.substring(0, 8)}...');

          return {
            'success': true,
            'user': {
              'id': userId,
              'name': userName,
              'login': userLogin,
              'email': userLogin, // Use login as email for now
            },
            'session_id': actualSessionId, // Use REAL Odoo session
            'session_cookie':
                odooSessionCookie, // Store full cookie for requests
            'database': database,
          };
        } else {
          final errorMsg = 'Invalid response format';
          print('❌ Authentication failed: $errorMsg\n');
          return {
            'success': false,
            'message': errorMsg,
          };
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        print('❌ Response Body: ${response.body}\n');

        String errorMessage;
        if (response.statusCode == 404) {
          errorMessage =
              'Endpoint non trouvé (404) - Vérifiez l\'URL du serveur';
        } else if (response.statusCode == 500) {
          errorMessage = 'Erreur interne du serveur (500)';
        } else if (response.statusCode == 403) {
          errorMessage = 'Accès refusé (403)';
        } else if (response.statusCode == 401) {
          errorMessage = 'Non autorisé (401)';
        } else {
          errorMessage = 'Erreur serveur: ${response.statusCode}';
        }

        return {
          'success': false,
          'message': errorMessage,
          'status_code': response.statusCode,
        };
      }
    } on SocketException catch (e) {
      print('❌ Network error: $e\n');
      return {
        'success': false,
        'message': 'Erreur réseau: Vérifiez votre connexion internet',
      };
    } on TimeoutException catch (e) {
      print('❌ Timeout error: $e\n');
      return {
        'success': false,
        'message': 'Timeout: Le serveur met trop de temps à répondre',
      };
    } on FormatException catch (e) {
      print('❌ Format error: $e\n');
      return {
        'success': false,
        'message': 'Réponse du serveur invalide',
      };
    } catch (e, stackTrace) {
      print('❌ Unexpected exception during authentication: $e');
      print('❌ Exception type: ${e.runtimeType}');
      print('❌ Stack trace: $stackTrace\n');

      return {
        'success': false,
        'message': 'Erreur inattendue: ${e.toString()}',
      };
    }
  }

  // Logout method
  Future<void> logout() async {
    try {
      // Clear all stored authentication data
      if (kIsWeb) {
        _webStorage.clear();
      } else {
        await _secureStorage.delete(key: AppConstants.tokenKey);
        await _secureStorage.delete(key: AppConstants.usernameKey);
        await _secureStorage.delete(key: AppConstants.userIdKey);
        await _secureStorage.delete(key: 'user_name');
        await _secureStorage.delete(key: 'user_email');
        await _secureStorage.delete(key: 'is_demo_mode');
        await _secureStorage.delete(key: 'database');
        await _secureStorage.delete(key: 'user_data');
        await _secureStorage.delete(key: 'session_cookie');
      }
    } catch (e) {
      // Even if logout fails, clear local data
      if (kIsWeb) {
        _webStorage.clear();
      } else {
        await _secureStorage.deleteAll();
      }
    }
  }

  // Test connection to server
  Future<bool> testConnection() async {
    try {
      final response = await _apiService.get('/health');
      return response['success'] == true;
    } catch (e) {
      return false;
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
