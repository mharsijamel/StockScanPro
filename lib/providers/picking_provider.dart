import 'package:flutter/material.dart';
import '../api/api_service.dart';
import '../models/picking.dart';
import '../models/picking_line.dart';

class PickingProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  List<Picking> _pickings = [];
  List<PickingLine> _pickingLines = [];

  bool get isLoading => _isLoading;
  List<Picking> get pickings => _pickings;
  List<PickingLine> get pickingLines => _pickingLines;

  Future<void> fetchPickings(String token, String pickingType) async {
    _isLoading = true;
    _pickings = []; // Vider la liste précédente
    notifyListeners();

    try {
      _pickings = await _apiService.getPickings(token, pickingType);
    } catch (e) {
      // Gérer l'erreur, par exemple avec un logger
      print(e.toString());
      rethrow;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchPickingLines(String token, int pickingId) async {
    _isLoading = true;
    _pickingLines = []; // Vider la liste précédente
    notifyListeners();

    try {
      _pickingLines = await _apiService.getPickingLines(token, pickingId);
    } catch (e) {
      print(e.toString());
      rethrow;
    }

    _isLoading = false;
    notifyListeners();
  }
}
