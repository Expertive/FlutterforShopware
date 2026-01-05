class AppConfig {
  // Shopware API Configuration - These values are loaded from the Shopware config dynamically.
  // Note: These default values are only used for the initial load.
  // The actual values are loaded from the backend from the /store-api/flutter/config endpoint.
  static String shopwareBaseUrl = 'https://demo.expertive.de/';
  // The default value in the backend config.xml should be the same.
  // This value is updated when loaded from the backend (shopware_api.dart)
  static String salesChannelAccessKey = 'SWSCR2ZZS0LEBFRETUZHTJBFNA';

  // API Endpoints
  // Layout endpoints are still coming from the plugin.
  static const String layoutEndpoint = '/store-api/flutter/layout';
  // Product and category endpoints are directly used from the Store API.
  static const String productsEndpoint = '/store-api/product';
  static const String categoriesEndpoint = '/store-api/category';

  // App Configuration - These values are loaded from the Shopware config dynamically.
  static String appName = 'FlutterforShopware';
  static String defaultHomePageId = '';
  static String? logoUrl; // The logo URL is loaded from the config.

  // Cache Configuration
  static const int cacheExpirationMinutes = 30;
  static const int maxCacheSize = 100;

  // UI Configuration
  static const double defaultPadding = 16.0;
  static const double cardElevation = 2.0;
  static const double borderRadius = 8.0;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Colors
  static const primaryColor = 0xFF1976D2;
  static const secondaryColor = 0xFF03DAC6;
  static const errorColor = 0xFFB00020;
  static const surfaceColor = 0xFFFFFFFF;
  static const backgroundColor = 0xFFF5F5F5;

  // Text Styles
  static const double headingFontSize = 24.0;
  static const double subHeadingFontSize = 18.0;
  static const double bodyFontSize = 14.0;
  static const double captionFontSize = 12.0;
}
