import 'package:flutter/material.dart';

class PickingListScreen extends StatelessWidget {
  final String operationType;
  
  const PickingListScreen({Key? key, required this.operationType}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Picking List - $operationType')),
      body: const Center(
        child: Text('Picking List Screen - To be implemented'),
      ),
    );
  }
}
