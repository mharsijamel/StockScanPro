# StockScan Pro

Flutter mobile application for managing product serial numbers with Odoo 15 integration.

## 📱 Overview

StockScan Pro is a mobile application designed to streamline the process of scanning and managing product serial numbers during stock operations (IN/OUT) with seamless integration to Odoo 15 ERP system.

## 🚀 Features

- **Barcode/QR Code Scanning**: Fast and accurate serial number scanning
- **Stock IN Operations**: Receive products with duplicate SN detection
- **Stock OUT Operations**: Validate serial number existence before shipping
- **Offline Mode**: Work without internet connection with local data storage
- **Synchronization**: Bidirectional sync with Odoo 15 via REST API
- **User Authentication**: Secure login with token-based authentication
- **Multi-language Support**: French interface (expandable)

## 🏗️ Architecture

### Frontend (Flutter)
- **State Management**: Provider pattern
- **Local Database**: SQLite with sqflite
- **HTTP Client**: Dio for API communication
- **Secure Storage**: flutter_secure_storage for tokens
- **Navigation**: go_router for declarative routing

### Backend (Odoo 15)
- **Custom Module**: REST API controllers
- **Authentication**: Token-based auth system
- **Data Models**: Picking, Product, Serial Number management
- **API Endpoints**: CRUD operations for mobile app

## 📁 Project Structure

```
lib/
├── constants/          # App constants and configuration
├── models/            # Data models (Picking, Product, ScannedSn)
├── providers/         # State management providers
├── repositories/      # Data access layer
├── screens/          # UI screens
├── services/         # Business logic services
├── utils/            # Utility functions
└── widgets/          # Reusable UI components
```

## 🛠️ Setup Instructions

### Prerequisites
- Flutter SDK 3.0+
- Dart SDK 3.0+
- Android Studio / VS Code
- Odoo 15 instance with custom module

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd stock_scan_pro
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure API endpoint**
   Update `lib/constants/app_constants.dart`:
   ```dart
   static const String baseUrl = 'https://your-odoo-instance.com';
   ```

4. **Run the application**
   ```bash
   flutter run
   ```

## 📊 Database Schema

### Local SQLite Tables

#### pickings
- id (INTEGER PRIMARY KEY)
- name (TEXT)
- operation_type (TEXT) - 'in' or 'out'
- state (TEXT)
- partner_id (TEXT)
- partner_name (TEXT)
- scheduled_date (INTEGER)
- date_created (INTEGER)
- sync_status (TEXT)

#### products
- id (INTEGER PRIMARY KEY)
- name (TEXT)
- default_code (TEXT)
- barcode (TEXT)
- picking_id (INTEGER)
- quantity (REAL)
- quantity_done (REAL)
- location (TEXT)

#### scanned_sn
- id (TEXT PRIMARY KEY)
- serial_number (TEXT)
- product_id (INTEGER)
- picking_id (INTEGER)
- location (TEXT)
- scanned_at (INTEGER)
- sync_status (TEXT)

## 🔌 API Endpoints

### Authentication
- `POST /api/auth/login` - User authentication

### Pickings
- `GET /api/pickings` - Get picking list
- `GET /api/pickings/{id}` - Get picking details

### Serial Numbers
- `GET /api/serial/check` - Verify SN existence
- `POST /api/pickings/{id}/update_sn` - Update scanned SNs

## 🧪 Testing

Run tests with:
```bash
flutter test
```

## 📱 Build & Deploy

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License.

## 📞 Support

For support and questions, please contact the development team.

---

**Version**: 1.0.0  
**Last Updated**: September 2025
