import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/picking.dart';
import '../providers/auth_provider.dart';
import '../providers/picking_provider.dart';
import 'serial_scan_screen.dart';

class PickingDetailScreen extends StatefulWidget {
  final Picking picking;

  const PickingDetailScreen({super.key, required this.picking});

  @override
  State<PickingDetailScreen> createState() => _PickingDetailScreenState();
}

class _PickingDetailScreenState extends State<PickingDetailScreen>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    _fetchPickingLines();
  }

  Future<void> _fetchPickingLines() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final pickingProvider =
        Provider.of<PickingProvider>(context, listen: false);
    if (authProvider.token != null) {
      try {
        await pickingProvider.fetchPickingLines(
            authProvider.token!, widget.picking.id);
        log('Successfully fetched picking lines');
      } catch (error) {
        log('Error fetching picking lines: $error');
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
        title: Text(widget.picking.name),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Add menu functionality
            },
          ),
        ],
      ),
      body: Consumer<PickingProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Stock Move Lines List
              Expanded(
                child: provider.isLoading
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF1976D2)),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Loading...',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : provider.pickingLines.isEmpty
                        ? const Center(
                            child: Text(
                              'No stock move lines found.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16.0),
                            itemCount: provider.pickingLines.length,
                            itemBuilder: (context, index) {
                              final line = provider.pickingLines[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12.0),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8.0),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.2),
                                      spreadRadius: 1,
                                      blurRadius: 3,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16.0),
                                  title: Text(
                                    line.displayName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 8),
                                      Text(
                                        'Demand: ${line.productUomQty.toStringAsFixed(2)} Units',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Done: ${line.quantityDone.toStringAsFixed(2)} Units',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: const Icon(
                                    Icons.chevron_right,
                                    color: Colors.grey,
                                  ),
                                  onTap: () {
                                    // Navigate to serial scan screen
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => SerialScanScreen(
                                          pickingLine: line,
                                          picking: widget.picking,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
              ),
              
              // Synchronize Button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () {
                    _synchronizeData();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    elevation: 2,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sync, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Synchronize',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _synchronizeData() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Synchronizing data to Odoo...'),
            ],
          ),
        );
      },
    );

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final pickingProvider = Provider.of<PickingProvider>(context, listen: false);
      
      if (authProvider.token != null) {
        await pickingProvider.synchronizeWithOdoo(authProvider.token!);
      }
      
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data synchronized successfully with Odoo!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Synchronization failed: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
