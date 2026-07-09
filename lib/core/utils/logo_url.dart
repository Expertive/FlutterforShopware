import '../config/app_config.dart';

/// Resolves and normalizes logo URLs from config / sales channel sources.
class LogoUrl {
  LogoUrl._();

  static String? resolve({
    String? configLogoUrl,
    String? salesChannelLogoUrl,
  }) {
    final raw = AppConfig.logoUrl ?? configLogoUrl ?? salesChannelLogoUrl;
    if (raw == null || raw.isEmpty) return null;

    var logoUrl = raw;
    if (logoUrl.startsWith('/') ||
        (!logoUrl.startsWith('http://') && !logoUrl.startsWith('https://'))) {
      var baseUrl = AppConfig.baseUrl;
      if (baseUrl.endsWith('/store-api')) {
        baseUrl = baseUrl.replaceAll('/store-api', '');
      }
      if (baseUrl.endsWith('/public')) {
        baseUrl = baseUrl.replaceAll('/public', '');
      }
      if (baseUrl.endsWith('/')) {
        baseUrl = baseUrl.substring(0, baseUrl.length - 1);
      }
      logoUrl = logoUrl.startsWith('/')
          ? '$baseUrl$logoUrl'
          : '$baseUrl/$logoUrl';
    }
    return logoUrl;
  }
}
