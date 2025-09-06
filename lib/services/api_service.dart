import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class ApiService {
  final String baseUrl = AppConstants.baseUrl;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  // Get headers with authentication token
  Future<Map<String, String>> _getHeaders() async {
    final token = await _secureStorage.read(key: AppConstants.tokenKey);
    
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
  
  // GET request
  Future<Map<String, dynamic>> get(String endpoint, {Map<String, String>? queryParams}) async {
    try {
      final uri = Uri.parse('$baseUrl${AppConstants.apiPrefix}$endpoint');
      final uriWithParams = queryParams != null 
          ? uri.replace(queryParameters: queryParams)
          : uri;
      
      final headers = await _getHeaders();
      
      final response = await http.get(
        uriWithParams,
        headers: headers,
      ).timeout(const Duration(seconds: AppConstants.apiTimeoutSeconds));
      
      return _handleResponse(response);
    } catch (e) {
      throw Exception('GET request failed: ${e.toString()}');
    }
  }
  
  // POST request
  Future<Map<String, dynamic>> post(String endpoint, {Map<String, dynamic>? data}) async {
    try {
      final uri = Uri.parse('$baseUrl${AppConstants.apiPrefix}$endpoint');
      final headers = await _getHeaders();
      
      final response = await http.post(
        uri,
        headers: headers,
        body: data != null ? json.encode(data) : null,
      ).timeout(const Duration(seconds: AppConstants.apiTimeoutSeconds));
      
      return _handleResponse(response);
    } catch (e) {
      throw Exception('POST request failed: ${e.toString()}');
    }
  }
  
  // PUT request
  Future<Map<String, dynamic>> put(String endpoint, {Map<String, dynamic>? data}) async {
    try {
      final uri = Uri.parse('$baseUrl${AppConstants.apiPrefix}$endpoint');
      final headers = await _getHeaders();
      
      final response = await http.put(
        uri,
        headers: headers,
        body: data != null ? json.encode(data) : null,
      ).timeout(const Duration(seconds: AppConstants.apiTimeoutSeconds));
      
      return _handleResponse(response);
    } catch (e) {
      throw Exception('PUT request failed: ${e.toString()}');
    }
  }
  
  // DELETE request
  Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final uri = Uri.parse('$baseUrl${AppConstants.apiPrefix}$endpoint');
      final headers = await _getHeaders();
      
      final response = await http.delete(
        uri,
        headers: headers,
      ).timeout(const Duration(seconds: AppConstants.apiTimeoutSeconds));
      
      return _handleResponse(response);
    } catch (e) {
      throw Exception('DELETE request failed: ${e.toString()}');
    }
  }
  
  // Handle HTTP response
  Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final Map<String, dynamic> data = json.decode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Invalid JSON response: ${response.body}');
      }
      rethrow;
    }
  }
  
  // Check network connectivity
  Future<bool> checkConnectivity() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
