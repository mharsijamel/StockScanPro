import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/picking.dart';
import '../models/picking_line.dart';
import '../providers/picking_provider.dart';

class SerialScanScreen extends StatefulWidget {
  final PickingLine pickingLine;
  final Picking picking;

  const SerialScanScreen({
    super.key,
    required this.pickingLine,
    required this.picking,
  });

  @override
  State<SerialScanScreen> createState() => _SerialScanScreenState();
}

class _SerialScanScreenState extends State<SerialScanScreen> {
  final TextEditingController _serialController = TextEditingController();
  final FocusNode _serialFocusNode = FocusNode();
  List<String> _scannedSerials = [];

  @override
  void initState() {
    super.initState();
    
    // Load existing scanned serials from database
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final pickingProvider = Provider.of<PickingProvider>(context, listen: false);
      final existingSerials = await pickingProvider.getPickingLineSerials(widget.pickingLine.id);
      
      if (existingSerials.isNotEmpty) {
        setState(() {
          _scannedSerials = List.from(existingSerials);
        });
        log('📋 Loaded ${existingSerials.length} existing serials for line ${widget.pickingLine.id}');
      }
      
      // Auto-focus on the text field for immediate scanning
      _serialFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _serialController.dispose();
    _serialFocusNode.dispose();
    super.dispose();
  }

  void _onSerialScanned() {
    final serial = _serialController.text.trim();
    if (serial.isNotEmpty) {
      if (!_scannedSerials.contains(serial)) {
        setState(() {
          _scannedSerials.add(serial);
          _serialController.clear();
        });
        
        // Provide haptic feedback
        HapticFeedback.lightImpact();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Serial number $serial added'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
        
        log('Serial scanned: $serial');
      } else {
        // Serial already exists
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Serial number $serial already scanned'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
        _serialController.clear();
      }
    }
    
    // Refocus for next scan
    _serialFocusNode.requestFocus();
  }

  void _removeSerial(String serial) {
    setState(() {
      _scannedSerials.remove(serial);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Serial number $serial removed'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _saveSerials() async {
    if (_scannedSerials.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please scan at least one serial number'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

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
              Text('Saving serial numbers to database...'),
            ],
          ),
        );
      },
    );

    try {
      // Save to SQLite database through provider
      final pickingProvider = Provider.of<PickingProvider>(context, listen: false);
      await pickingProvider.updatePickingLineSerials(
        widget.pickingLine.id,
        widget.picking.id,
        _scannedSerials,
      );
      
      log('📦 Saved ${_scannedSerials.length} serials to database for line ${widget.pickingLine.id}: ${widget.pickingLine.displayName}');
      for (String serial in _scannedSerials) {
        log('📋 Serial: $serial');
      }
      
      // Brief delay for user feedback
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        Navigator.of(context).pop(); // Return to picking detail screen
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_scannedSerials.length} serial numbers saved to database!'),
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
            content: Text('Failed to save serial numbers: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final requiredQuantity = widget.pickingLine.productUomQty.toInt();
    final scannedQuantity = _scannedSerials.length;
    final isComplete = scannedQuantity >= requiredQuantity;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Serial Numbers'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Product Information
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.pickingLine.displayName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Required: $requiredQuantity',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Scanned: $scannedQuantity',
                      style: TextStyle(
                        fontSize: 14,
                        color: isComplete ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Scanning Input
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Scan or Enter Serial Number:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _serialController,
                  focusNode: _serialFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Scan or type serial number...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    prefixIcon: const Icon(Icons.qr_code_scanner),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _onSerialScanned,
                    ),
                  ),
                  onSubmitted: (_) => _onSerialScanned(),
                  textInputAction: TextInputAction.done,
                ),
              ],
            ),
          ),

          // Progress Indicator
          if (requiredQuantity > 0)
            Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Progress:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '$scannedQuantity / $requiredQuantity',
                        style: TextStyle(
                          fontSize: 14,
                          color: isComplete ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: requiredQuantity > 0 ? scannedQuantity / requiredQuantity : 0,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isComplete ? Colors.green : const Color(0xFF1976D2),
                    ),
                  ),
                ],
              ),
            ),

          // Scanned Serials List
          Expanded(
            child: _scannedSerials.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.qr_code_scanner,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No serial numbers scanned yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Use the scanner or type serial numbers above',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _scannedSerials.length,
                    itemBuilder: (context, index) {
                      final serial = _scannedSerials[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green,
                            radius: 16,
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            serial,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeSerial(serial),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Save Button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _scannedSerials.isNotEmpty ? _saveSerials : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                elevation: 2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.save, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Save ${_scannedSerials.length} Serial Numbers',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}