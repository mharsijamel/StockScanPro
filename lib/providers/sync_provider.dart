import 'package:flutter/foundation.dart';
import '../services/sync_service.dart';

class SyncProvider extends ChangeNotifier {
  final SyncService _syncService;

  bool _isSyncing = false;
  String? _error;
  DateTime? _lastSyncTime;
  SyncStats? _syncStats;

  SyncProvider(this._syncService);

  // Getters
  bool get isSyncing => _isSyncing;
  String? get error => _error;
  DateTime? get lastSyncTime => _lastSyncTime;
  SyncStats? get syncStats => _syncStats;

  // Initialize and load sync stats
  Future<void> initialize() async {
    await loadSyncStats();
  }

  // Load sync statistics
  Future<void> loadSyncStats() async {
    try {
      _syncStats = await _syncService.getSyncStats();
      notifyListeners();
    } catch (e) {
      print('Error loading sync stats: $e');
    }
  }

  // Check connection status
  Future<bool> checkConnection() async {
    try {
      return await _syncService.checkConnection();
    } catch (e) {
      return false;
    }
  }

  // Sync data
  Future<bool> syncData() async {
    _isSyncing = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _syncService.syncStockOperations();
      _lastSyncTime = DateTime.now();
      if (!result.success) {
        _error = result.message;
        return false;
      }
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  // Sync serial numbers for a specific picking
  Future<bool> syncSerialNumbers(
      int pickingId, List<String> serialNumbers) async {
    try {
      _error = null;
      notifyListeners();

      final success =
          await _syncService.syncSerialNumbers(pickingId, serialNumbers);
      if (!success) {
        _error = 'Failed to sync serial numbers';
        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
