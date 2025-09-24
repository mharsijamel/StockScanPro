import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'picking_list_screen.dart'; // Make sure this path is correct

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Pickings'), // Changed title
        elevation: 4.0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authProvider.logout(),
            tooltip: 'Déconnexion',
          ),
        ],
        // Add TabBar to the AppBar's bottom
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white, // Indicator for selected tab
          labelColor: Colors.white, // Text color for selected tab
          unselectedLabelColor:
              Colors.white.withOpacity(0.7), // Text color for unselected tabs
          tabs: const [
            Tab(text: 'INCOMING'), // Tab 1
            Tab(text: 'OUTGOING'), // Tab 2
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          // Content for the "Incoming" tab
          PickingListScreen(pickingType: 'incoming', title: 'Réceptions'),
          // Content for the "Outgoing" tab
          PickingListScreen(pickingType: 'outgoing', title: 'Livraisons'),
        ],
      ),
    );
  }
}
