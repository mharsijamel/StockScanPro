import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';
import '../config/app_config.dart';

enum HealthCheckResult {
  ok,
  notFound,
  badRequest,
  networkError,
  unknownError,
}

class ApiService {
  String get baseUrl => AppConfig.currentBaseUrl;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: '$baseUrl${AppConstants.apiPrefix}',
      connectTimeout: const Duration(seconds: AppConstants.apiTimeoutSeconds),
      receiveTimeout: const Duration(seconds: AppConstants.apiTimeoutSeconds),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add interceptors
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _secureStorage.read(key: AppConstants.tokenKey);
        final database = AppConfig.selectedDatabase;

        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        if (database != null) {
          options.headers['X-Openerp-Database'] = database;
        }

        handler.next(options);
      },
      onError: (error, handler) {
        print('API Error: ${error.message}');
        handler.next(error);
      },
    ));
  }

  // GET request
  Future<Map<String, dynamic>> get(String endpoint,
      {Map<String, String>? queryParams}) async {
    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParams,
      );

      return _handleResponse(response);
    } catch (e) {
      if (e is DioException) {
        return _handleDioError(e);
      }
      throw Exception('GET request failed: ${e.toString()}');
    }
  }

  // POST request
  Future<Map<String, dynamic>> post(String endpoint,
      {Map<String, dynamic>? data}) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: data,
      );

      return _handleResponse(response);
    } catch (e) {
      if (e is DioException) {
        return _handleDioError(e);
      }
      throw Exception('POST request failed: ${e.toString()}');
    }
  }

  // PUT request
  Future<Map<String, dynamic>> put(String endpoint,
      {Map<String, dynamic>? data}) async {
    try {
      final response = await _dio.put(
        endpoint,
        data: data,
      );

      return _handleResponse(response);
    } catch (e) {
      if (e is DioException) {
        return _handleDioError(e);
      }
      throw Exception('PUT request failed: ${e.toString()}');
    }
  }

  // DELETE request
  Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final response = await _dio.delete(endpoint);

      return _handleResponse(response);
    } catch (e) {
      if (e is DioException) {
        return _handleDioError(e);
      }
      throw Exception('DELETE request failed: ${e.toString()}');
    }
  }

  // Handle HTTP response
  Map<String, dynamic> _handleResponse(Response response) {
    try {
      final data = response.data;

      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        if (data is Map<String, dynamic>) {
          return data;
        } else {
          return {'success': true, 'data': data};
        }
      } else {
        return {
          'success': false,
          'message': data is Map
              ? (data['message'] ?? 'Erreur HTTP ${response.statusCode}')
              : 'Erreur HTTP ${response.statusCode}',
          'status_code': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de traitement de la réponse',
        'error': e.toString(),
      };
    }
  }

  // Handle Dio errors
  Map<String, dynamic> _handleDioError(DioException error) {
    String errorMessage;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        errorMessage = 'Timeout - Le serveur met trop de temps à répondre';
        break;
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 404) {
          errorMessage =
              'Endpoint non trouvé (404) - Vérifiez l\'URL du serveur';
        } else if (statusCode == 500) {
          errorMessage = 'Erreur interne du serveur (500)';
        } else if (statusCode == 403) {
          errorMessage = 'Accès refusé (403)';
        } else if (statusCode == 401) {
          errorMessage = 'Non autorisé (401)';
        } else {
          errorMessage = 'Erreur serveur: $statusCode';
        }
        break;
      case DioExceptionType.cancel:
        errorMessage = 'Requête annulée';
        break;
      case DioExceptionType.connectionError:
        errorMessage =
            'Erreur de connexion - Vérifiez votre connexion internet';
        break;
      default:
        errorMessage = 'Erreur de requête: ${error.message}';
    }

    return {
      'success': false,
      'message': errorMessage,
      'status_code': error.response?.statusCode,
      'error': error.toString(),
    };
  }

  // Perform a health check to determine API status
  Future<HealthCheckResult> healthCheck() async {
    try {
      await _dio.get(
        '/health',
        // Use a shorter timeout for the health check
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      // If we get a 2xx response, the API is OK.
      return HealthCheckResult.ok;
    } on DioException catch (e) {
      // If we get a 404, it means the module is not installed/active
      if (e.response?.statusCode == 404) {
        return HealthCheckResult.notFound;
      }
      if (e.response?.statusCode == 400) {
        return HealthCheckResult.badRequest;
      }
      // For timeouts or other connection issues, it's a network error
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        return HealthCheckResult.networkError;
      }
      // For other Dio errors, it's an unknown issue
      return HealthCheckResult.unknownError;
    } catch (_) {
      // For any other non-Dio exception
      return HealthCheckResult.unknownError;
    }
  }
}
