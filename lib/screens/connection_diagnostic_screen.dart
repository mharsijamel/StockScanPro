import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../config/app_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ConnectionDiagnosticScreen extends StatefulWidget {
  const ConnectionDiagnosticScreen({super.key});

  @override
  State<ConnectionDiagnosticScreen> createState() =>
      _ConnectionDiagnosticScreenState();
}

class _ConnectionDiagnosticScreenState
    extends State<ConnectionDiagnosticScreen> {
  bool _isRunning = false;
  List<DiagnosticResult> _results = [];
  String _serverUrl = '';

  @override
  void initState() {
    super.initState();
    _serverUrl = AppConfig.currentBaseUrl;
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _isRunning = true;
      _results.clear();
    });

    await _checkServerConnectivity();
    await _checkOdooWebInterface();
    await _checkHealthEndpoint();
    await _checkCustomModuleEndpoints();
    await _testAuthentication();

    setState(() {
      _isRunning = false;
    });
  }

  Future<void> _checkServerConnectivity() async {
    setState(() {
      _results.add(DiagnosticResult(
        title: 'Connectivité serveur',
        status: DiagnosticStatus.running,
        message: 'Test en cours...',
      ));
    });

    try {
      final response = await http.get(
        Uri.parse(_serverUrl),
        headers: {'User-Agent': 'StockScanPro Diagnostic'},
      ).timeout(const Duration(seconds: 10));

      setState(() {
        _results[_results.length - 1] = DiagnosticResult(
          title: 'Connectivité serveur',
          status: response.statusCode == 200
              ? DiagnosticStatus.success
              : DiagnosticStatus.warning,
          message: response.statusCode == 200
              ? 'Serveur accessible (HTTP ${response.statusCode})'
              : 'Serveur répond avec HTTP ${response.statusCode}',
          details: 'URL testée: $_serverUrl',
        );
      });
    } catch (e) {
      setState(() {
        _results[_results.length - 1] = DiagnosticResult(
          title: 'Connectivité serveur',
          status: DiagnosticStatus.error,
          message: 'Serveur inaccessible',
          details: e.toString(),
          solution: 'Vérifiez votre connexion internet et l\'URL du serveur',
        );
      });
    }
  }

  Future<void> _checkOdooWebInterface() async {
    setState(() {
      _results.add(DiagnosticResult(
        title: 'Interface web Odoo',
        status: DiagnosticStatus.running,
        message: 'Test en cours...',
      ));
    });

    try {
      final response = await http.get(
        Uri.parse('$_serverUrl/web/login'),
        headers: {'User-Agent': 'StockScanPro Diagnostic'},
      ).timeout(const Duration(seconds: 10));

      final isOdoo =
          response.statusCode == 200 && response.body.contains('odoo');

      setState(() {
        _results[_results.length - 1] = DiagnosticResult(
          title: 'Interface web Odoo',
          status: isOdoo ? DiagnosticStatus.success : DiagnosticStatus.error,
          message: isOdoo
              ? 'Interface Odoo détectée'
              : 'Interface Odoo non détectée',
          details: 'Code de statut: ${response.statusCode}',
          solution:
              isOdoo ? null : 'Vérifiez que l\'URL pointe vers un serveur Odoo',
        );
      });
    } catch (e) {
      setState(() {
        _results[_results.length - 1] = DiagnosticResult(
          title: 'Interface web Odoo',
          status: DiagnosticStatus.error,
          message: 'Impossible d\'accéder à l\'interface web',
          details: e.toString(),
        );
      });
    }
  }

  Future<void> _checkHealthEndpoint() async {
    setState(() {
      _results.add(DiagnosticResult(
        title: 'Endpoint de santé',
        status: DiagnosticStatus.running,
        message: 'Test en cours...',
      ));
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final response = await apiService.get('/health');

      setState(() {
        _results[_results.length - 1] = DiagnosticResult(
          title: 'Endpoint de santé',
          status: response['success'] == true
              ? DiagnosticStatus.success
              : DiagnosticStatus.warning,
          message: response['success'] == true
              ? 'Endpoint fonctionnel'
              : 'Endpoint non fonctionnel',
          details: 'Réponse: ${response.toString()}',
        );
      });
    } catch (e) {
      setState(() {
        _results[_results.length - 1] = DiagnosticResult(
          title: 'Endpoint de santé',
          status: DiagnosticStatus.error,
          message: 'Endpoint non disponible',
          details: e.toString(),
          solution: 'Le module stock_scan_mobile n\'est peut-être pas installé',
        );
      });
    }
  }

  Future<void> _checkCustomModuleEndpoints() async {
    setState(() {
      _results.add(DiagnosticResult(
        title: 'Endpoints du module personnalisé',
        status: DiagnosticStatus.running,
        message: 'Test en cours...',
      ));
    });

    final endpoints = ['/api/auth/login', '/api/pickings', '/api/serial/check'];
    int successCount = 0;

    for (final endpoint in endpoints) {
      try {
        final response = await http.get(
          Uri.parse('$_serverUrl$endpoint'),
          headers: {
            'Content-Type': 'application/json',
            'User-Agent': 'StockScanPro Diagnostic',
          },
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode != 404) {
          successCount++;
        }
      } catch (e) {
        // Ignore errors for individual endpoints
      }
    }

    setState(() {
      _results[_results.length - 1] = DiagnosticResult(
        title: 'Endpoints du module personnalisé',
        status: successCount > 0
            ? DiagnosticStatus.success
            : DiagnosticStatus.error,
        message: '$successCount/${endpoints.length} endpoints disponibles',
        details: 'Endpoints testés: ${endpoints.join(', ')}',
        solution: successCount == 0
            ? 'Installez le module stock_scan_mobile dans Odoo'
            : null,
      );
    });
  }

  Future<void> _testAuthentication() async {
    setState(() {
      _results.add(DiagnosticResult(
        title: 'Test d\'authentification',
        status: DiagnosticStatus.running,
        message: 'Test en cours...',
      ));
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final result =
          await authService.loginWithDatabase('demo', 'demo', 'demo');

      setState(() {
        _results[_results.length - 1] = DiagnosticResult(
          title: 'Test d\'authentification',
          status: result['success'] == true
              ? DiagnosticStatus.success
              : DiagnosticStatus.warning,
          message: result['success'] == true
              ? 'Authentification démo réussie'
              : 'Authentification échouée',
          details: result['message'] ?? '',
          solution: result['success'] != true
              ? 'Utilisez le mode démo ou vérifiez vos identifiants'
              : null,
        );
      });
    } catch (e) {
      setState(() {
        _results[_results.length - 1] = DiagnosticResult(
          title: 'Test d\'authentification',
          status: DiagnosticStatus.error,
          message: 'Erreur d\'authentification',
          details: e.toString(),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnostic de connexion'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Configuration actuelle',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text('Serveur: $_serverUrl'),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isRunning ? null : _runDiagnostics,
                        icon: _isRunning
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.play_arrow),
                        label: Text(_isRunning
                            ? 'Diagnostic en cours...'
                            : 'Lancer le diagnostic'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_results.isNotEmpty) ...[
              Text(
                'Résultats du diagnostic',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
            ],
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final result = _results[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: _getStatusIcon(result.status),
                      title: Text(result.title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(result.message),
                          if (result.details != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              result.details!,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ],
                          if (result.solution != null) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(4),
                                border:
                                    Border.all(color: Colors.orange.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.lightbulb,
                                      size: 16, color: Colors.orange.shade700),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      result.solution!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getStatusIcon(DiagnosticStatus status) {
    switch (status) {
      case DiagnosticStatus.success:
        return const Icon(Icons.check_circle, color: Colors.green);
      case DiagnosticStatus.warning:
        return const Icon(Icons.warning, color: Colors.orange);
      case DiagnosticStatus.error:
        return const Icon(Icons.error, color: Colors.red);
      case DiagnosticStatus.running:
        return const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
    }
  }
}

enum DiagnosticStatus { success, warning, error, running }

class DiagnosticResult {
  final String title;
  final DiagnosticStatus status;
  final String message;
  final String? details;
  final String? solution;

  DiagnosticResult({
    required this.title,
    required this.status,
    required this.message,
    this.details,
    this.solution,
  });
}
