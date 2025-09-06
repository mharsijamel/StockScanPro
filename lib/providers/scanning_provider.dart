import 'package:flutter/foundation.dart';
import '../services/database_service.dart';
import '../services/api_service.dart';
import '../models/picking.dart';

class ScanningProvider extends ChangeNotifier {
  final DatabaseService _databaseService;
  final ApiService _apiService;
  
  List<ScannedSn> _scannedSns = [];
  bool _isScanning = false;
  String? _error;
  
  ScanningProvider(this._databaseService, this._apiService);
  
  // Getters
  List<ScannedSn> get scannedSns => _scannedSns;
  bool get isScanning => _isScanning;
  String? get error => _error;
  
  Future<void> loadScannedSns(int productId) async {
    try {
      _scannedSns = await _databaseService.getScannedSnsByProductId(productId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
