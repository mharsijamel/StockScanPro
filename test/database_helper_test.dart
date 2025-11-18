import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:stock_app/utils/database_helper.dart';

void main() {
  group('DatabaseHelper Tests', () {
    late DatabaseHelper dbHelper;

    setUpAll(() {
      // Initialize FFI for testing
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() {
      dbHelper = DatabaseHelper();
    });

    tearDown(() async {
      await dbHelper.clearAllData();
      await dbHelper.close();
    });

    test('should save and retrieve scanned serials', () async {
      // Test data
      const pickingLineId = 1;
      const pickingId = 100;
      const serialNumbers = ['SN001', 'SN002', 'SN003'];

      // Save serials
      await dbHelper.saveScannedSerials(
        pickingLineId: pickingLineId,
        pickingId: pickingId,
        serialNumbers: serialNumbers,
      );

      // Retrieve serials
      final retrievedSerials = await dbHelper.getScannedSerials(pickingLineId);

      // Verify
      expect(retrievedSerials, equals(serialNumbers));
      expect(retrievedSerials.length, equals(3));
    });

    test('should count scanned serials correctly', () async {
      // Test data
      const pickingLineId = 2;
      const pickingId = 200;
      const serialNumbers = ['SN004', 'SN005'];

      // Save serials
      await dbHelper.saveScannedSerials(
        pickingLineId: pickingLineId,
        pickingId: pickingId,
        serialNumbers: serialNumbers,
      );

      // Count serials
      final count = await dbHelper.getScannedSerialsCount(pickingLineId);

      // Verify
      expect(count, equals(2));
    });

    test('should replace existing serials when saving', () async {
      // Test data
      const pickingLineId = 3;
      const pickingId = 300;
      const initialSerials = ['SN006', 'SN007'];
      const updatedSerials = ['SN008', 'SN009', 'SN010'];

      // Save initial serials
      await dbHelper.saveScannedSerials(
        pickingLineId: pickingLineId,
        pickingId: pickingId,
        serialNumbers: initialSerials,
      );

      // Save updated serials (should replace)
      await dbHelper.saveScannedSerials(
        pickingLineId: pickingLineId,
        pickingId: pickingId,
        serialNumbers: updatedSerials,
      );

      // Retrieve serials
      final retrievedSerials = await dbHelper.getScannedSerials(pickingLineId);

      // Verify
      expect(retrievedSerials, equals(updatedSerials));
      expect(retrievedSerials.length, equals(3));
    });

    test('should handle empty serial lists', () async {
      // Test data
      const pickingLineId = 4;

      // Retrieve from empty database
      final retrievedSerials = await dbHelper.getScannedSerials(pickingLineId);
      final count = await dbHelper.getScannedSerialsCount(pickingLineId);

      // Verify
      expect(retrievedSerials, isEmpty);
      expect(count, equals(0));
    });
  });
}