import 'package:flutter/material.dart';

class ProductListScreen extends StatelessWidget {
  final int pickingId;
  
  const ProductListScreen({Key? key, required this.pickingId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Products - Picking $pickingId')),
      body: const Center(
        child: Text('Product List Screen - To be implemented'),
      ),
    );
  }
}
