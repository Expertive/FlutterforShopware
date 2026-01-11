import '../config/app_config.dart';

class SalesChannelInfo {
  final String? id;
  final String? name;
  final String? logoUrl;
  final String? currencyId;
  final String? currencyIsoCode;
  final String? languageId;
  final String? languageName;
  final Map<String, dynamic>? rawData;

  SalesChannelInfo({
    this.id,
    this.name,
    this.logoUrl,
    this.currencyId,
    this.currencyIsoCode,
    this.languageId,
    this.languageName,
    this.rawData,
  });

  factory SalesChannelInfo.fromContext(Map<String, dynamic> context) {
    final salesChannel = context['salesChannel'] as Map<String, dynamic>?;
    final currency = context['currency'] as Map<String, dynamic>?;
    final language = context['language'] as Map<String, dynamic>?;

    // Logo URL'ini bul
    String? logoUrl;
    if (salesChannel != null) {
      // Logo medya bilgisi
      final logoMedia = salesChannel['logoMedia'] as Map<String, dynamic>?;
      if (logoMedia != null) {
        String? url = logoMedia['url'] as String?;
        if (url != null && url.isNotEmpty) {
          // Eğer URL relative ise base URL ile birleştir
          if (url.startsWith('/') || !url.startsWith('http')) {
            // Base URL'den store-api ve public kısmını temizle
            String baseUrl = AppConfig.baseUrl;
            if (baseUrl.endsWith('/store-api')) {
              baseUrl = baseUrl.replaceAll('/store-api', '');
            }
            if (baseUrl.endsWith('/public')) {
              baseUrl = baseUrl.replaceAll('/public', '');
            }
            if (baseUrl.endsWith('/')) {
              baseUrl = baseUrl.substring(0, baseUrl.length - 1);
            }
            logoUrl = '$baseUrl$url';
          } else {
            logoUrl = url;
          }
        } else {
          // Thumbnails'den ilkini al
          final thumbnails = logoMedia['thumbnails'] as List?;
          if (thumbnails != null && thumbnails.isNotEmpty) {
            final firstThumb = thumbnails.first as Map<String, dynamic>?;
            url = firstThumb?['url'] as String?;
            if (url != null && url.isNotEmpty) {
              // Eğer URL relative ise base URL ile birleştir
              if (url.startsWith('/') || !url.startsWith('http')) {
                // Base URL'den store-api ve public kısmını temizle
                String baseUrl = AppConfig.baseUrl;
                if (baseUrl.endsWith('/store-api')) {
                  baseUrl = baseUrl.replaceAll('/store-api', '');
                }
                if (baseUrl.endsWith('/public')) {
                  baseUrl = baseUrl.replaceAll('/public', '');
                }
                if (baseUrl.endsWith('/')) {
                  baseUrl = baseUrl.substring(0, baseUrl.length - 1);
                }
                logoUrl = '$baseUrl$url';
              } else {
                logoUrl = url;
              }
            }
          }
        }
      }
    }

    return SalesChannelInfo(
      id: salesChannel?['id']?.toString(),
      name: salesChannel?['name']?.toString(),
      logoUrl: logoUrl,
      currencyId: currency?['id']?.toString(),
      currencyIsoCode: currency?['isoCode']?.toString(),
      languageId: language?['id']?.toString(),
      languageName: language?['name']?.toString(),
      rawData: context,
    );
  }

  static SalesChannelInfo? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return SalesChannelInfo.fromContext(json);
  }
}

