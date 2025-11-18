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
      body: Column(
        children: [
          // Custom Header with gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1976D2), // Dark blue
                  Color(0xFF42A5F5), // Light blue
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Header with title and menu
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Stock Pickings',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.logout,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: () => authProvider.logout(),
                          tooltip: 'Déconnexion',
                        ),
                      ],
                    ),
                  ),
                  // Tab Bar
                  TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.white,
                    indicatorWeight: 3,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    labelStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    tabs: const [
                      Tab(text: 'INCOMING'),
                      Tab(text: 'OUTGOING'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Content Area
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                // Content for the "Incoming" tab
                PickingListScreen(pickingType: 'incoming', title: 'Réceptions'),
                // Content for the "Outgoing" tab
                PickingListScreen(pickingType: 'outgoing', title: 'Livraisons'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
