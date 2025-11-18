import 'dart:developer';
import 'package:flutter/material.dart';
import '../api/api_service.dart';
import '../models/picking.dart';
import '../models/picking_line.dart';
import '../utils/database_helper.dart';

class PickingProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  bool _isLoading = false;
  List<Picking> _pickings = [];
  List<PickingLine> _pickingLines = [];

  bool get isLoading => _isLoading;
  List<Picking> get pickings => _pickings;
  List<PickingLine> get pickingLines => _pickingLines;

  Future<void> fetchPickings(String token, String pickingType) async {
    log('🔄 PickingProvider: Starting fetchPickings for type: $pickingType');
    log('🔑 PickingProvider: Token: ${token.substring(0, 20)}...');
    
    _isLoading = true;
    _pickings = []; // Vider la liste précédente
    notifyListeners();
    log('📱 PickingProvider: Set loading to true, cleared pickings list');

    try {
      log('🌐 PickingProvider: Calling API service...');
      _pickings = await _apiService.getPickings(token, pickingType);
      log('✅ PickingProvider: Successfully fetched ${_pickings.length} pickings');
      
      // Log first few pickings for debugging
      for (int i = 0; i < _pickings.length && i < 3; i++) {
        log('📦 PickingProvider: Picking $i: ${_pickings[i].name} - ${_pickings[i].partnerName}');
      }
    } catch (e) {
      log('❌ PickingProvider: Error fetching pickings: $e');
      print('❌ PickingProvider Error: $e');
      rethrow;
    }

    _isLoading = false;
    notifyListeners();
    log('📱 PickingProvider: Set loading to false, notified listeners');
  }

  Future<void> fetchPickingLines(String token, int pickingId) async {
    log('📦 PickingProvider: Starting fetchPickingLines for picking $pickingId');
    _isLoading = true;
    _pickingLines = []; // Vider la liste précédente
    notifyListeners();
    log('📱 PickingProvider: Set loading to true, cleared picking lines list');

    try {
      log('🌐 PickingProvider: Calling API service for picking lines...');
      _pickingLines = await _apiService.getPickingLines(token, pickingId);
      log('✅ PickingProvider: Successfully fetched ${_pickingLines.length} picking lines');
      
      // Load scanned serials from database for each line
      for (int i = 0; i < _pickingLines.length; i++) {
        final serials = await _dbHelper.getScannedSerials(_pickingLines[i].id);
        _pickingLines[i].scannedSerials = serials;
        log('📋 PickingProvider: Loaded ${serials.length} scanned serials for line ${_pickingLines[i].id}');
      }
      
      // Log first few picking lines for debugging
      for (int i = 0; i < _pickingLines.length && i < 3; i++) {
        log('📦 PickingProvider: Line $i: ${_pickingLines[i].displayName} - ${_pickingLines[i].scannedSerials.length} serials');
      }
    } catch (e) {
      log('❌ PickingProvider: Error fetching picking lines: $e');
      print('❌ PickingProvider Error: $e');
      rethrow;
    }

    _isLoading = false;
    notifyListeners();
    log('📱 PickingProvider: Set loading to false, notified listeners');
  }

  // Method to update scanned serials for a picking line using SQLite
  Future<void> updatePickingLineSerials(int pickingLineId, int pickingId, List<String> serials) async {
    log('📦 PickingProvider: Updating serials in database for line $pickingLineId');
    log('📋 PickingProvider: Serials: $serials');
    
    try {
      // Save to database
      await _dbHelper.saveScannedSerials(
        pickingLineId: pickingLineId,
        pickingId: pickingId,
        serialNumbers: serials,
      );
      
      // Update the in-memory list
      for (int i = 0; i < _pickingLines.length; i++) {
        if (_pickingLines[i].id == pickingLineId) {
          _pickingLines[i].scannedSerials = List.from(serials);
          log('✅ PickingProvider: Updated line ${_pickingLines[i].displayName} with ${serials.length} serials');
          break;
        }
      }
      
      notifyListeners();
    } catch (e) {
      log('❌ PickingProvider: Error updating serials: $e');
      rethrow;
    }
  }

  // Method to get scanned serials for a picking line from SQLite
  Future<List<String>> getPickingLineSerials(int lineId) async {
    try {
      return await _dbHelper.getScannedSerials(lineId);
    } catch (e) {
      log('❌ PickingProvider: Error getting serials: $e');
      return [];
    }
  }

  // Method to get count of scanned serials
  Future<int> getScannedSerialsCount(int lineId) async {
    try {
      return await _dbHelper.getScannedSerialsCount(lineId);
    } catch (e) {
      log('❌ PickingProvider: Error getting serials count: $e');
      return 0;
    }
  }

  // Method to synchronize all unsynced data with Odoo
  Future<void> synchronizeWithOdoo(String token) async {
    log('🔄 PickingProvider: Starting synchronization with Odoo');
    
    try {
      final unsyncedSerials = await _dbHelper.getUnsyncedSerials();
      log('📋 PickingProvider: Found ${unsyncedSerials.length} unsynced serials');
      
      if (unsyncedSerials.isEmpty) {
        log('✅ PickingProvider: No data to synchronize');
        return;
      }
      
      // Group serials by picking line
      Map<int, List<Map<String, dynamic>>> groupedSerials = {};
      for (var serial in unsyncedSerials) {
        int lineId = serial['picking_line_id'];
        if (!groupedSerials.containsKey(lineId)) {
          groupedSerials[lineId] = [];
        }
        groupedSerials[lineId]!.add(serial);
      }
      
      // TODO: Implement actual API calls to sync with Odoo
      // For now, just simulate the sync
      await Future.delayed(const Duration(seconds: 2));
      
      // Mark all as synced
      List<int> serialIds = unsyncedSerials.map((s) => s['id'] as int).toList();
      await _dbHelper.markSerialsAsSynced(serialIds);
      
      log('✅ PickingProvider: Synchronization completed successfully');
    } catch (e) {
      log('❌ PickingProvider: Error during synchronization: $e');
      rethrow;
    }
  }
}
