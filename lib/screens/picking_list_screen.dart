import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/picking_provider.dart';
import 'picking_detail_screen.dart';

class PickingListScreen extends StatefulWidget {
  final String pickingType;
  final String title;

  const PickingListScreen(
      {super.key, required this.pickingType, required this.title});

  @override
  State<PickingListScreen> createState() => _PickingListScreenState();
}

class _PickingListScreenState extends State<PickingListScreen> {
  @override
  void initState() {
    super.initState();
    // Charger les données initiales
    _fetchData();
  }

  Future<void> _fetchData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final pickingProvider =
        Provider.of<PickingProvider>(context, listen: false);
    if (authProvider.token != null) {
      try {
        await pickingProvider.fetchPickings(
            authProvider.token!, widget.pickingType);
        log('Successfully fetched pickings');
      } catch (error) {
        log('Error fetching pickings: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        elevation: 4.0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<PickingProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.pickings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline,
                      size: 80,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.6)),
                  const SizedBox(height: 24),
                  Text(
                    'Aucun mouvement trouvé.',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.8),
                          fontSize: 20,
                        ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _fetchData,
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: provider.pickings.length,
              itemBuilder: (context, index) {
                final picking = provider.pickings[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 16.0),
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0)),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => PickingDetailScreen(picking: picking),
                      ));
                    },
                    borderRadius: BorderRadius.circular(20.0),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  picking.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        fontSize: 24,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0, vertical: 6.0),
                                decoration: BoxDecoration(
                                  color: widget.pickingType == 'incoming'
                                      ? Colors.green.shade100
                                      : Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: Text(
                                  widget.pickingType == 'incoming'
                                      ? 'IN'
                                      : 'OUT',
                                  style: TextStyle(
                                    color: widget.pickingType == 'incoming'
                                        ? Colors.green.shade800
                                        : Colors.orange.shade800,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(Icons.person,
                                  size: 24, color: Colors.grey.shade600),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  picking.partnerName,
                                  style: Theme.of(context).textTheme.titleLarge,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(Icons.calendar_today,
                                  size: 24, color: Colors.grey.shade600),
                              const SizedBox(width: 16),
                              Text(
                                picking.scheduledDate.split(' ').first,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchData, // Synchroniser
        tooltip: 'Synchroniser',
        child: const Icon(Icons.sync),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}
