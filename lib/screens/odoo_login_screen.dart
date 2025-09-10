import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../services/database_selection_service.dart';
import '../config/app_config.dart';
import '../constants/app_constants.dart';
import 'database_selection_screen.dart';

class OdooLoginScreen extends StatefulWidget {
  const OdooLoginScreen({super.key});

  @override
  State<OdooLoginScreen> createState() => _OdooLoginScreenState();
}

class _OdooLoginScreenState extends State<OdooLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final DatabaseSelectionService _dbService = DatabaseSelectionService();
  
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _selectedDatabase;
  List<String> _availableDatabases = [];

  @override
  void initState() {
    super.initState();
    _loadDatabases();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadDatabases() async {
    try {
      final serverUrl = AppConfig.currentBaseUrl;
      print('🔍 Chargement des bases depuis: $serverUrl');

      final databases = await _dbService.getDatabaseList(serverUrl);
      print('📋 Bases récupérées: $databases');

      setState(() {
        _availableDatabases = databases;
        if (databases.isNotEmpty) {
          _selectedDatabase = databases.first;
          print('✅ Base sélectionnée: $_selectedDatabase');
        }
      });
    } catch (e) {
      print('❌ Erreur chargement bases: $e');
      setState(() {
        _availableDatabases = ['SMART']; // Fallback
        _selectedDatabase = 'SMART';
      });
    }
  }

  Future<void> _selectDatabase() async {
    if (_availableDatabases.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucune base de données disponible')),
      );
      return;
    }

    final String? selectedDb = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sélectionner une base de données'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ..._availableDatabases.map((db) {
                return ListTile(
                  title: Text(db),
                  leading: Radio<String>(
                    value: db,
                    groupValue: _selectedDatabase,
                    onChanged: (String? value) {
                      Navigator.of(context).pop(value);
                    },
                  ),
                  onTap: () {
                    Navigator.of(context).pop(db);
                  },
                );
              }).toList(),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.visibility),
                title: const Text('Voir toutes les bases'),
                subtitle: const Text('Inclure les bases de test'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _showAllDatabases();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
          ],
        );
      },
    );

    if (selectedDb != null && selectedDb != _selectedDatabase) {
      setState(() {
        _selectedDatabase = selectedDb;
      });

      // Afficher une notification de confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Base de données "$selectedDb" sélectionnée'),
          backgroundColor: Colors.green,
        ),
      );

      print('✅ Base changée vers: $selectedDb');
    }
  }

  Future<void> _showAllDatabases() async {
    try {
      final serverUrl = AppConfig.currentBaseUrl;
      print('🔍 Chargement de TOUTES les bases depuis: $serverUrl');

      final allDatabases = await _dbService.getAllDatabaseList(serverUrl);
      print('📋 Toutes les bases récupérées: $allDatabases');

      if (allDatabases.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucune base de données trouvée')),
        );
        return;
      }

      final String? selectedDb = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Toutes les bases de données'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: allDatabases.map((db) {
                final isTestDb = db.toLowerCase().contains('test') ||
                                db.toLowerCase().contains('demo');
                return ListTile(
                  title: Text(db),
                  subtitle: isTestDb ? const Text('Base de test',
                    style: TextStyle(color: Colors.orange)) : null,
                  leading: Radio<String>(
                    value: db,
                    groupValue: _selectedDatabase,
                    onChanged: (String? value) {
                      Navigator.of(context).pop(value);
                    },
                  ),
                  onTap: () {
                    Navigator.of(context).pop(db);
                  },
                );
              }).toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annuler'),
              ),
            ],
          );
        },
      );

      if (selectedDb != null && selectedDb != _selectedDatabase) {
        setState(() {
          _selectedDatabase = selectedDb;
          // Ajouter la base sélectionnée à la liste si elle n'y est pas
          if (!_availableDatabases.contains(selectedDb)) {
            _availableDatabases.add(selectedDb);
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Base de données "$selectedDb" sélectionnée'),
            backgroundColor: Colors.green,
          ),
        );

        print('✅ Base changée vers: $selectedDb');
      }
    } catch (e) {
      print('❌ Erreur chargement toutes les bases: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate() || _selectedDatabase == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une base de données'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      final result = await authProvider.loginWithDatabase(
        _usernameController.text.trim(),
        _passwordController.text,
        _selectedDatabase!,
      );

      if (result['success'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Connexion réussie'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/dashboard');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Erreur de connexion'),
            backgroundColor: Colors.red,
          ),
        );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connexion Odoo'),
        backgroundColor: Color(AppConstants.primaryColorValue),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo et titre
              const Icon(
                Icons.account_circle,
                size: 80,
                color: Color(AppConstants.primaryColorValue),
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              Text(
                'StockScan Pro',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Color(AppConstants.primaryColorValue),
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.defaultPadding * 2),

              // Sélection de base de données
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.storage, color: Color(AppConstants.primaryColorValue)),
                          const SizedBox(width: 8),
                          const Text(
                            'Base de données',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_selectedDatabase != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey.shade50,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _selectedDatabase!,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: _selectDatabase,
                                child: const Text('Changer'),
                              ),
                            ],
                          ),
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: _selectDatabase,
                          icon: const Icon(Icons.add),
                          label: const Text('Sélectionner une base'),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.defaultPadding),

              // Champs de connexion
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Nom d\'utilisateur',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez saisir votre nom d\'utilisateur';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppConstants.defaultPadding),

              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez saisir votre mot de passe';
                  }
                  return null;
                },
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _handleLogin(),
              ),
              const SizedBox(height: AppConstants.defaultPadding * 2),

              // Bouton de connexion
              ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(AppConstants.primaryColorValue),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Se connecter',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
              const SizedBox(height: AppConstants.defaultPadding),

              // Bouton mode démo
              TextButton(
                onPressed: _isLoading ? null : () async {
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  final success = await authProvider.login('demo', 'demo');
                  if (success && mounted) {
                    context.go('/dashboard');
                  }
                },
                child: const Text('Mode Démo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
