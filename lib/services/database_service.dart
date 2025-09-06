import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../constants/app_constants.dart';
import '../models/picking.dart';

class DatabaseService {
  static Database? _database;
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }
  
  Future<Database> initDatabase() async {
    String path = join(await getDatabasesPath(), AppConstants.databaseName);
    
    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }
  
  Future<void> _createDatabase(Database db, int version) async {
    // Create pickings table
    await db.execute('''
      CREATE TABLE ${AppConstants.pickingsTable} (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        operation_type TEXT NOT NULL,
        state TEXT NOT NULL,
        partner_id TEXT,
        partner_name TEXT,
        scheduled_date INTEGER,
        date_created INTEGER,
        sync_status TEXT DEFAULT 'completed'
      )
    ''');
    
    // Create products table
    await db.execute('''
      CREATE TABLE ${AppConstants.productsTable} (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        default_code TEXT,
        barcode TEXT,
        picking_id INTEGER NOT NULL,
        quantity REAL NOT NULL,
        quantity_done REAL DEFAULT 0.0,
        location TEXT,
        FOREIGN KEY (picking_id) REFERENCES ${AppConstants.pickingsTable} (id)
      )
    ''');
    
    // Create scanned_sn table
    await db.execute('''
      CREATE TABLE ${AppConstants.scannedSnTable} (
        id TEXT PRIMARY KEY,
        serial_number TEXT NOT NULL,
        product_id INTEGER NOT NULL,
        picking_id INTEGER NOT NULL,
        location TEXT,
        scanned_at INTEGER NOT NULL,
        sync_status TEXT DEFAULT 'pending',
        FOREIGN KEY (product_id) REFERENCES ${AppConstants.productsTable} (id),
        FOREIGN KEY (picking_id) REFERENCES ${AppConstants.pickingsTable} (id)
      )
    ''');
    
    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_pickings_type ON ${AppConstants.pickingsTable} (operation_type)');
    await db.execute('CREATE INDEX idx_products_picking ON ${AppConstants.productsTable} (picking_id)');
    await db.execute('CREATE INDEX idx_scanned_sn_product ON ${AppConstants.scannedSnTable} (product_id)');
    await db.execute('CREATE INDEX idx_scanned_sn_sync ON ${AppConstants.scannedSnTable} (sync_status)');
  }
  
  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
    if (oldVersion < 2) {
      // Example: Add new column in version 2
      // await db.execute('ALTER TABLE ${AppConstants.pickingsTable} ADD COLUMN new_column TEXT');
    }
  }
  
  // Picking operations
  Future<int> insertPicking(Picking picking) async {
    final db = await database;
    return await db.insert(AppConstants.pickingsTable, picking.toDatabase());
  }
  
  Future<List<Picking>> getPickings({String? operationType}) async {
    final db = await database;
    
    String whereClause = '';
    List<dynamic> whereArgs = [];
    
    if (operationType != null) {
      whereClause = 'WHERE operation_type = ?';
      whereArgs.add(operationType);
    }
    
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT * FROM ${AppConstants.pickingsTable} $whereClause ORDER BY scheduled_date DESC',
      whereArgs,
    );
    
    return List.generate(maps.length, (i) => Picking.fromDatabase(maps[i]));
  }
  
  Future<Picking?> getPickingById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.pickingsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return Picking.fromDatabase(maps.first);
    }
    return null;
  }
  
  Future<int> updatePicking(Picking picking) async {
    final db = await database;
    return await db.update(
      AppConstants.pickingsTable,
      picking.toDatabase(),
      where: 'id = ?',
      whereArgs: [picking.id],
    );
  }
  
  Future<int> deletePicking(int id) async {
    final db = await database;
    return await db.delete(
      AppConstants.pickingsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  // Product operations
  Future<int> insertProduct(Product product) async {
    final db = await database;
    return await db.insert(AppConstants.productsTable, product.toDatabase());
  }
  
  Future<List<Product>> getProductsByPickingId(int pickingId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.productsTable,
      where: 'picking_id = ?',
      whereArgs: [pickingId],
      orderBy: 'name ASC',
    );
    
    return List.generate(maps.length, (i) => Product.fromDatabase(maps[i]));
  }
  
  Future<Product?> getProductById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.productsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return Product.fromDatabase(maps.first);
    }
    return null;
  }
  
  // ScannedSn operations
  Future<int> insertScannedSn(ScannedSn scannedSn) async {
    final db = await database;
    return await db.insert(AppConstants.scannedSnTable, scannedSn.toDatabase());
  }
  
  Future<List<ScannedSn>> getScannedSnsByProductId(int productId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.scannedSnTable,
      where: 'product_id = ?',
      whereArgs: [productId],
      orderBy: 'scanned_at DESC',
    );
    
    return List.generate(maps.length, (i) => ScannedSn.fromDatabase(maps[i]));
  }
  
  Future<bool> isSerialNumberExists(String serialNumber, int pickingId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.scannedSnTable,
      where: 'serial_number = ? AND picking_id = ?',
      whereArgs: [serialNumber, pickingId],
    );
    
    return maps.isNotEmpty;
  }
  
  Future<List<ScannedSn>> getPendingSyncScannedSns() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.scannedSnTable,
      where: 'sync_status = ?',
      whereArgs: [AppConstants.syncPending],
      orderBy: 'scanned_at ASC',
    );
    
    return List.generate(maps.length, (i) => ScannedSn.fromDatabase(maps[i]));
  }
  
  Future<int> updateScannedSnSyncStatus(String id, String syncStatus) async {
    final db = await database;
    return await db.update(
      AppConstants.scannedSnTable,
      {'sync_status': syncStatus},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  // Clear all data
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete(AppConstants.scannedSnTable);
    await db.delete(AppConstants.productsTable);
    await db.delete(AppConstants.pickingsTable);
  }
  
  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
