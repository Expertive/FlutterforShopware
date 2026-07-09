import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../core/services/storefront_session_service.dart';
import '../core/utils/color_utils.dart';
import '../core/config/app_config.dart';

class StorefrontWebViewScreen extends StatefulWidget {
  const StorefrontWebViewScreen({
    super.key,
    required this.url,
    this.title = 'Shop',
  });

  final String url;
  final String title;

  @override
  State<StorefrontWebViewScreen> createState() =>
      _StorefrontWebViewScreenState();
}

class _StorefrontWebViewScreenState extends State<StorefrontWebViewScreen> {
  WebViewController? _controller;
  bool _loading = true;
  late Color _primaryColor;

  @override
  void initState() {
    super.initState();
    _primaryColor = ColorUtils.hexToColor(AppConfig.primaryColorHex);
    _initWebView();
  }

  Future<void> _initWebView() async {
    if (kIsWeb) {
      final uri = Uri.tryParse(widget.url);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      if (mounted) context.pop();
      return;
    }

    final controller = StorefrontSessionService.instance
        .createController(widget.url)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
        ),
      );

    if (mounted) {
      setState(() {
        _controller = controller;
        _loading = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(widget.title),
        backgroundColor: _primaryColor,
        foregroundColor: ColorUtils.foregroundOn(_primaryColor),
        actions: [
          if (_controller != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _controller!.reload(),
            ),
        ],
      ),
      body: _controller == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                WebViewWidget(controller: _controller!),
                if (_loading)
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
    );
  }
}
