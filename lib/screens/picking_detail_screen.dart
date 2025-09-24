import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/animation.dart';
import '../models/picking.dart';
import '../providers/auth_provider.dart';
import '../providers/picking_provider.dart';

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
        elevation: 4.0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<PickingProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.picking.name,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 28,
                            shadows: [
                              Shadow(
                                blurRadius: 4,
                                color: Colors.black.withOpacity(0.25),
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(Icons.person,
                                size: 24, color: Colors.grey.shade600),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                widget.picking.partnerName,
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
                              widget.picking.scheduledDate.split(' ').first,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        if (widget.picking.origin != null &&
                            widget.picking.origin!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(Icons.info_outline,
                                  size: 24, color: Colors.grey.shade600),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'Origine: ${widget.picking.origin}',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 16.0),
                child: Text(
                  'Lignes de mouvement',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.secondary,
                        fontSize: 24,
                      ),
                ),
              ),
              Expanded(
                child: provider.pickingLines.isEmpty
                    ? Center(
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
                              'Aucune ligne trouvée pour ce mouvement.',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.8),
                                    fontSize: 20,
                                  ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: provider.pickingLines.length,
                        itemBuilder: (context, index) {
                          final line = provider.pickingLines[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 16.0),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.0)),
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    line.displayName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                        ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Demandé: ${line.productUomQty}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge,
                                      ),
                                      Text(
                                        'Fait: ${line.quantityDone}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                              fontSize: 20,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
