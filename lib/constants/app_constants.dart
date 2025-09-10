class AppConstants {
  // App Information
  static const String appName = 'StockScan Pro';
  static const String appVersion = '1.0.0';

  // API Configuration
  // TODO: Remplacez par l'URL de votre serveur Odoo
  static const String baseUrl = 'https://smart.webvue.tn'; // Pour production
  // static const String baseUrl = 'http://localhost:8069'; // Pour développement local
  static const String apiPrefix = '/api';
  static const String authEndpoint = '/auth/login';
  static const String pickingsEndpoint = '/pickings';
  static const String serialCheckEndpoint = '/serial/check';
  static const String updateSnEndpoint = '/pickings/{id}/update_sn';

  // Database Configuration
  static const String databaseName = 'stock_scan_pro.db';
  static const int databaseVersion = 1;

  // Table Names
  static const String pickingsTable = 'pickings';
  static const String productsTable = 'products';
  static const String scannedSnTable = 'scanned_sn';

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String usernameKey = 'username';
  static const String lastSyncKey = 'last_sync';

  // Operation Types
  static const String stockIn = 'in';
  static const String stockOut = 'out';

  // Sync Status
  static const String syncPending = 'pending';
  static const String syncCompleted = 'completed';
  static const String syncFailed = 'failed';

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;

  static const double defaultBorderRadius = 8.0;
  static const double cardElevation = 2.0;

  // Colors (Material Design)
  static const int primaryColorValue = 0xFF2196F3; // Blue
  static const int accentColorValue = 0xFF4CAF50; // Green

  // Timeouts
  static const int apiTimeoutSeconds = 30;
  static const int syncIntervalMinutes = 15;

  // Validation
  static const int maxSnLength = 50;
  static const int minSnLength = 3;
  static const int maxLocationLength = 20;

  // Error Messages
  static const String networkError = 'Erreur de connexion réseau';
  static const String authError = 'Erreur d\'authentification';
  static const String syncError = 'Erreur de synchronisation';
  static const String scanError = 'Erreur de scan';
  static const String duplicateSnError = 'Numéro de série déjà scanné';
  static const String snNotFoundError = 'Numéro de série non trouvé';

  // Success Messages
  static const String loginSuccess = 'Connexion réussie';
  static const String syncSuccess = 'Synchronisation réussie';
  static const String scanSuccess = 'Scan réussi';

  // Permissions
  static const String cameraPermission = 'camera';

  // Barcode Formats
  static const List<String> supportedBarcodeFormats = [
    'CODE_128',
    'CODE_39',
    'EAN_13',
    'EAN_8',
    'QR_CODE',
    'DATA_MATRIX',
  ];
}
