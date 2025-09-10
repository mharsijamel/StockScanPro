import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class DatabaseSelectionService {
  
  /// Récupère la liste des bases de données disponibles sur l'instance Odoo
  Future<List<String>> getDatabaseList(String serverUrl) async {
    try {
      // Essayer d'abord notre endpoint personnalisé
      final customUri = Uri.parse('$serverUrl/api/databases');

      final customResponse = await http.get(
        customUri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (customResponse.statusCode == 200) {
        final data = jsonDecode(customResponse.body);
        if (data is Map && data['success'] == true && data.containsKey('databases')) {
          final databases = data['databases'];
          if (databases is List) {
            return _filterDemoDatabases(databases.cast<String>());
          }
        }
      }

      // Si notre endpoint ne fonctionne pas, essayer l'endpoint standard Odoo
      final uri = Uri.parse('$serverUrl/web/database/list');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Odoo retourne les bases de données dans différents formats selon la version
        if (data is Map && data.containsKey('result')) {
          // Format standard Odoo
          final result = data['result'];
          if (result is List) {
            return _filterDemoDatabases(result.cast<String>());
          }
        } else if (data is List) {
          // Format direct (liste)
          return _filterDemoDatabases(data.cast<String>());
        }
      }

      // Si l'endpoint ne fonctionne pas, essayer l'approche alternative
      return await _getDatabaseListAlternative(serverUrl);

    } catch (e) {
      // En cas d'erreur, essayer l'approche alternative
      return await _getDatabaseListAlternative(serverUrl);
    }
  }

  /// Méthode alternative pour récupérer les bases de données
  Future<List<String>> _getDatabaseListAlternative(String serverUrl) async {
    try {
      // Essayer l'endpoint de sélection de base de données
      final uri = Uri.parse('$serverUrl/web/database/selector');
      
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        // Parser le HTML pour extraire les bases de données
        final databases = _parseDatabasesFromHtml(response.body);
        if (databases.isNotEmpty) {
          return _filterDemoDatabases(databases);
        }
      }
      
      // Si aucune méthode ne fonctionne, retourner une liste vide
      return [];
      
    } catch (e) {
      return [];
    }
  }

  /// Parse le HTML de la page de sélection pour extraire les noms des bases de données
  List<String> _parseDatabasesFromHtml(String html) {
    final databases = <String>[];
    
    try {
      // Rechercher les patterns communs dans le HTML d'Odoo
      final patterns = [
        RegExp(r'<option[^>]*value="([^"]+)"[^>]*>([^<]+)</option>'),
        RegExp(r'data-database="([^"]+)"'),
        RegExp(r'"database":\s*"([^"]+)"'),
      ];
      
      for (final pattern in patterns) {
        final matches = pattern.allMatches(html);
        for (final match in matches) {
          final dbName = match.group(1);
          if (dbName != null && dbName.isNotEmpty && !databases.contains(dbName)) {
            databases.add(dbName);
          }
        }
      }
    } catch (e) {
      // Ignore parsing errors
    }
    
    return databases;
  }

  /// Teste si une base de données spécifique est accessible
  Future<bool> testDatabaseConnection(String serverUrl, String database) async {
    try {
      final uri = Uri.parse('$serverUrl/web/database/list');
      
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Openerp-Database': database,
        },
        body: jsonEncode({'database': database}),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Vérifie si le serveur a une seule base de données (pas de sélection nécessaire)
  Future<bool> hasSingleDatabase(String serverUrl) async {
    try {
      final databases = await getDatabaseList(serverUrl);
      return databases.length <= 1;
    } catch (e) {
      return true; // Assume single database on error
    }
  }

  /// Récupère TOUTES les bases de données (y compris les démos) - pour option avancée
  Future<List<String>> getAllDatabaseList(String serverUrl) async {
    try {
      // Essayer d'abord notre endpoint personnalisé
      final customUri = Uri.parse('$serverUrl/api/databases');

      final customResponse = await http.get(
        customUri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (customResponse.statusCode == 200) {
        final data = jsonDecode(customResponse.body);
        if (data is Map && data['success'] == true && data.containsKey('databases')) {
          final databases = data['databases'];
          if (databases is List) {
            return databases.cast<String>(); // Pas de filtrage
          }
        }
      }

      // Si notre endpoint ne fonctionne pas, essayer l'endpoint standard Odoo
      final uri = Uri.parse('$serverUrl/web/database/list');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Odoo retourne les bases de données dans différents formats selon la version
        if (data is Map && data.containsKey('result')) {
          // Format standard Odoo
          final result = data['result'];
          if (result is List) {
            return result.cast<String>(); // Pas de filtrage
          }
        } else if (data is List) {
          // Format direct (liste)
          return data.cast<String>(); // Pas de filtrage
        }
      }

      // Si l'endpoint ne fonctionne pas, essayer l'approche alternative
      return await _getAllDatabaseListAlternative(serverUrl);

    } catch (e) {
      // En cas d'erreur, essayer l'approche alternative
      return await _getAllDatabaseListAlternative(serverUrl);
    }
  }

  /// Méthode alternative pour récupérer TOUTES les bases de données
  Future<List<String>> _getAllDatabaseListAlternative(String serverUrl) async {
    try {
      // Essayer l'endpoint de sélection de base de données
      final uri = Uri.parse('$serverUrl/web/database/selector');

      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // Parser le HTML pour extraire les bases de données
        final databases = _parseDatabasesFromHtml(response.body);
        return databases; // Pas de filtrage
      }

      // Si aucune méthode ne fonctionne, retourner une liste vide
      return [];

    } catch (e) {
      return [];
    }
  }

  /// Récupère la base de données par défaut (première dans la liste)
  Future<String?> getDefaultDatabase(String serverUrl) async {
    try {
      final databases = await getDatabaseList(serverUrl);
      return databases.isNotEmpty ? databases.first : null;
    } catch (e) {
      return null;
    }
  }

  /// Filtre les bases de données de démonstration pour ne garder que les vraies bases
  List<String> _filterDemoDatabases(List<String> databases) {
    print('🔍 FILTRAGE: ${databases.length} bases trouvées: $databases');

    // Patterns des bases de données de démonstration à exclure
    final demoPatterns = [
      // Codes de langues (format ISO) - TOUS les codes
      'sq_AL', 'am_ET', 'ar_SY', 'ar_001', 'eu_ES', 'bn_IN',
      'bg_BG', 'ca_ES', 'cs_CZ', 'da_DK', 'de_DE', 'el_GR',
      'en_US', 'es_ES', 'et_EE', 'fi_FI', 'fr_FR', 'hr_HR',
      'hu_HU', 'it_IT', 'ja_JP', 'ko_KR', 'lt_LT', 'lv_LV',
      'nl_NL', 'pl_PL', 'pt_PT', 'ro_RO', 'ru_RU', 'sk_SK',
      'sl_SI', 'sv_SE', 'th_TH', 'tr_TR', 'uk_UA', 'vi_VN',
      'zh_CN', 'zh_TW', 'ar_EG', 'ar_MA', 'en_GB', 'fr_CA',

      // Codes de langue spéciaux et régionaux
      'kab_DZ', 'sr@latin', 'af', 'al', 'dz', 'as', 'az', 'be',
      'bn', 'bs', 'ca', 'cs', 'cy', 'da', 'de', 'el', 'en',
      'eo', 'es', 'et', 'eu', 'fa', 'fi', 'fo', 'fr', 'fy',
      'ga', 'gl', 'gu', 'he', 'hi', 'hr', 'hu', 'hy', 'id',
      'is', 'it', 'ja', 'ka', 'kk', 'km', 'kn', 'ko', 'lb',
      'lo', 'lt', 'lv', 'mk', 'ml', 'mn', 'mr', 'ms', 'mt',
      'nb', 'ne', 'nl', 'nn', 'oc', 'or', 'pa', 'pl', 'ps',
      'pt', 'ro', 'ru', 'si', 'sk', 'sl', 'sq', 'sr', 'sv',
      'sw', 'ta', 'te', 'th', 'tl', 'tr', 'uk', 'ur', 'uz',
      'vi', 'zh', 'zu',

      // Noms communs de démonstration
      'demo', 'test', 'sample', 'example', 'training', 'sandbox',
    ];

    final filtered = databases.where((db) {
      // Ignorer les noms vides
      if (db.trim().isEmpty) {
        print('❌ Base vide ignorée');
        return false;
      }

      // Vérifier contre les patterns de démonstration
      final dbLower = db.toLowerCase().trim();
      for (final pattern in demoPatterns) {
        if (dbLower == pattern.toLowerCase()) {
          print('❌ Base démo exclue: $db (pattern: $pattern)');
          return false; // Exclure cette base de données
        }
      }

      // Exclure les patterns de codes de langue (xx_XX ou xx_XXX)
      final languageCodePattern = RegExp(r'^[a-z]{2}_[A-Z]{2,3}$');
      if (languageCodePattern.hasMatch(db)) {
        print('❌ Code de langue exclu: $db');
        return false;
      }

      // Exclure les codes de langue courts (2-3 lettres)
      if (db.length <= 3 && RegExp(r'^[a-z]{2,3}$').hasMatch(dbLower)) {
        print('❌ Code de langue court exclu: $db');
        return false;
      }

      // Exclure les patterns spéciaux comme sr@latin, kab_DZ
      if (dbLower.contains('@') || dbLower.contains('_')) {
        final parts = dbLower.split(RegExp(r'[@_]'));
        if (parts.length == 2 && parts.every((part) => part.length <= 5)) {
          print('❌ Pattern de langue spécial exclu: $db');
          return false;
        }
      }

      // Vérifier si contient des mots-clés de démo
      final demoKeywords = ['demo', 'test', 'sample', 'training'];
      for (final keyword in demoKeywords) {
        if (dbLower.contains(keyword)) {
          print('❌ Base avec mot-clé démo exclue: $db');
          return false;
        }
      }

      print('✅ Base conservée: $db');
      return true; // Garder cette base de données
    }).toList();

    print('🎯 RÉSULTAT: ${filtered.length} bases conservées: $filtered');
    return filtered;
  }
}
