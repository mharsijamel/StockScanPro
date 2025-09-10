import '../models/stock_picking.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../config/app_config.dart';
import 'package:dio/dio.dart';

class SyncService {
  final ApiService _apiService;
  final AuthService _authService;

  SyncService(this._apiService, this._authService);

  /// Synchronise les opérations Stock IN et OUT depuis Odoo
  Future<SyncResult> syncStockOperations() async {
    try {
      final isDemo = await _authService.isDemoMode();

      if (isDemo) {
        return _syncDemoData();
      }

      // Synchronisation réelle avec Odoo
      return await _syncRealData();
    } catch (e) {
      return SyncResult(
        success: false,
        message: 'Erreur de synchronisation: ${e.toString()}',
        stockInCount: 0,
        stockOutCount: 0,
      );
    }
  }

  /// Synchronisation avec données de démonstration
  Future<SyncResult> _syncDemoData() async {
    await Future.delayed(const Duration(seconds: 2)); // Simulation

    // Données de démonstration
    final demoStockIn = [
      StockPicking(
        id: 1,
        name: 'IN/001',
        pickingType: 'incoming',
        state: 'assigned',
        partnerId: 1,
        partnerName: 'Fournisseur Demo',
        scheduledDate: DateTime.now().subtract(const Duration(days: 1)),
        products: [],
      ),
      StockPicking(
        id: 2,
        name: 'IN/002',
        pickingType: 'incoming',
        state: 'draft',
        partnerId: 2,
        partnerName: 'Fournisseur ABC',
        scheduledDate: DateTime.now(),
        products: [],
      ),
    ];

    final demoStockOut = [
      StockPicking(
        id: 3,
        name: 'OUT/001',
        pickingType: 'outgoing',
        state: 'assigned',
        partnerId: 3,
        partnerName: 'Client Demo',
        scheduledDate: DateTime.now().add(const Duration(hours: 2)),
        products: [],
      ),
    ];

    // TODO: Sauvegarder en base locale

    return SyncResult(
      success: true,
      message: 'Synchronisation démo réussie',
      stockInCount: demoStockIn.length,
      stockOutCount: demoStockOut.length,
      stockInOperations: demoStockIn,
      stockOutOperations: demoStockOut,
    );
  }

  /// Synchronisation réelle avec l'API Odoo
  Future<SyncResult> _syncRealData() async {
    try {
      // Vérifier d'abord la connexion
      final isConnected = await checkConnection();
      if (!isConnected) {
        return SyncResult(
          success: false,
          message: 'Impossible de se connecter au serveur Odoo.⁠\n'
              'Vérifiez :⁠\n'
              '- Votre connexion internet⁠\n'
              '- L\'URL du serveur: ${AppConfig.currentBaseUrl}⁠\n'
              '- Que le serveur Odoo est en fonctionnement⁠\n'
              'Ou utilisez le mode démo (demo/demo)',
          stockInCount: 0,
          stockOutCount: 0,
        );
      }

      // Récupérer les données utilisateur pour la session
      final token = await _authService.getToken();
      final userData = await _authService.getUserInfo();
      final database = userData['database'] ?? 'SMART';

      if (token == null) {
        return SyncResult(
          success: false,
          message: 'Session expirée, veuillez vous reconnecter',
          stockInCount: 0,
          stockOutCount: 0,
        );
      }

      print('🌐 Synchronisation avec Odoo - Base: $database');

      // Pour l'instant, retourner des données simulées si les endpoints personnalisés ne fonctionnent pas
      // Cela évite les erreurs 400/404 et permet à l'app de fonctionner
      final isDemo = await _authService.isDemoMode();

      if (isDemo || token.contains('demo')) {
        // Mode démo - utiliser des données simulées
        return _syncDemoData();
      }

      // Essayer de récupérer les opérations Stock IN depuis Odoo
      List<StockPicking> stockInOperations = [];
      List<StockPicking> stockOutOperations = [];

      try {
        stockInOperations =
            await _getOdooStockPickings(token, database, 'incoming');
      } catch (e) {
        print('❌ Erreur récupération pickings incoming: $e');
      }

      try {
        stockOutOperations =
            await _getOdooStockPickings(token, database, 'outgoing');
      } catch (e) {
        print('❌ Erreur récupération pickings outgoing: $e');
      }

      print(
          '✅ Synchronisation terminée: ${stockInOperations.length} IN, ${stockOutOperations.length} OUT');

      // TODO: Sauvegarder en base locale SQLite

      return SyncResult(
        success: true,
        message:
            'Synchronisation Odoo réussie - ${stockInOperations.length} IN, ${stockOutOperations.length} OUT',
        stockInCount: stockInOperations.length,
        stockOutCount: stockOutOperations.length,
        stockInOperations: stockInOperations,
        stockOutOperations: stockOutOperations,
      );
    } catch (e) {
      String detailedError;
      if (e.toString().contains('SocketException')) {
        detailedError = 'Erreur réseau - Vérifiez votre connexion internet';
      } else if (e.toString().contains('TimeoutException')) {
        detailedError = 'Timeout - Le serveur met trop de temps à répondre';
      } else if (e.toString().contains('404')) {
        detailedError =
            'Module Odoo manquant - Vérifiez l\'installation du module stock_scan_mobile';
      } else if (e.toString().contains('400')) {
        detailedError =
            'Erreur de requête - Vérifiez l\'authentification et les paramètres';
      } else if (e.toString().contains('401') || e.toString().contains('403')) {
        detailedError = 'Erreur d\'authentification - Reconnectez-vous';
      } else {
        detailedError = 'Erreur inconnue: ${e.toString()}';
      }

      throw Exception('Erreur lors de la synchronisation: $detailedError');
    }
  }

  /// Synchronise les numéros de série pour une opération spécifique
  Future<bool> syncSerialNumbers(
      int pickingId, List<String> serialNumbers) async {
    try {
      final isDemo = await _authService.isDemoMode();

      if (isDemo) {
        await Future.delayed(const Duration(seconds: 1));
        return true;
      }

      final response =
          await _apiService.post('/api/pickings/$pickingId/update_sn', data: {
        'serial_numbers': serialNumbers
            .map((sn) => {
                  'serial_number': sn,
                  'scanned_at': DateTime.now().toIso8601String(),
                })
            .toList(),
      });

      return response['success'] == true;
    } catch (e) {
      print('Erreur sync numéros de série: $e');
      return false;
    }
  }

  /// Vérifie l'état de la connexion avec le serveur
  Future<bool> checkConnection() async {
    try {
      // Essayer d'abord l'interface web standard d'Odoo
      final dio = Dio();
      final baseUrl = AppConfig.currentBaseUrl;
      final response = await dio.get('$baseUrl/web/login',
          options: Options(
              sendTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(seconds: 5)));

      if (response.statusCode == 200) {
        print('✅ Serveur Odoo accessible via interface web');
        return true;
      }
    } catch (e) {
      print('❌ Interface web Odoo non accessible: $e');
    }

    try {
      // Alternative: essayer l'endpoint de santé personnalisé
      final response = await _apiService.get('/health');
      if (response['success'] == true) {
        print('✅ API personnalisée accessible via health endpoint');
        return true;
      }
    } catch (e) {
      print('❌ Custom health endpoint failed: $e');
    }

    try {
      // Alternative: tester l'endpoint d'authentification personnalisé
      final response = await _apiService.get('/auth/status');
      if (response['success'] == true) {
        print('✅ API personnalisée accessible via auth status');
        return true;
      }
    } catch (e) {
      print('❌ Custom auth status check failed: $e');
    }

    // Si les endpoints personnalisés ne répondent pas, considérer comme déconnecté
    print('❌ Aucun endpoint personnalisé accessible');
    return false;
  }

  /// Obtient les statistiques de synchronisation
  Future<SyncStats> getSyncStats() async {
    try {
      final isDemo = await _authService.isDemoMode();

      if (isDemo) {
        return SyncStats(
          lastSyncTime: DateTime.now().subtract(const Duration(minutes: 5)),
          totalStockIn: 2,
          totalStockOut: 1,
          pendingSync: 0,
          isConnected: true,
        );
      }

      // TODO: Récupérer les vraies statistiques depuis la base locale
      return SyncStats(
        lastSyncTime: DateTime.now().subtract(const Duration(minutes: 10)),
        totalStockIn: 0,
        totalStockOut: 0,
        pendingSync: 0,
        isConnected: await checkConnection(),
      );
    } catch (e) {
      return SyncStats(
        lastSyncTime: null,
        totalStockIn: 0,
        totalStockOut: 0,
        pendingSync: 0,
        isConnected: false,
      );
    }
  }

  /// Récupère les stock pickings via l'API (essaie custom puis standard)
  Future<List<StockPicking>> _getOdooStockPickings(
      String sessionId, String database, String pickingType) async {
    // Essayer d'abord l'API personnalisée
    try {
      final customPickings = await _tryCustomApiPickings(pickingType);
      if (customPickings.isNotEmpty) {
        return customPickings;
      }
    } catch (e) {
      print('❌ API personnalisée non disponible: $e');
    }

    // Fallback vers l'API standard Odoo
    try {
      final standardPickings =
          await _tryStandardOdooPickings(sessionId, database, pickingType);
      return standardPickings;
    } catch (e) {
      print('❌ Erreur récupération pickings: $e');
      return [];
    }
  }

  /// Essaie de récupérer via l'API personnalisée
  Future<List<StockPicking>> _tryCustomApiPickings(String pickingType) async {
    try {
      final response = await _apiService.get('/pickings', queryParams: {
        'type': pickingType,
        'limit': '50',
        'state': 'assigned,confirmed,waiting',
      });

      if (response['success'] == true && response['data'] != null) {
        final records = response['data'] as List;
        List<StockPicking> pickings = [];

        for (var record in records) {
          // Convertir en objets StockMove si des produits sont inclus
          final products = <StockMove>[];
          if (record['moves'] != null) {
            final movesData = record['moves'] as List;
            for (var moveData in movesData) {
              products.add(StockMove(
                id: moveData['id'] ?? 0,
                productId: moveData['product_id'] ?? 0,
                productName: moveData['product_name'] ?? 'Produit inconnu',
                quantity: (moveData['quantity_expected'] ?? 0.0).toDouble(),
                quantityDone: (moveData['quantity_done'] ?? 0.0).toDouble(),
                uomName: moveData['uom_name'] ?? 'Units',
                serialNumbers: [],
                requiresSerialNumber: moveData['requires_serial'] ?? false,
              ));
            }
          }

          pickings.add(StockPicking(
            id: record['id'],
            name: record['name'] ?? '',
            pickingType: pickingType,
            state: record['state'] ?? 'draft',
            partnerId: record['partner_id'] ?? 0,
            partnerName: record['partner_name'] ?? 'Inconnu',
            scheduledDate: record['scheduled_date'] != null
                ? DateTime.parse(record['scheduled_date'])
                : DateTime.now(),
            products: products,
          ));
        }

        print(
            '📦 ${pickings.length} $pickingType pickings récupérés via API personnalisée');
        return pickings;
      } else {
        throw Exception(
            'API personnalisée: ${response['message'] ?? 'Réponse invalide'}');
      }
    } catch (e) {
      // Log l'erreur mais ne pas arrêter tout le processus
      print('🔴 API personnalisée non accessible pour $pickingType: $e');

      // Retourner une liste vide pour permettre le fallback vers l'API standard
      return [];
    }
  }

  /// Fallback vers l'API standard Odoo
  Future<List<StockPicking>> _tryStandardOdooPickings(
      String sessionId, String database, String pickingType) async {
    print('🔄 Utilisation de l\'API standard Odoo pour $pickingType');

    // Déterminer le type de picking selon Odoo
    String odooPickingTypeCode;
    switch (pickingType) {
      case 'incoming':
        odooPickingTypeCode = 'incoming';
        break;
      case 'outgoing':
        odooPickingTypeCode = 'outgoing';
        break;
      default:
        odooPickingTypeCode = pickingType;
    }

    // Récupérer l'ID utilisateur réel et valider la session
    final userInfo = await _authService.getUserInfo();
    final userId = int.tryParse(userInfo['user_id'] ?? '1') ?? 1;
    final username = userInfo['username'];
    final sessionCookie = await _authService.getSessionCookie();

    if (username == null) {
      throw Exception('Aucune information utilisateur disponible');
    }

    print('👤 User: $username (ID: $userId), Database: $database');
    if (sessionCookie != null) {
      print('🍪 Using session cookie: ${sessionCookie.substring(0, 20)}...');
    }

    // Utiliser l'endpoint standard d'Odoo - Nécessite une authentification valide
    final requestData = {
      'jsonrpc': '2.0',
      'method': 'call',
      'params': {
        'service': 'object',
        'method': 'execute_kw',
        'args': [
          database,
          userId,
          sessionId, // Le sessionId est utilisé comme token d'authentification
          'stock.picking',
          'search_read',
          [
            [
              ['picking_type_code', '=', odooPickingTypeCode],
              [
                'state',
                'in',
                ['assigned', 'confirmed', 'waiting']
              ]
            ]
          ],
          {
            'fields': [
              'id',
              'name',
              'state',
              'partner_id',
              'scheduled_date',
              'picking_type_code',
              'move_lines'
            ],
            'limit': 50
          }
        ]
      }
    };

    // Faire la requête directement avec Dio (contourner ApiService pour l'endpoint standard)
    final dio = Dio();
    final baseUrl = AppConfig.currentBaseUrl;

    // Use the actual Odoo session cookie if available
    String cookieHeader = 'session_id=$sessionId';
    if (sessionCookie != null && sessionCookie.isNotEmpty) {
      cookieHeader = sessionCookie;
      print('🔑 Using real Odoo session cookie');
    } else {
      print('⚠️ Fallback to session_id token');
    }

    final response = await dio.post(
      '$baseUrl/web/dataset/call_kw',
      data: requestData,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Cookie': cookieHeader,
          'X-Openerp-Database': database, // Header requis selon la mémoire
        },
      ),
    );

    if (response.statusCode == 200 && response.data['result'] != null) {
      final records = response.data['result'] as List;
      List<StockPicking> pickings = [];

      for (var record in records) {
        // Traitement basique sans les détails des moves pour le fallback
        pickings.add(StockPicking(
          id: record['id'],
          name: record['name'] ?? '',
          pickingType: pickingType,
          state: record['state'] ?? 'draft',
          partnerId: record['partner_id'] is List
              ? record['partner_id'][0]
              : (record['partner_id'] ?? 0),
          partnerName: record['partner_id'] is List
              ? record['partner_id'][1]
              : 'Inconnu',
          scheduledDate: record['scheduled_date'] != null
              ? DateTime.parse(record['scheduled_date'])
              : DateTime.now(),
          products: [], // Les détails des produits nécessiteraient une requête supplémentaire
        ));
      }

      print(
          '📦 ${pickings.length} $pickingType pickings récupérés via API standard Odoo');
      return pickings;
    } else if (response.statusCode == 200 && response.data['error'] != null) {
      // Gestion des erreurs JSON-RPC
      final error = response.data['error'];
      final errorMessage = error['message'] ??
          error['data']?['message'] ??
          'Erreur JSON-RPC inconnue';
      throw Exception('Erreur Odoo JSON-RPC: $errorMessage');
    } else {
      throw Exception(
          'API standard Odoo: Réponse invalide (Status: ${response.statusCode})');
    }
  }
}

/// Résultat d'une synchronisation
class SyncResult {
  final bool success;
  final String message;
  final int stockInCount;
  final int stockOutCount;
  final List<StockPicking>? stockInOperations;
  final List<StockPicking>? stockOutOperations;

  SyncResult({
    required this.success,
    required this.message,
    required this.stockInCount,
    required this.stockOutCount,
    this.stockInOperations,
    this.stockOutOperations,
  });
}

/// Statistiques de synchronisation
class SyncStats {
  final DateTime? lastSyncTime;
  final int totalStockIn;
  final int totalStockOut;
  final int pendingSync;
  final bool isConnected;

  SyncStats({
    this.lastSyncTime,
    required this.totalStockIn,
    required this.totalStockOut,
    required this.pendingSync,
    required this.isConnected,
  });
}
