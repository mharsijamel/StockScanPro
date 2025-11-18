/// Asset paths for the Odoo Stock Viewer app
/// 
/// This class contains all asset paths used in the application.
/// It helps maintain consistency and makes it easier to manage assets.
class Assets {
  Assets._(); // Private constructor to prevent instantiation

  // Base paths
  static const String _imagesPath = 'assets/images';
  static const String _iconsPath = 'assets/icons';

  // Images
  static const String stockViewerLogo = '$_imagesPath/stock_viewer_logo.png';
  static const String splashLogo = '$_imagesPath/splash_logo.png';
  static const String appLogo = '$_imagesPath/app_logo.png';
  static const String placeholderImage = '$_imagesPath/placeholder.png';

  // Icons
  static const String inventoryIcon = '$_iconsPath/inventory.svg';
  static const String scanIcon = '$_iconsPath/scan.svg';
  static const String syncIcon = '$_iconsPath/sync.svg';
  static const String settingsIcon = '$_iconsPath/settings.svg';

  // Helper method to check if an asset exists
  static String getImagePath(String imageName) {
    return '$_imagesPath/$imageName';
  }

  static String getIconPath(String iconName) {
    return '$_iconsPath/$iconName';
  }
}

/// Usage examples:
/// 
/// ```dart
/// // Using predefined assets
/// Image.asset(Assets.appLogo)
/// 
/// // Using helper methods
/// Image.asset(Assets.getImagePath('my_image.png'))
/// ```