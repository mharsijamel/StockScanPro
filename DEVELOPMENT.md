# StockScan Pro - Development Guide

## 🚀 Quick Start

### Prerequisites
- Flutter SDK 3.0+ (installed at `C:\dev\flutter`)
- Dart SDK 3.0+
- VS Code with Flutter/Dart extensions
- Git
- Android Studio (for Android development)
- Xcode (for iOS development, macOS only)

### Initial Setup
```powershell
# Clone and setup
git clone <repository-url>
cd StockScanPro
.\dev.ps1 setup
```

## 🛠️ Development Commands

### Using the Development Script
```powershell
# Show all available commands
.\dev.ps1 help

# Run the app
.\dev.ps1 run

# Run in web browser
.\dev.ps1 web

# Analyze code
.\dev.ps1 analyze

# Run tests
.\dev.ps1 test
```

### Manual Flutter Commands
```powershell
# Get dependencies
flutter pub get

# Run app
flutter run

# Run on web
flutter run -d web-server --web-port 3000

# Build for Android
flutter build apk --release

# Build for web
flutter build web --release
```

## 📁 Project Structure

```
lib/
├── constants/          # App constants and configuration
│   └── app_constants.dart
├── models/            # Data models
│   └── picking.dart   # Picking, Product, ScannedSn models
├── providers/         # State management (Provider pattern)
│   ├── auth_provider.dart
│   ├── sync_provider.dart
│   ├── picking_provider.dart
│   └── scanning_provider.dart
├── services/          # Business logic services
│   ├── api_service.dart
│   ├── auth_service.dart
│   ├── database_service.dart
│   └── sync_service.dart
├── screens/           # UI screens
│   ├── splash_screen.dart
│   ├── login_screen.dart
│   ├── dashboard_screen.dart
│   ├── picking_list_screen.dart
│   ├── product_list_screen.dart
│   └── scanning_screen.dart
├── widgets/           # Reusable UI components
├── repositories/      # Data access layer
├── utils/            # Utility functions
└── main.dart         # App entry point
```

## 🏗️ Architecture

### State Management
- **Provider Pattern**: Used for state management
- **Dependency Injection**: Services injected through providers
- **Separation of Concerns**: Clear separation between UI, business logic, and data

### Data Flow
1. **UI Layer**: Screens and widgets
2. **State Layer**: Providers manage application state
3. **Service Layer**: Business logic and API calls
4. **Data Layer**: Local database and remote API

### Database Schema
- **pickings**: Stock operations (IN/OUT)
- **products**: Product information
- **scanned_sn**: Scanned serial numbers with sync status

## 🔧 Development Workflow

### 1. Feature Development
```powershell
# Create feature branch
git checkout -b feature/new-feature

# Make changes
# ... code changes ...

# Test changes
.\dev.ps1 test
.\dev.ps1 analyze

# Commit changes
.\dev.ps1 commit
```

### 2. Code Quality
- **Formatting**: Use `dart format` or `.\dev.ps1 format`
- **Analysis**: Run `flutter analyze` regularly
- **Testing**: Write tests for new features
- **Documentation**: Update documentation for new features

### 3. Testing Strategy
- **Unit Tests**: Test business logic and services
- **Widget Tests**: Test UI components
- **Integration Tests**: Test complete workflows
- **Manual Testing**: Test on real devices

## 🐛 Debugging

### VS Code Debugging
1. Set breakpoints in code
2. Press F5 or use "Run and Debug" panel
3. Select appropriate launch configuration

### Flutter Inspector
- Use Flutter Inspector in VS Code
- Analyze widget tree and performance
- Debug layout issues

### Logging
```dart
import 'dart:developer' as developer;

// Use log instead of print for debugging
developer.log('Debug message', name: 'StockScanPro');
```

## 📱 Platform-Specific Development

### Android
- Minimum SDK: 21 (Android 5.0)
- Target SDK: 34
- Permissions: Camera, Internet, Storage

### iOS
- Minimum iOS: 12.0
- Permissions: Camera, Network

### Web
- Responsive design
- PWA capabilities
- Limited camera access

## 🔐 Security Considerations

- **Secure Storage**: Use flutter_secure_storage for tokens
- **API Security**: Implement proper authentication headers
- **Data Validation**: Validate all user inputs
- **HTTPS**: Use HTTPS for all API communications

## 🚀 Deployment

### Android
```powershell
# Build release APK
.\dev.ps1 build-apk

# Build App Bundle (recommended for Play Store)
flutter build appbundle --release
```

### iOS
```powershell
# Build iOS
.\dev.ps1 build-ios

# Archive in Xcode for App Store
```

### Web
```powershell
# Build web
.\dev.ps1 build-web

# Deploy to web server
# Copy build/web/ contents to web server
```

## 📚 Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Documentation](https://dart.dev/guides)
- [Provider Package](https://pub.dev/packages/provider)
- [SQLite in Flutter](https://docs.flutter.dev/cookbook/persistence/sqlite)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Update documentation
6. Submit a pull request

## 📞 Support

For development questions and issues:
- Check existing documentation
- Review code comments
- Create GitHub issues for bugs
- Contact the development team
