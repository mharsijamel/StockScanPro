import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../services/sync_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'settings_screen.dart';
import 'connection_diagnostic_screen.dart';
import 'odoo_diagnostic_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late SyncService _syncService;
  bool _isSyncing = false;
  SyncStats? _syncStats;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadSyncStats();
  }

  void _initializeServices() {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    _syncService = SyncService(apiService, authService);
  }

  Future<void> _loadSyncStats() async {
    try {
      final stats = await _syncService.getSyncStats();
      if (mounted) {
        setState(() {
          _syncStats = stats;
        });
      }
    } catch (e) {
      print('Erreur chargement stats: $e');
    }
  }

  Future<void> _performSync() async {
    if (_isSyncing) return;

    setState(() {
      _isSyncing = true;
    });

    try {
      print('🚀 Démarrage de la synchronisation...');
      final result = await _syncService.syncStockOperations();

      if (mounted) {
        // Show detailed result
        _showSyncResultDialog(result);

        if (result.success) {
          await _loadSyncStats(); // Recharger les statistiques
        }
      }
    } catch (e) {
      print('❌ Erreur de synchronisation: $e');
      if (mounted) {
        // Show enhanced error dialog with diagnostic option
        _showSyncErrorDialog(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  void _showSyncErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.error, color: Colors.red),
              const SizedBox(width: 8),
              const Text('Erreur de synchronisation'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Impossible de synchroniser avec le serveur Odoo:'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  error,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade700,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb,
                            size: 16, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Solutions possibles:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Utilisez le mode démo (demo/demo)\n'
                      '• Vérifiez votre connexion internet\n'
                      '• Vérifiez l\'URL du serveur\n'
                      '• Lancez un diagnostic complet',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const OdooDiagnosticScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.medical_services),
              label: const Text('Diagnostic'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSyncResultDialog(SyncResult result) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                result.success ? Icons.check_circle : Icons.error,
                color: result.success ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                result.success
                    ? 'Synchronisation réussie'
                    : 'Erreur de synchronisation',
                style: TextStyle(
                  color: result.success ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(result.message),
              if (result.success) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.input, color: Colors.green.shade600),
                            const SizedBox(height: 4),
                            Text(
                              '${result.stockInCount}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                            Text(
                              'Stock IN',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.output, color: Colors.blue.shade600),
                            const SizedBox(height: 4),
                            Text(
                              '${result.stockOutCount}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            Text(
                              'Stock OUT',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
            if (result.success)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Navigate to stock operations
                  context.go('/pickings/in');
                },
                child: const Text('Voir les opérations'),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('StockScan Pro'),
        actions: [
          // Bouton de synchronisation
          IconButton(
            onPressed: _isSyncing ? null : _performSync,
            icon: _isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(
                    Icons.sync,
                    color: _syncStats?.isConnected == true
                        ? Colors.white
                        : Colors.orange,
                  ),
            tooltip: _isSyncing ? 'Synchronisation...' : 'Synchroniser',
          ),
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return PopupMenuButton<String>(
                icon: const Icon(Icons.account_circle),
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    value: 'user',
                    child:
                        Text('Utilisateur: ${authProvider.username ?? 'Demo'}'),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem<String>(
                    value: 'settings',
                    child: const Row(
                      children: [
                        Icon(Icons.settings),
                        SizedBox(width: 8),
                        Text('Configuration'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'diagnostic',
                    child: const Row(
                      children: [
                        Icon(Icons.medical_services),
                        SizedBox(width: 8),
                        Text('Diagnostic Odoo'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'logout',
                    child: const Row(
                      children: [
                        Icon(Icons.logout),
                        SizedBox(width: 8),
                        Text('Déconnexion'),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) async {
                  if (value == 'settings') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  } else if (value == 'diagnostic') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const OdooDiagnosticScreen(),
                      ),
                    );
                  } else if (value == 'logout') {
                    await authProvider.logout();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  }
                },
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome message
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.waving_hand,
                      color: Colors.orange[600],
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bienvenue !',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Gérez vos opérations de stock avec les numéros de série',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'Opérations',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 16),

            // Sync status card
            if (_syncStats != null) _buildSyncStatusCard(),

            const SizedBox(height: 16),

            // Prominent Sync Button
            _buildSyncButton(),

            const SizedBox(height: 16),

            // Operations grid
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildOperationCard(
                    context,
                    title: 'Stock IN',
                    subtitle: 'Réception de marchandises',
                    icon: Icons.input,
                    color: Colors.green,
                    onTap: () => context.go('/pickings/in'),
                    badgeCount: _syncStats?.totalStockIn,
                  ),
                  _buildOperationCard(
                    context,
                    title: 'Stock OUT',
                    subtitle: 'Expédition de marchandises',
                    icon: Icons.output,
                    color: Colors.blue,
                    onTap: () => context.go('/pickings/out'),
                    badgeCount: _syncStats?.totalStockOut,
                  ),
                  _buildOperationCard(
                    context,
                    title: 'Scanner',
                    subtitle: 'Scanner un numéro de série',
                    icon: Icons.qr_code_scanner,
                    color: Colors.orange,
                    onTap: () {
                      // For demo, go to scanning with dummy IDs
                      context.go('/scanning/1/1');
                    },
                  ),
                  _buildOperationCard(
                    context,
                    title: 'Historique',
                    subtitle: 'Voir les opérations passées',
                    icon: Icons.history,
                    color: Colors.purple,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Fonctionnalité à venir'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncButton() {
    return Card(
      elevation: 6,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade600,
              Colors.blue.shade700,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: InkWell(
          onTap: _isSyncing ? null : _performSync,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: _isSyncing
                      ? const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.sync,
                          size: 28,
                          color: Colors.white,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isSyncing
                            ? 'Synchronisation en cours...'
                            : 'Synchroniser avec Odoo',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isSyncing
                            ? 'Récupération des opérations Stock IN/OUT'
                            : 'Récupérer les dernières opérations et produits',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_isSyncing)
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white.withOpacity(0.8),
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOperationCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    int? badgeCount,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Icon(
                      icon,
                      size: 30,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            if (badgeCount != null && badgeCount > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncStatusCard() {
    final stats = _syncStats!;
    final lastSync = stats.lastSyncTime;
    final isConnected = stats.isConnected;

    return Card(
      color: isConnected ? Colors.green.shade50 : Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isConnected ? Icons.cloud_done : Icons.cloud_off,
                  color: isConnected ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  isConnected ? 'Connecté à Odoo' : 'Hors ligne',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isConnected
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                  ),
                ),
                const Spacer(),
                if (_isSyncing)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Stock IN',
                    stats.totalStockIn.toString(),
                    Icons.input,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Stock OUT',
                    stats.totalStockOut.toString(),
                    Icons.output,
                    Colors.blue,
                  ),
                ),
                if (stats.pendingSync > 0)
                  Expanded(
                    child: _buildStatItem(
                      'En attente',
                      stats.pendingSync.toString(),
                      Icons.sync_problem,
                      Colors.orange,
                    ),
                  ),
              ],
            ),
            if (lastSync != null) ...[
              const SizedBox(height: 8),
              Text(
                'Dernière sync: ${_formatLastSync(lastSync)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  String _formatLastSync(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else {
      return 'Il y a ${difference.inDays} jour(s)';
    }
  }
}
