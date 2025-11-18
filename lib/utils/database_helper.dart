import 'dart:developer';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'stock_app.db');
    log('🗄️ DatabaseHelper: Initializing database at $path');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    log('🏗️ DatabaseHelper: Creating database tables');
    
    // Table for scanned serial numbers
    await db.execute('''
      CREATE TABLE scanned_serials (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        picking_line_id INTEGER NOT NULL,
        picking_id INTEGER NOT NULL,
        serial_number TEXT NOT NULL,
        created_at TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        UNIQUE(picking_line_id, serial_number)
      )
    ''');
    
    log('✅ DatabaseHelper: Database tables created successfully');
  }

  // Save a scanned serial number
  Future<int> insertScannedSerial({
    required int pickingLineId,
    required int pickingId,
    required String serialNumber,
  }) async {
    try {
      final db = await database;
      final result = await db.insert(
        'scanned_serials',
        {
          'picking_line_id': pickingLineId,
          'picking_id': pickingId,
          'serial_number': serialNumber,
          'created_at': DateTime.now().toIso8601String(),
          'synced': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      log('💾 DatabaseHelper: Saved serial $serialNumber for line $pickingLineId');
      return result;
    } catch (e) {
      log('❌ DatabaseHelper: Error saving serial: $e');
      rethrow;
    }
  }

  // Get all scanned serials for a picking line
  Future<List<String>> getScannedSerials(int pickingLineId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'scanned_serials',
        where: 'picking_line_id = ?',
        whereArgs: [pickingLineId],
        orderBy: 'created_at ASC',
      );
      
      List<String> serials = maps.map((map) => map['serial_number'] as String).toList();
      log('📖 DatabaseHelper: Retrieved ${serials.length} serials for line $pickingLineId');
      return serials;
    } catch (e) {
      log('❌ DatabaseHelper: Error retrieving serials: $e');
      return [];
    }
  }

  // Save multiple scanned serials at once
  Future<void> saveScannedSerials({
    required int pickingLineId,
    required int pickingId,
    required List<String> serialNumbers,
  }) async {
    try {
      final db = await database;
      
      // Start a transaction for better performance
      await db.transaction((txn) async {
        // First, delete existing serials for this line
        await txn.delete(
          'scanned_serials',
          where: 'picking_line_id = ?',
          whereArgs: [pickingLineId],
        );
        
        // Then insert all new serials
        for (String serial in serialNumbers) {
          await txn.insert(
            'scanned_serials',
            {
              'picking_line_id': pickingLineId,
              'picking_id': pickingId,
              'serial_number': serial,
              'created_at': DateTime.now().toIso8601String(),
              'synced': 0,
            },
          );
        }
      });
      
      log('💾 DatabaseHelper: Saved ${serialNumbers.length} serials for line $pickingLineId');
    } catch (e) {
      log('❌ DatabaseHelper: Error saving serials: $e');
      rethrow;
    }
  }

  // Delete a specific serial number
  Future<int> deleteScannedSerial(int pickingLineId, String serialNumber) async {
    try {
      final db = await database;
      final result = await db.delete(
        'scanned_serials',
        where: 'picking_line_id = ? AND serial_number = ?',
        whereArgs: [pickingLineId, serialNumber],
      );
      
      log('🗑️ DatabaseHelper: Deleted serial $serialNumber from line $pickingLineId');
      return result;
    } catch (e) {
      log('❌ DatabaseHelper: Error deleting serial: $e');
      return 0;
    }
  }

  // Get all unsynced serials for synchronization
  Future<List<Map<String, dynamic>>> getUnsyncedSerials() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'scanned_serials',
        where: 'synced = ?',
        whereArgs: [0],
        orderBy: 'picking_line_id, created_at ASC',
      );
      
      log('🔄 DatabaseHelper: Found ${maps.length} unsynced serials');
      return maps;
    } catch (e) {
      log('❌ DatabaseHelper: Error retrieving unsynced serials: $e');
      return [];
    }
  }

  // Mark serials as synced
  Future<void> markSerialsAsSynced(List<int> serialIds) async {
    try {
      final db = await database;
      await db.transaction((txn) async {
        for (int id in serialIds) {
          await txn.update(
            'scanned_serials',
            {'synced': 1},
            where: 'id = ?',
            whereArgs: [id],
          );
        }
      });
      
      log('✅ DatabaseHelper: Marked ${serialIds.length} serials as synced');
    } catch (e) {
      log('❌ DatabaseHelper: Error marking serials as synced: $e');
      rethrow;
    }
  }

  // Get count of scanned serials for a picking line
  Future<int> getScannedSerialsCount(int pickingLineId) async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM scanned_serials WHERE picking_line_id = ?',
        [pickingLineId],
      );
      
      int count = result.first['count'] as int;
      log('🔢 DatabaseHelper: Line $pickingLineId has $count scanned serials');
      return count;
    } catch (e) {
      log('❌ DatabaseHelper: Error counting serials: $e');
      return 0;
    }
  }

  // Clear all data (for testing or reset)
  Future<void> clearAllData() async {
    try {
      final db = await database;
      await db.delete('scanned_serials');
      log('🧹 DatabaseHelper: All data cleared');
    } catch (e) {
      log('❌ DatabaseHelper: Error clearing data: $e');
      rethrow;
    }
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
    log('🔒 DatabaseHelper: Database closed');
  }
}