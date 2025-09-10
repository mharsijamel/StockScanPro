import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../config/app_config.dart';
import 'package:dio/dio.dart';

class OdooDiagnosticScreen extends StatefulWidget {
  const OdooDiagnosticScreen({super.key});

  @override
  State<OdooDiagnosticScreen> createState() => _OdooDiagnosticScreenState();
}

class _OdooDiagnosticScreenState extends State<OdooDiagnosticScreen> {
  List<DiagnosticResult> _diagnosticResults = [];
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _runDiagnostic();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnostic Odoo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isRunning ? null : _runDiagnostic,
          ),
        ],
      ),
      body: _isRunning
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Diagnostic en cours...'),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _diagnosticResults.length,
              itemBuilder: (context, index) {
                final result = _diagnosticResults[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ExpansionTile(
                    leading: Icon(
                      result.success ? Icons.check_circle : Icons.error,
                      color: result.success ? Colors.green : Colors.red,
                    ),
                    title: Text(result.title),
                    subtitle: Text(
                      result.success ? 'Succès' : 'Échec',
                      style: TextStyle(
                        color: result.success ? Colors.green : Colors.red,
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Détails:',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(result.message),
                            if (result.additionalInfo != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Informations supplémentaires:',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                result.additionalInfo!,
                                style: const TextStyle(fontFamily: 'monospace'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Future<void> _runDiagnostic() async {
    setState(() {
      _isRunning = true;
      _diagnosticResults.clear();
    });

    final authService = context.read<AuthService>();
    final apiService = context.read<ApiService>();

    // Test 1: Basic server connectivity
    await _testBasicConnectivity();

    // Test 2: Authentication status
    await _testAuthentication(authService);

    // Test 3: Standard Odoo endpoints
    await _testStandardOdooEndpoints();

    // Test 4: Custom API endpoints
    await _testCustomApiEndpoints(apiService);

    // Test 5: Module verification
    await _testModuleInstallation();

    // Test 6: Available endpoints discovery
    await _discoverAvailableEndpoints();

    setState(() {
      _isRunning = false;
    });
  }

  Future<void> _testBasicConnectivity() async {
    try {
      final dio = Dio();
      final baseUrl = AppConfig.currentBaseUrl;

      // Test web interface
      final response = await dio.get('$baseUrl/web/login');

      if (response.statusCode == 200) {
        _addResult(DiagnosticResult(
          title: 'Connectivité serveur',
          success: true,
          message: 'Le serveur Odoo est accessible via l\'interface web',
          additionalInfo: 'URL: $baseUrl\nStatus: ${response.statusCode}',
        ));
      } else {
        _addResult(DiagnosticResult(
          title: 'Connectivité serveur',
          success: false,
          message: 'Le serveur répond mais avec un code inattendu',
          additionalInfo: 'Status: ${response.statusCode}',
        ));
      }
    } catch (e) {
      _addResult(DiagnosticResult(
        title: 'Connectivité serveur',
        success: false,
        message: 'Impossible d\'accéder au serveur Odoo',
        additionalInfo: 'Erreur: $e',
      ));
    }
  }

  Future<void> _testAuthentication(AuthService authService) async {
    try {
      final isAuthenticated = await authService.isAuthenticated();
      final userInfo = await authService.getUserInfo();

      if (isAuthenticated) {
        _addResult(DiagnosticResult(
          title: 'Authentification',
          success: true,
          message: 'Utilisateur authentifié avec succès',
          additionalInfo:
              'Utilisateur: ${userInfo['username']}\nBase: ${userInfo['database'] ?? 'Non définie'}',
        ));
      } else {
        _addResult(DiagnosticResult(
          title: 'Authentification',
          success: false,
          message: 'Aucune session active',
          additionalInfo: 'Veuillez vous connecter',
        ));
      }
    } catch (e) {
      _addResult(DiagnosticResult(
        title: 'Authentification',
        success: false,
        message: 'Erreur lors de la vérification de l\'authentification',
        additionalInfo: 'Erreur: $e',
      ));
    }
  }

  Future<void> _testStandardOdooEndpoints() async {
    final dio = Dio();
    final baseUrl = AppConfig.currentBaseUrl;

    final endpoints = [
      '/web/session/get_session_info',
      '/web/dataset/search_read',
      '/web/session/authenticate',
    ];

    for (final endpoint in endpoints) {
      try {
        final response = await dio.get('$baseUrl$endpoint');

        _addResult(DiagnosticResult(
          title: 'Endpoint Standard: $endpoint',
          success: response.statusCode == 200,
          message: response.statusCode == 200
              ? 'Endpoint accessible'
              : 'Endpoint retourne ${response.statusCode}',
          additionalInfo: 'URL: $baseUrl$endpoint',
        ));
      } catch (e) {
        String errorMsg = 'Non accessible';
        if (e is DioException && e.response?.statusCode == 405) {
          errorMsg =
              'Méthode non autorisée (endpoint existe mais GET non supporté)';
        }

        _addResult(DiagnosticResult(
          title: 'Endpoint Standard: $endpoint',
          success: false,
          message: errorMsg,
          additionalInfo: 'Erreur: $e',
        ));
      }
    }
  }

  Future<void> _testCustomApiEndpoints(ApiService apiService) async {
    final endpoints = [
      '/health',
      '/api/health',
      '/pickings',
      '/api/pickings',
      '/auth/status',
      '/api/auth/status',
    ];

    for (final endpoint in endpoints) {
      try {
        final response = await apiService.get(endpoint);

        _addResult(DiagnosticResult(
          title: 'API Personnalisée: $endpoint',
          success: response['success'] == true,
          message: response['success'] == true
              ? 'Endpoint accessible'
              : 'Endpoint retourne une erreur',
          additionalInfo: 'Réponse: ${response.toString()}',
        ));
      } catch (e) {
        _addResult(DiagnosticResult(
          title: 'API Personnalisée: $endpoint',
          success: false,
          message: 'Endpoint non accessible',
          additionalInfo: 'Erreur: $e',
        ));
      }
    }
  }

  Future<void> _testModuleInstallation() async {
    try {
      final dio = Dio();
      final baseUrl = AppConfig.currentBaseUrl;

      // Try to check module list (requires authentication)
      final response = await dio.post('$baseUrl/web/dataset/call_kw', data: {
        'jsonrpc': '2.0',
        'method': 'call',
        'params': {
          'service': 'object',
          'method': 'execute_kw',
          'args': [
            'SMART', // database
            1, // user_id
            'password', // password (dummy)
            'ir.module.module',
            'search_read',
            [
              [
                ['name', '=', 'stock_scan_mobile']
              ]
            ],
            {
              'fields': ['name', 'state', 'installed_version']
            }
          ]
        }
      });

      if (response.statusCode == 200 && response.data['result'] != null) {
        final modules = response.data['result'] as List;
        if (modules.isNotEmpty) {
          final module = modules.first;
          _addResult(DiagnosticResult(
            title: 'Module stock_scan_mobile',
            success: module['state'] == 'installed',
            message: module['state'] == 'installed'
                ? 'Module installé et actif'
                : 'Module trouvé mais non installé (état: ${module['state']})',
            additionalInfo: 'Détails: ${module.toString()}',
          ));
        } else {
          _addResult(DiagnosticResult(
            title: 'Module stock_scan_mobile',
            success: false,
            message: 'Module non trouvé dans la liste des modules',
            additionalInfo:
                'Le module stock_scan_mobile n\'est pas présent sur le serveur',
          ));
        }
      } else {
        _addResult(DiagnosticResult(
          title: 'Module stock_scan_mobile',
          success: false,
          message: 'Impossible de vérifier l\'installation du module',
          additionalInfo: 'Erreur d\'accès à la liste des modules',
        ));
      }
    } catch (e) {
      _addResult(DiagnosticResult(
        title: 'Module stock_scan_mobile',
        success: false,
        message: 'Erreur lors de la vérification du module',
        additionalInfo: 'Erreur: $e',
      ));
    }
  }

  Future<void> _discoverAvailableEndpoints() async {
    final dio = Dio();
    final baseUrl = AppConfig.currentBaseUrl;

    // Test various possible API endpoints
    final possibleEndpoints = [
      '/api',
      '/api/v1',
      '/api/v2',
      '/rest',
      '/rest/v1',
      '/mobile',
      '/mobile/api',
      '/stock_scan',
      '/stock_scan/api',
    ];

    List<String> foundEndpoints = [];

    for (final endpoint in possibleEndpoints) {
      try {
        final response = await dio.get('$baseUrl$endpoint');
        if (response.statusCode == 200) {
          foundEndpoints.add(endpoint);
        }
      } catch (e) {
        // Ignore errors, we're just discovering
      }
    }

    _addResult(DiagnosticResult(
      title: 'Découverte d\'endpoints',
      success: foundEndpoints.isNotEmpty,
      message: foundEndpoints.isNotEmpty
          ? 'Endpoints disponibles trouvés'
          : 'Aucun endpoint d\'API personnalisée trouvé',
      additionalInfo: foundEndpoints.isNotEmpty
          ? 'Endpoints trouvés:\n${foundEndpoints.join('\n')}'
          : 'Aucun des endpoints testés n\'est accessible',
    ));
  }

  void _addResult(DiagnosticResult result) {
    setState(() {
      _diagnosticResults.add(result);
    });
  }
}

class DiagnosticResult {
  final String title;
  final bool success;
  final String message;
  final String? additionalInfo;

  DiagnosticResult({
    required this.title,
    required this.success,
    required this.message,
    this.additionalInfo,
  });
}
