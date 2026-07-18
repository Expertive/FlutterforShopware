class AppConfig {
  AppConfig._();

  // Shopware API Configuration - These values are loaded from the Shopware config dynamically.
  // Note: These default values are only used for the initial load.
  // The actual values are loaded from the backend from the /store-api/flutter/config endpoint.

  // Base URL for Shopware API - Single source of truth
  static String baseUrl = const String.fromEnvironment(
    'SHOPWARE_BASE_URL',
    defaultValue: 'http://localhost/shopware67/public/',
  );

  // Mobile Sales Channel ID - hardcoded, identifies which sales channel this app uses.
  // Get this from Shopware Admin → Sales Channels → (your mobile channel) → ID field.
  // Flutter uses this ID to bootstrap the access key on startup via /store-api/flutter/bootstrap.
  static const String mobileSalesChannelId = const String.fromEnvironment(
    'SHOPWARE_SALES_CHANNEL_ID',
    defaultValue: '', // Mobilx sales channel ID
  );

  // Shared secret between this app and the Shopware plugin.
  // Must match the value in Shopware Admin → Plugin Config → Mobile App Secret.
  static const String mobileAppSecret = const String.fromEnvironment(
    'MOBILE_APP_SECRET',
    defaultValue: '', // Set via --dart-define=MOBILE_APP_SECRET=your-secret
  );

  // Sales Channel Access Key - bootstrapped at startup from the backend.
  // Do NOT set this manually; it is fetched automatically using mobileSalesChannelId.
  static String salesChannelAccessKey = '';

  // Optional: sales channel domain for clarity/logging; not required for headers
  static String salesChannelDomain = const String.fromEnvironment(
    'SHOPWARE_SALES_CHANNEL_DOMAIN',
    defaultValue: 'Storefront',
  );

  // Primary color hex (e.g. #1976D2). Screens should read this and apply.
  static String primaryColorHex = '#1976D2';

  // Timeout configurations
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 20);

  // Update method for runtime configuration changes
  static void update({
    String? newBaseUrl,
    String? newSalesChannelDomain,
    String? newPrimaryColorHex,
  }) {
    if (newBaseUrl != null && newBaseUrl.isNotEmpty) {
      baseUrl = newBaseUrl;
    }
    if (newSalesChannelDomain != null && newSalesChannelDomain.isNotEmpty) {
      salesChannelDomain = newSalesChannelDomain;
    }
    if (newPrimaryColorHex != null && newPrimaryColorHex.isNotEmpty) {
      primaryColorHex = newPrimaryColorHex;
    }
  }

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
