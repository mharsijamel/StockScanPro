import 'package:flutter/foundation.dart';
import '../services/database_service.dart';
import '../services/api_service.dart';
import '../models/picking.dart';

class PickingProvider extends ChangeNotifier {
  final DatabaseService _databaseService;
  final ApiService _apiService;
  
  List<Picking> _pickings = [];
  bool _isLoading = false;
  String? _error;
  
  PickingProvider(this._databaseService, this._apiService);
  
  // Getters
  List<Picking> get pickings => _pickings;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  Future<void> loadPickings({String? operationType}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _pickings = await _databaseService.getPickings(operationType: operationType);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
