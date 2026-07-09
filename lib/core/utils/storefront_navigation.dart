import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens storefront and shop URLs in the in-app WebView (mobile) or browser (web).
class StorefrontNavigation {
  StorefrontNavigation._();

  static Future<void> open(
    BuildContext context,
    String url, {
    String title = 'Shop',
  }) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    if (kIsWeb) {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }

    if (!context.mounted) return;
    await context.push(
      '/storefront?url=${Uri.encodeComponent(url)}'
      '&title=${Uri.encodeComponent(title)}',
    );
  }
}
