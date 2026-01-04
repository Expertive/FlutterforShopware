// Core configuration for API endpoints and timeouts
class AppConfig {
  AppConfig._();

  // Initial baseUrl comes from app_config.dart; can be overridden by env or runtime update
  static String baseUrl = const String.fromEnvironment(
    'SHOPWARE_BASE_URL',
    defaultValue: 'http://localhost/shopware67/public/',
  );

  // Optional: sales channel domain for clarity/logging; not required for headers
  static String salesChannelDomain = const String.fromEnvironment(
    'SHOPWARE_SALES_CHANNEL_DOMAIN',
    defaultValue: 'Storefront',
  );

  // Primary color hex (e.g. #1976D2). Screens should read this and apply.
  static String primaryColorHex = '#1976D2';

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 20);

  static void update(
      {String? newBaseUrl,
      String? newSalesChannelDomain,
      String? newPrimaryColorHex}) {
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
}
