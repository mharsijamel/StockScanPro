import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StockOutScreen extends StatefulWidget {
  const StockOutScreen({super.key});

  @override
  State<StockOutScreen> createState() => _StockOutScreenState();
}

class _StockOutScreenState extends State<StockOutScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock OUT - Livraison'),
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
              Icons.output,
              size: 80,
              color: Colors.blue,
            ),
            SizedBox(height: 16),
            Text(
              'Stock OUT - Livraison',
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
            Text('• Liste des livraisons en attente'),
            Text('• Scan des numéros de série'),
            Text('• Validation des livraisons'),
            Text('• Synchronisation avec Odoo'),
          ],
        ),
      ),
    );
  }
}
