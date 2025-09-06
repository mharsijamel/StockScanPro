import 'package:flutter/foundation.dart';
import '../services/sync_service.dart';

class SyncProvider extends ChangeNotifier {
  final SyncService _syncService;
  
  bool _isSyncing = false;
  String? _error;
  DateTime? _lastSyncTime;
  
  SyncProvider(this._syncService);
  
  // Getters
  bool get isSyncing => _isSyncing;
  String? get error => _error;
  DateTime? get lastSyncTime => _lastSyncTime;
  
  // Sync data
  Future<bool> syncData() async {
    _isSyncing = true;
    _error = null;
    notifyListeners();
    
    try {
      await _syncService.syncAll();
      _lastSyncTime = DateTime.now();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
