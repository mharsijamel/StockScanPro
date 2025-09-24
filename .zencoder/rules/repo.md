---
description: Repository Information Overview
alwaysApply: true
---

# Stock Android Application Information

## Summary
A Flutter mobile application for inventory management that connects to an Odoo ERP system through a PHP backend API. The app allows users to authenticate, view picking lists, and manage stock operations.

## Structure
- **android/**: Android platform-specific code and configuration
- **api/**: PHP backend API endpoints for Odoo integration
- **common/**: Shared PHP utilities for authentication and Odoo connection
- **lib/**: Flutter application source code
  - **api/**: API service for HTTP requests
  - **models/**: Data models for the application
  - **providers/**: State management using Provider pattern
  - **screens/**: UI screens and widgets
- **vendor/**: PHP dependencies managed by Composer

## Projects

### Flutter Mobile Application
**Configuration File**: pubspec.yaml

#### Language & Runtime
**Language**: Dart
**Version**: SDK >=3.0.0 <4.0.0
**Build System**: Flutter
**Package Manager**: pub

#### Dependencies
**Main Dependencies**:
- flutter: SDK
- http: ^1.1.0 (HTTP requests)
- provider: ^6.0.5 (State management)
- shared_preferences: ^2.2.0 (Local storage)
- cupertino_icons: ^1.0.2

**Development Dependencies**:
- flutter_test: SDK
- flutter_lints: ^2.0.0

#### Build & Installation
```bash
flutter pub get
flutter build apk
```

#### Main Entry Points
**Main Application**: lib/main.dart
**Key Screens**:
- login_screen.dart (Authentication)
- home_screen.dart (Dashboard)
- picking_list_screen.dart (Inventory operations)
- picking_detail_screen.dart (Detailed view)

### PHP Backend API
**Configuration File**: composer.json

#### Language & Runtime
**Language**: PHP
**Package Manager**: Composer

#### Dependencies
**Main Dependencies**:
- phpxmlrpc/phpxmlrpc: ^4.11 (XML-RPC client for Odoo)

#### Build & Installation
```bash
composer install
```

#### Main Entry Points
**API Endpoints**:
- api/auth.php (Authentication)
- api/stock.php (Stock operations)
- api/picking_details.php (Detailed picking information)

#### Configuration
**URL Routing**: .htaccess with RewriteRules
**Token Management**: config.php (24-hour token expiration)
**Storage**: tokens.json for token persistence

### Android Configuration
**Configuration File**: android/app/build.gradle.kts

#### Language & Runtime
**Language**: Kotlin
**Java Compatibility**: JavaVersion.VERSION_11
**Build System**: Gradle

#### Build & Installation
```bash
cd android
./gradlew assembleDebug
```

## Integration Points
- Flutter app communicates with PHP backend via HTTP REST API
- PHP backend connects to Odoo ERP using XML-RPC protocol
- Authentication uses token-based system with 24-hour expiration