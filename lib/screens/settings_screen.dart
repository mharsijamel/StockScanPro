import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../providers/auth_provider.dart';
import '../constants/app_constants.dart';
import '../services/database_selection_service.dart';
import 'database_selection_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final DatabaseSelectionService _dbService = DatabaseSelectionService();
  bool _isLoading = false;
  bool _hasMultipleDatabases = false;
  String? _selectedDatabase;

  @override
  void initState() {
    super.initState();
    _urlController.text = AppConfig.currentBaseUrl;
    _selectedDatabase = AppConfig.selectedDatabase;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _saveConfiguration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newUrl = _urlController.text.trim();

      // Valider l'URL
      if (!AppConfig.isValidUrl(newUrl)) {
        throw Exception('URL invalide');
      }

      // Sauvegarder la nouvelle URL
      AppConfig.setManualBaseUrl(newUrl);

      // Vérifier s'il y a plusieurs bases de données
      final hasSingle = await _dbService.hasSingleDatabase(newUrl);

      if (!hasSingle) {
        // Plusieurs bases de données - ouvrir l'écran de sélection
        if (mounted) {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (context) => DatabaseSelectionScreen(
                serverUrl: newUrl,
                onDatabaseSelected: () {
                  setState(() {
                    _selectedDatabase = AppConfig.selectedDatabase;
                  });
                },
              ),
            ),
          );

          if (result != true) {
            // L'utilisateur a annulé la sélection
            setState(() {
              _isLoading = false;
            });
            return;
          }
        }
      } else {
        // Une seule base de données - utiliser la base par défaut
        final defaultDb = await _dbService.getDefaultDatabase(newUrl);
        if (defaultDb != null) {
          AppConfig.setSelectedDatabase(defaultDb);
          _selectedDatabase = defaultDb;
        }
      }

      // Tester la connexion
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.testConnection();

      if (mounted) {
        final dbInfo = _selectedDatabase != null ? ' (DB: $_selectedDatabase)' : '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Configuration sauvegardée avec succès$dbInfo'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final testUrl = _urlController.text.trim();

      // Test de connexion basique
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Temporairement changer l'URL pour le test
      final originalUrl = AppConfig.currentBaseUrl;
      AppConfig.setBaseUrl(testUrl);

      final isConnected = await authProvider.testConnection();

      // Restaurer l'URL originale si le test échoue
      if (!isConnected) {
        AppConfig.setBaseUrl(originalUrl);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isConnected
                ? '✅ Connexion réussie au serveur Odoo'
                : '❌ Impossible de se connecter au serveur'
            ),
            backgroundColor: isConnected ? Colors.green : Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de test: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration Serveur'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'URL du serveur Odoo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppConstants.smallPadding),
              const Text(
                'Saisissez l\'URL complète de votre serveur Odoo (ex: https://your-company.odoo.com)',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              
              // Champ URL
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'URL du serveur',
                  hintText: 'https://your-company.odoo.com',
                  prefixIcon: Icon(Icons.link),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.url,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez saisir une URL';
                  }
                  if (!AppConfig.isValidUrl(value.trim())) {
                    return 'URL invalide (doit commencer par http:// ou https://)';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: AppConstants.defaultPadding),

              // Bouton de test de connexion
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _testConnection,
                      icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.wifi_find),
                      label: Text(_isLoading ? 'Test en cours...' : 'Tester la connexion'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.defaultPadding),

              // Base de données sélectionnée
              if (_selectedDatabase != null) ...[
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    child: Row(
                      children: [
                        const Icon(Icons.storage, color: Colors.blue),
                        const SizedBox(width: AppConstants.smallPadding),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Base de données sélectionnée:',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Text(
                                _selectedDatabase!,
                                style: const TextStyle(color: Colors.blue),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            if (_urlController.text.trim().isNotEmpty) {
                              final result = await Navigator.of(context).push<bool>(
                                MaterialPageRoute(
                                  builder: (context) => DatabaseSelectionScreen(
                                    serverUrl: _urlController.text.trim(),
                                    onDatabaseSelected: () {
                                      setState(() {
                                        _selectedDatabase = AppConfig.selectedDatabase;
                                      });
                                    },
                                  ),
                                ),
                              );
                            }
                          },
                          child: const Text('Changer'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.defaultPadding),
              ],

              // URLs communes
              const Text(
                'URLs communes:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: AppConstants.smallPadding),
              
              ...AppConfig.commonOdooUrls.map((url) => ListTile(
                dense: true,
                leading: const Icon(Icons.link, size: 16),
                title: Text(url, style: const TextStyle(fontSize: 14)),
                onTap: () {
                  _urlController.text = url;
                },
              )),
              
              const Spacer(),
              
              // Boutons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () {
                        AppConfig.clearConfiguration();
                        _urlController.text = AppConfig.currentBaseUrl;
                        setState(() {
                          _selectedDatabase = null;
                        });
                      },
                      child: const Text('Réinitialiser'),
                    ),
                  ),
                  const SizedBox(width: AppConstants.defaultPadding),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveConfiguration,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Sauvegarder'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
