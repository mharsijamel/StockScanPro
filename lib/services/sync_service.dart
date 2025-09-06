import 'api_service.dart';
import 'database_service.dart';
import '../constants/app_constants.dart';

class SyncService {
  final ApiService _apiService;
  final DatabaseService _databaseService;
  
  SyncService(this._apiService, this._databaseService);
  
  Future<void> syncAll() async {
    // Implement sync logic
    await syncPickings();
    await syncScannedSerialNumbers();
  }
  
  Future<void> syncPickings() async {
    // Implement picking sync
  }
  
  Future<void> syncScannedSerialNumbers() async {
    // Implement SN sync
  }
}
