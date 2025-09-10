import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StockInScreen extends StatefulWidget {
  const StockInScreen({super.key});

  @override
  State<StockInScreen> createState() => _StockInScreenState();
}

class _StockInScreenState extends State<StockInScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock IN - Réception'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.input,
              size: 80,
              color: Colors.green,
            ),
            SizedBox(height: 16),
            Text(
              'Stock IN - Réception',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Écran en cours de développement',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 32),
            Text(
              'Fonctionnalités à venir :',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 16),
            Text('• Liste des réceptions en attente'),
            Text('• Scan des numéros de série'),
            Text('• Validation des réceptions'),
            Text('• Synchronisation avec Odoo'),
          ],
        ),
      ),
    );
  }
}
