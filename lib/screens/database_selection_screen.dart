import 'package:flutter/material.dart';
import '../services/database_selection_service.dart';
import '../config/app_config.dart';
import '../constants/app_constants.dart';

class DatabaseSelectionScreen extends StatefulWidget {
  final String serverUrl;
  final VoidCallback? onDatabaseSelected;

  const DatabaseSelectionScreen({
    super.key,
    required this.serverUrl,
    this.onDatabaseSelected,
  });

  @override
  State<DatabaseSelectionScreen> createState() => _DatabaseSelectionScreenState();
}

class _DatabaseSelectionScreenState extends State<DatabaseSelectionScreen> {
  final DatabaseSelectionService _dbService = DatabaseSelectionService();
  List<String> _databases = [];
  List<String> _allDatabases = []; // Toutes les bases de données (y compris démo)
  bool _isLoading = true;
  String? _error;
  String? _selectedDatabase;
  bool _showAllDatabases = false; // Option pour afficher toutes les bases

  @override
  void initState() {
    super.initState();
    _loadDatabases();
  }

  Future<void> _loadDatabases() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('🌐 Chargement des bases depuis: ${widget.serverUrl}');

      // Charger les bases de données filtrées ET toutes les bases
      final databases = await _dbService.getDatabaseList(widget.serverUrl);
      final allDatabases = await _dbService.getAllDatabaseList(widget.serverUrl);

      print('📋 Toutes les bases: ${allDatabases.length} - $allDatabases');
      print('🎯 Bases filtrées: ${databases.length} - $databases');

      if (databases.isEmpty && allDatabases.isEmpty) {
        setState(() {
          _error = 'Aucune base de données trouvée sur ce serveur';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _allDatabases = allDatabases;
        _databases = databases;
        _selectedDatabase = databases.isNotEmpty ? databases.first : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur lors de la récupération des bases de données: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _toggleShowAllDatabases() {
    setState(() {
      _showAllDatabases = !_showAllDatabases;
      _selectedDatabase = null; // Reset selection when switching
    });
  }

  List<String> get _displayedDatabases {
    return _showAllDatabases ? _allDatabases : _databases;
  }

  Future<void> _selectDatabase() async {
    if (_selectedDatabase == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Tester la connexion à la base de données
      final isAccessible = await _dbService.testDatabaseConnection(
        widget.serverUrl,
        _selectedDatabase!,
      );

      if (!isAccessible) {
        throw Exception('Base de données non accessible');
      }

      // Sauvegarder la sélection
      AppConfig.setSelectedDatabase(_selectedDatabase!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Base de données "$_selectedDatabase" sélectionnée'),
            backgroundColor: Colors.green,
          ),
        );

        // Callback pour notifier la sélection
        widget.onDatabaseSelected?.call();
        
        // Retourner à l'écran précédent
        Navigator.of(context).pop(true);
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
        title: const Text('Sélection Base de Données'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Information sur le serveur
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Serveur Odoo',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppConstants.smallPadding),
                    Text(
                      widget.serverUrl,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: AppConstants.defaultPadding),
            
            // Contenu principal
            Expanded(
              child: _buildContent(),
            ),
            
            // Boutons
            if (!_isLoading && _databases.isNotEmpty) ...[
              const SizedBox(height: AppConstants.defaultPadding),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: AppConstants.defaultPadding),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _selectedDatabase != null ? _selectDatabase : null,
                      child: const Text('Sélectionner'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: AppConstants.defaultPadding),
            Text('Récupération des bases de données...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            ElevatedButton(
              onPressed: _loadDatabases,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_databases.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.storage_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: AppConstants.defaultPadding),
            Text(
              'Aucune base de données trouvée',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Bases de données disponibles:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_allDatabases.length > _databases.length)
              TextButton.icon(
                onPressed: _toggleShowAllDatabases,
                icon: Icon(_showAllDatabases ? Icons.visibility_off : Icons.visibility),
                label: Text(_showAllDatabases ? 'Masquer démos' : 'Voir toutes'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).primaryColor,
                ),
              ),
          ],
        ),
        if (_showAllDatabases && _allDatabases.length > _databases.length)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Affichage de toutes les bases (y compris démos)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange[700],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        const SizedBox(height: AppConstants.defaultPadding),

        Expanded(
          child: ListView.builder(
            itemCount: _displayedDatabases.length,
            itemBuilder: (context, index) {
              final database = _displayedDatabases[index];
              return Card(
                child: RadioListTile<String>(
                  title: Text(database),
                  subtitle: Text('Base de données: $database'),
                  value: database,
                  groupValue: _selectedDatabase,
                  onChanged: (value) {
                    setState(() {
                      _selectedDatabase = value;
                    });
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
