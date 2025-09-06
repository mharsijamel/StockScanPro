import 'package:flutter/material.dart';

class ScanningScreen extends StatelessWidget {
  final int pickingId;
  final int productId;
  
  const ScanningScreen({
    Key? key, 
    required this.pickingId, 
    required this.productId
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scanning')),
      body: const Center(
        child: Text('Scanning Screen - To be implemented'),
      ),
    );
  }
}
