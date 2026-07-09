import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/config/app_config.dart';
import '../core/utils/logo_url.dart';

/// AppBar title: logo when available, otherwise [AppConfig.appName].
class AppBarBrandTitle extends StatelessWidget {
  const AppBarBrandTitle({
    super.key,
    this.configLogoUrl,
    this.salesChannelLogoUrl,
    this.isLoading = false,
    this.foregroundColor,
  });

  final String? configLogoUrl;
  final String? salesChannelLogoUrl;
  final bool isLoading;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final logoUrl = LogoUrl.resolve(
      configLogoUrl: configLogoUrl,
      salesChannelLogoUrl: salesChannelLogoUrl,
    );

    if (isLoading && logoUrl == null) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: foregroundColor,
        ),
      );
    }

    if (logoUrl != null) {
      return SizedBox(
        height: 36,
        child: CachedNetworkImage(
          imageUrl: logoUrl,
          fit: BoxFit.contain,
          fadeInDuration: const Duration(milliseconds: 200),
          placeholder: (_, __) => SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: foregroundColor,
            ),
          ),
          errorWidget: (_, __, ___) => _titleText(),
          httpHeaders: const {'Accept': 'image/*'},
        ),
      );
    }

    return _titleText();
  }

  Widget _titleText() => Text(
        AppConfig.appName,
        style: const TextStyle(fontSize: 18),
        overflow: TextOverflow.ellipsis,
      );
}
