/// Copy this file to `app_config.dart` for local development,
/// or pass all values via --dart-define at build time (recommended for production).
///
/// Example:
/// flutter run \
///   --dart-define=SHOPWARE_BASE_URL=https://shop.example.com/ \
///   --dart-define=SHOPWARE_SALES_CHANNEL_ID=your32charhexid \
///   --dart-define=MOBILE_APP_SECRET=your-secret

class AppConfig {
  AppConfig._();

  static String baseUrl = const String.fromEnvironment(
    'SHOPWARE_BASE_URL',
    defaultValue: 'https://shop.example.com/',
  );

  static const String mobileSalesChannelId = String.fromEnvironment(
    'SHOPWARE_SALES_CHANNEL_ID',
    defaultValue: '',
  );

  static const String mobileAppSecret = String.fromEnvironment(
    'MOBILE_APP_SECRET',
    defaultValue: '',
  );

  static String salesChannelAccessKey = '';

  static String salesChannelDomain = const String.fromEnvironment(
    'SHOPWARE_SALES_CHANNEL_DOMAIN',
    defaultValue: 'Storefront',
  );

  static String primaryColorHex = '#1976D2';

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 20);

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

  static const String layoutEndpoint = '/store-api/flutter/layout';
  static const String productsEndpoint = '/store-api/product';
  static const String categoriesEndpoint = '/store-api/category';

  static String appName = 'FlutterforShopware';
  static String defaultHomePageId = '';
  static String? logoUrl;

  static const int cacheExpirationMinutes = 30;
  static const int maxCacheSize = 100;

  static const double defaultPadding = 16.0;
  static const double cardElevation = 2.0;
  static const double borderRadius = 8.0;

  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  static const primaryColor = 0xFF1976D2;
  static const secondaryColor = 0xFF03DAC6;
  static const errorColor = 0xFFB00020;
  static const surfaceColor = 0xFFFFFFFF;
  static const backgroundColor = 0xFFF5F5F5;

  static const double headingFontSize = 24.0;
  static const double subHeadingFontSize = 18.0;
  static const double bodyFontSize = 14.0;
  static const double captionFontSize = 12.0;
}
