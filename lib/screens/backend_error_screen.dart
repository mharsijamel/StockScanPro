import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BackendErrorScreen extends StatelessWidget {
  final VoidCallback onRetry;

  const BackendErrorScreen({
    Key? key,
    required this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_off_outlined,
                size: 80,
                color: Colors.red.shade700,
              ),
              const SizedBox(height: 24),
              Text(
                'Problème de Connexion Odoo',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade900,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                'L\'application ne parvient pas à communiquer avec le module "Stock Scan Mobile" sur votre serveur Odoo. Le module est probablement manquant ou pas activé.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              _buildTroubleshootingCard(context),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                  onPressed: onRetry,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  child: const Text('Fermer l\'application'),
                  onPressed: () => SystemNavigator.pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTroubleshootingCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🔧 Actions de Dépannage (pour l\'administrateur Odoo)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          const _TroubleshootingStep(
            step: '1. Vérifier l\'installation du module',
            details:
                'Assurez-vous que le module "stock_scan_mobile" est présent dans le dossier des "addons" de votre instance Odoo.',
          ),
          const _TroubleshootingStep(
            step: '2. Mettre à jour la liste des applications',
            details:
                'Dans Odoo, allez dans le menu "Apps" et cliquez sur "Update Apps List".',
          ),
          const _TroubleshootingStep(
            step: '3. Installer le module',
            details:
                'Cherchez "Stock Scan Mobile API" et installez-le. S\'il est déjà installé, essayez de le réinstaller.',
          ),
          const _TroubleshootingStep(
            step: '4. Redémarrer le service Odoo',
            details:
                'Après l\'installation, un redémarrage du service Odoo est souvent nécessaire.',
          ),
        ],
      ),
    );
  }
}

class _TroubleshootingStep extends StatelessWidget {
  final String step;
  final String details;

  const _TroubleshootingStep({
    Key? key,
    required this.step,
    required this.details,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            step,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            details,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade700,
                ),
          ),
        ],
      ),
    );
  }
}
