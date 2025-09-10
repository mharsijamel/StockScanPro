import 'package:flutter/foundation.dart';

class AppConfig {
  // Configuration pour différents environnements
  static const String _devBaseUrl = 'https://smart.webvue.tn';
  static const String _stagingBaseUrl = 'https://smart.webvue.tn';
  static const String _prodBaseUrl = 'https://smart.webvue.tn';

  // Configuration actuelle basée sur l'environnement
  static String get baseUrl {
    if (kDebugMode) {
      // Mode développement
      return _devBaseUrl;
    } else if (kProfileMode) {
      // Mode staging/test
      return _stagingBaseUrl;
    } else {
      // Mode production
      return _prodBaseUrl;
    }
  }

  // Configuration manuelle (pour override)
  static String? _manualBaseUrl;
  static String? _selectedDatabase;

  static String get currentBaseUrl => _manualBaseUrl ?? baseUrl;
  static String? get selectedDatabase => _selectedDatabase;

  static void setManualBaseUrl(String url) {
    _manualBaseUrl = url;
  }

  static void setBaseUrl(String url) {
    _manualBaseUrl = url;
  }

  static void setSelectedDatabase(String database) {
    _selectedDatabase = database;
  }

  static void clearManualBaseUrl() {
    _manualBaseUrl = null;
  }

  static void clearSelectedDatabase() {
    _selectedDatabase = null;
  }

  static void clearConfiguration() {
    _manualBaseUrl = null;
    _selectedDatabase = null;
  }

  // Validation de l'URL
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  // URLs communes pour Odoo
  static const List<String> commonOdooUrls = [
    'http://localhost:8069',
    'http://192.168.1.100:8069',
    'https://your-company.odoo.com',
    'https://your-domain.com',
  ];
}
