import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
// WebView import - only for mobile platforms
// On web, we use url_launcher instead
import 'package:webview_flutter/webview_flutter.dart';

import 'shopware_api.dart';
import '../../widgets/product_slider.dart';
import '../../widgets/product_card.dart';
import '../models/product.dart';

class DynamicLayoutService {
  static final DynamicLayoutService _instance =
      DynamicLayoutService._internal();
  factory DynamicLayoutService() => _instance;
  DynamicLayoutService._internal();

  final ShopwareApi _api = ShopwareApi();

  Future<Widget?> loadLayout(String pageId, BuildContext context) async {
    try {
      // Get raw CMS data from Store API
      final cmsData = await _api.getLayout(pageId);

      // If data is empty or null, return null (fallback layout will be used)
      if (cmsData is Map && cmsData.isEmpty) {
        return null;
      }

      // If sections exist (direct Shopware CMS page structure), convert to Flutter format
      if (cmsData is Map && cmsData.containsKey('sections')) {
        return _buildWidgetFromCms(cmsData, context);
      }

      // If type and child exist (flutter/layout endpoint), use directly
      // Backend sometimes returns JSON with type/child even in error cases
      if (cmsData is Map && (cmsData.containsKey('child') || cmsData.containsKey('type'))) {
        return _buildWidget(cmsData, context);
      }

      // Invalid data - return null (fallback will be used)
      return null;
    } catch (e) {
      // Return null on error so fallback layout is used
      return null;
    }
  }

  Widget? _buildWidget(Map<String, dynamic> layoutData, BuildContext context) {
    try {
      // Simple widget builder - instead of dynamic_widget
      return _buildSimpleWidget(layoutData, context);
    } catch (e) {
      return _buildErrorWidget('Error building widget: $e');
    }
  }

  Widget? _buildWidgetFromCms(
      Map<String, dynamic> cmsData, BuildContext context) {
    try {
      // Convert CMS data to Flutter format
      return _buildSimpleWidget(cmsData, context);
    } catch (e) {
      return _buildErrorWidget('Error building widget from CMS: $e');
    }
  }

  Widget _buildSimpleWidget(
      Map<String, dynamic> layoutData, BuildContext context) {
    // Eğer type: SingleChildScrollView ise, direkt build et
    final type = layoutData['type']?.toString();
    if (type == 'SingleChildScrollView') {
      if (layoutData.containsKey('child')) {
        // SingleChildScrollView with child
        return SingleChildScrollView(
          child: _buildChild(layoutData['child'], context),
        );
      } else {
        // SingleChildScrollView without child - return empty
        return const SingleChildScrollView(
          child: SizedBox.shrink(),
        );
      }
    }

    // If type: Container and child exists, directly build the child
    if (type == 'Container' && layoutData['child'] != null) {
      // Create Container widget and put the child inside
      return SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: _buildChild(layoutData['child'], context),
        ),
      );
    }

    // Default: render CMS content only
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (layoutData['child'] != null)
              _buildChild(layoutData['child'], context)
            else if (layoutData['sections'] != null)
              ..._buildSections(layoutData['sections'], context),
          ],
        ),
      ),
    );
  }

  Widget _buildChild(dynamic child, [BuildContext? context]) {
    if (child == null) {
      return const SizedBox.shrink();
    }

    // If child is not a Map, return empty widget
    if (child is! Map<String, dynamic>) {
      return const SizedBox.shrink();
    }

    final childMap = child as Map<String, dynamic>;
    String type = childMap['type']?.toString() ?? 'Container';

    switch (type) {
      case 'SingleChildScrollView':
        // If SingleChildScrollView contains a child, build it
        if (childMap['child'] != null) {
          return SingleChildScrollView(
            child: _buildChild(childMap['child'], context),
          );
        }
        return const SingleChildScrollView(child: SizedBox.shrink());
      case 'Column':
        return _buildColumn(childMap, context);
      case 'Row':
        return _buildRow(childMap, context);
      case 'Wrap':
        return _buildWrap(childMap, context);
      case 'Stack':
        return _buildStack(childMap, context);
      case 'PageView':
        return _buildPageView(childMap, context);
      case 'YouTubeVideo':
        return _buildYouTubeVideo(childMap);
      case 'WebView':
        return _buildWebView(childMap);
      case 'ProductSlider':
        return _buildFlutterProductSlider(childMap);
      case 'ProductCard':
        return _buildProductCard(childMap, context);
      case 'NetworkImage':
        // Create NetworkImage widget
        final imageUrl = childMap['imageUrl']?.toString() ?? '';
        final widthStr = childMap['width']?.toString();
        final height = (childMap['height'] as num?)?.toDouble();
        final fitStr = childMap['fit']?.toString() ?? 'contain';

        BoxFit fit = BoxFit.contain;
        if (fitStr == 'cover') {
          fit = BoxFit.cover;
        } else if (fitStr == 'fill') {
          fit = BoxFit.fill;
        } else if (fitStr == 'fitWidth') {
          fit = BoxFit.fitWidth;
        } else if (fitStr == 'fitHeight') {
          fit = BoxFit.fitHeight;
        }

        Widget imageWidget;
        if (imageUrl.isNotEmpty) {
          final width = widthStr == 'double.infinity'
              ? double.infinity
              : (widthStr != null ? double.tryParse(widthStr) : null);
          imageWidget = CachedNetworkImage(
            imageUrl: imageUrl,
            width: width,
            height: height,
            fit: fit,
            placeholder: (context, url) => Container(
              width: width,
              height: height ?? 100,
              color: Colors.grey[200],
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => Container(
              width: width,
              height: height ?? 100,
              color: Colors.grey[300],
              child: const Icon(Icons.broken_image),
            ),
          );
        } else {
          imageWidget = Container(
            width: widthStr == 'double.infinity'
                ? double.infinity
                : (widthStr != null ? double.tryParse(widthStr) : 100),
            height: height ?? 100,
            color: Colors.grey[300],
            child: const Icon(Icons.image_not_supported),
          );
        }

        return imageWidget;
      case 'Container':
        // Container contains a child, build it
        Widget? childWidget;
        if (childMap['child'] != null) {
          childWidget = _buildChild(childMap['child'], context);
        }

        // If padding exists, apply it
        final paddingStr = childMap['padding']?.toString();
        EdgeInsets? padding;
        if (paddingStr != null && paddingStr.isNotEmpty) {
          final paddingValues = paddingStr.split(',');
          if (paddingValues.length == 4) {
            padding = EdgeInsets.only(
              left: double.tryParse(paddingValues[0]) ?? 0,
              top: double.tryParse(paddingValues[1]) ?? 0,
              right: double.tryParse(paddingValues[2]) ?? 0,
              bottom: double.tryParse(paddingValues[3]) ?? 0,
            );
          }
        }

        // Width and height control
        final widthStr = childMap['width']?.toString();
        final height = (childMap['height'] as num?)?.toDouble();
        final width = widthStr == 'double.infinity'
            ? double.infinity
            : (widthStr != null ? double.tryParse(widthStr) : null);

        // Decoration control (for bubble)
        BoxDecoration? decoration;
        final decorationData = childMap['decoration'];
        if (decorationData is Map) {
          final shape = decorationData['shape']?.toString();
          final colorStr = decorationData['color']?.toString();

          Color? decorationColor;
          if (colorStr != null && colorStr.isNotEmpty) {
            decorationColor = _parseColor(colorStr);
          }

          if (shape == 'circle') {
            decoration = BoxDecoration(
              shape: BoxShape.circle,
              color: decorationColor,
            );
          } else if (decorationColor != null) {
            decoration = BoxDecoration(
              color: decorationColor,
            );
          }
        }

        return Container(
          width: width,
          height: height,
          padding: padding,
          decoration: decoration,
          clipBehavior: decorationData is Map &&
                  decorationData['clipBehavior'] == 'antiAlias'
              ? Clip.antiAlias
              : Clip.none,
          child: childWidget,
        );
      case 'Text':
        // Create Text widget
        final data = childMap['data']?.toString() ?? '';

        // If error message contains, show special error widget
        if (data.contains('Layout yüklenirken hata oluştu') ||
            data.contains('Warning:') ||
            data.contains('Error:')) {
          return Container(
            padding: const EdgeInsets.all(16.0),
            margin: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              border: Border.all(color: Colors.orange[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.orange[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Layout Loading Error',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[900],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'An error occurred on the backend. Please try again later.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.orange[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Technical Details: $data',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          );
        }

        // Style control
        final styleData = childMap['style'];
        TextStyle textStyle = const TextStyle(
          fontSize: 16,
          color: Colors.black87,
        );

        if (styleData is Map) {
          textStyle = TextStyle(
            fontSize: (styleData['fontSize'] as num?)?.toDouble() ?? 16.0,
            fontWeight: styleData['fontWeight']?.toString() == 'bold'
                ? FontWeight.bold
                : FontWeight.normal,
            fontStyle: styleData['fontStyle']?.toString() == 'italic'
                ? FontStyle.italic
                : FontStyle.normal,
            color:
                _parseColor(styleData['color']?.toString()) ?? Colors.black87,
          );
        }

        TextAlign textAlign = TextAlign.left;
        if (styleData is Map) {
          final alignStr = styleData['textAlign']?.toString();
          if (alignStr == 'center') {
            textAlign = TextAlign.center;
          } else if (alignStr == 'right') {
            textAlign = TextAlign.right;
          } else if (alignStr == 'justify') {
            textAlign = TextAlign.justify;
          }
        }

        return Text(
          data,
          style: textStyle,
          textAlign: textAlign,
        );
      default:
        // Unknown widget type
        return Container();
    }
  }

  Widget _buildColumn(Map<String, dynamic> columnData,
      [BuildContext? context]) {
    List<Widget> children = [];

    // children field should be an array
    final childrenData = columnData['children'];

    if (childrenData != null) {
      List<dynamic> childrenList;
      if (childrenData is List) {
        childrenList = childrenData;
      } else {
        childrenList = [];
      }

      // Build each child recursively
      for (var i = 0; i < childrenList.length; i++) {
        final child = childrenList[i];
        if (child is Map<String, dynamic>) {
          final widget = _buildChild(child, context);
          children.add(widget);
        }
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _buildRow(Map<String, dynamic> rowData, [BuildContext? context]) {
    List<Widget> children = [];

    // children field should be an array
    final childrenData = rowData['children'];
    if (childrenData != null) {
      List<dynamic> childrenList;
      if (childrenData is List) {
        childrenList = childrenData;
      } else {
        childrenList = [];
      }

      // Build each child recursively and wrap with Expanded to prevent overflow
      for (var child in childrenList) {
        if (child is Map<String, dynamic>) {
          // Wrap children with Expanded to prevent overflow
          children.add(
            Expanded(
              child: _buildChild(child, context),
            ),
          );
        }
      }
    }

    // mainAxisAlignment control
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start;
    final mainAxisStr = rowData['mainAxisAlignment']?.toString();
    if (mainAxisStr == 'spaceEvenly') {
      mainAxisAlignment = MainAxisAlignment.spaceEvenly;
    } else if (mainAxisStr == 'spaceBetween') {
      mainAxisAlignment = MainAxisAlignment.spaceBetween;
    } else if (mainAxisStr == 'spaceAround') {
      mainAxisAlignment = MainAxisAlignment.spaceAround;
    } else if (mainAxisStr == 'center') {
      mainAxisAlignment = MainAxisAlignment.center;
    } else if (mainAxisStr == 'end') {
      mainAxisAlignment = MainAxisAlignment.end;
    }

    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _buildWrap(Map<String, dynamic> wrapData, [BuildContext? context]) {
    List<Widget> children = [];

    // children field should be an array
    final childrenData = wrapData['children'];
    if (childrenData != null) {
      List<dynamic> childrenList;
      if (childrenData is List) {
        childrenList = childrenData;
      } else {
        childrenList = [];
      }

      // Build each child recursively
      for (var child in childrenList) {
        if (child is Map<String, dynamic>) {
          children.add(_buildChild(child, context));
        }
      }
    }

    final spacing = (wrapData['spacing'] as num?)?.toDouble() ?? 8.0;
    final runSpacing = (wrapData['runSpacing'] as num?)?.toDouble() ?? 8.0;

    WrapAlignment alignment = WrapAlignment.start;
    final alignmentStr = wrapData['alignment']?.toString();
    if (alignmentStr == 'center') {
      alignment = WrapAlignment.center;
    } else if (alignmentStr == 'end') {
      alignment = WrapAlignment.end;
    }

    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      alignment: alignment,
      children: children,
    );
  }

  Color? _parseColor(String? colorStr) {
    if (colorStr == null || colorStr.isEmpty) {
      return null;
    }

    // Hex color (#RRGGBB or #AARRGGBB)
    if (colorStr.startsWith('#')) {
      try {
        final hex = colorStr.substring(1);
        if (hex.length == 6) {
          return Color(int.parse('FF$hex', radix: 16));
        } else if (hex.length == 8) {
          return Color(int.parse(hex, radix: 16));
        }
      } catch (e) {
        // Color parse error
      }
    }

    // Named colors
    switch (colorStr.toLowerCase()) {
      case 'black':
        return Colors.black;
      case 'white':
        return Colors.white;
      case 'red':
        return Colors.red;
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      default:
        return null;
    }
  }

  Widget _buildStack(Map<String, dynamic> stackData, [BuildContext? context]) {
    List<Widget> children = [];

    // children field should be an array
    final childrenData = stackData['children'];
    if (childrenData != null) {
      List<dynamic> childrenList;
      if (childrenData is List) {
        childrenList = childrenData;
      } else {
        childrenList = [];
      }

      // Build each child recursively
      for (var child in childrenList) {
        if (child is Map<String, dynamic>) {
          children.add(_buildChild(child, context));
        }
      }
    }

    // Alignment control
    AlignmentGeometry alignment = Alignment.center;
    final alignmentStr = stackData['alignment']?.toString();
    if (alignmentStr == 'topLeft') {
      alignment = Alignment.topLeft;
    } else if (alignmentStr == 'topCenter') {
      alignment = Alignment.topCenter;
    } else if (alignmentStr == 'topRight') {
      alignment = Alignment.topRight;
    } else if (alignmentStr == 'centerLeft') {
      alignment = Alignment.centerLeft;
    } else if (alignmentStr == 'center') {
      alignment = Alignment.center;
    } else if (alignmentStr == 'centerRight') {
      alignment = Alignment.centerRight;
    } else if (alignmentStr == 'bottomLeft') {
      alignment = Alignment.bottomLeft;
    } else if (alignmentStr == 'bottomCenter') {
      alignment = Alignment.bottomCenter;
    } else if (alignmentStr == 'bottomRight') {
      alignment = Alignment.bottomRight;
    }

    return Stack(
      alignment: alignment,
      children: children,
    );
  }

  Widget _buildPageView(Map<String, dynamic> pageViewData,
      [BuildContext? context]) {
    List<Widget> children = [];

    // children field should be an array
    final childrenData = pageViewData['children'];
    if (childrenData != null) {
      List<dynamic> childrenList;
      if (childrenData is List) {
        childrenList = childrenData;
      } else {
        childrenList = [];
      }

      // Build each child recursively
      for (var child in childrenList) {
        if (child is Map<String, dynamic>) {
          children.add(_buildChild(child, context));
        }
      }
    }

    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 300,
      child: PageView(
        children: children,
      ),
    );
  }

  Widget _buildYouTubeVideo(Map<String, dynamic> videoData) {
    final videoId = videoData['videoId']?.toString() ?? '';
    if (videoId.isEmpty) {
      return const SizedBox.shrink();
    }

    final autoPlay = videoData['autoPlay'] == true;
    final loop = videoData['loop'] == true;
    final showControls = videoData['showControls'] != false; // Default true
    final start = videoData['start'] as int?;
    final end = videoData['end'] as int?;

    final widthStr = videoData['width']?.toString();
    final height = (videoData['height'] as num?)?.toDouble() ?? 200.0;
    final width = widthStr == 'double.infinity'
        ? double.infinity
        : (widthStr != null ? double.tryParse(widthStr) : null);

    // YouTube embed URL oluşt  ur
    final params = <String>[];
    if (autoPlay) params.add('autoplay=1');
    if (loop)
      params.add(
          'loop=1&playlist=$videoId'); // For loop, playlist parameter is required
    if (showControls) params.add('controls=1');
    if (!showControls) params.add('controls=0');
    if (start != null && start > 0) params.add('start=$start');
    if (end != null && end > 0) params.add('end=$end');

    final youtubeUrl =
        'https://www.youtube.com/embed/$videoId?${params.join('&')}';

    // On web platform, use link button instead of WebView
    if (kIsWeb) {
      return Container(
        width: width,
        height: height,
        padding: const EdgeInsets.all(8.0),
        child: Card(
          child: InkWell(
            onTap: () async {
              final uri = Uri.parse('https://www.youtube.com/watch?v=$videoId');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            child: Container(
              width: double.infinity,
              height: double.infinity,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_circle_filled, size: 48, color: Colors.red),
                  const SizedBox(height: 8),
                  const Text(
                    'Watch on YouTube',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Mobile platform - use WebView
    try {
      // Create WebView controller
      final controller = WebViewController();
      controller
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (String url) {
              // YouTube video loaded
            },
          ),
        )
        ..loadRequest(Uri.parse(youtubeUrl));

      return Container(
        width: width,
        height: height,
        padding: const EdgeInsets.all(8.0),
        child: WebViewWidget(controller: controller),
      );
    } catch (e) {
      // WebView initialization error - show fallback
      return Container(
        width: width,
        height: height,
        padding: const EdgeInsets.all(8.0),
        child: Card(
          child: Center(
            child: Text('YouTube Error: $e'),
          ),
        ),
      );
    }
  }

  Widget _buildWebView(Map<String, dynamic> webViewData) {
    final url = webViewData['url']?.toString() ?? '';
    if (url.isEmpty) {
      return const SizedBox.shrink();
    }

    final widthStr = webViewData['width']?.toString();
    final height = (webViewData['height'] as num?)?.toDouble() ?? 200.0;
    final width = widthStr == 'double.infinity'
        ? double.infinity
        : (widthStr != null ? double.tryParse(widthStr) : null);

    // On web platform, use a link button instead of WebView
    if (kIsWeb) {
      return Container(
        width: width,
        height: height,
        padding: const EdgeInsets.all(8.0),
        child: Card(
          child: InkWell(
            onTap: () async {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            child: Container(
              width: double.infinity,
              height: double.infinity,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.open_in_browser, size: 48, color: Colors.blue),
                  const SizedBox(height: 8),
                  Text(
                    'Open in Browser',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    url,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Mobile platform - use WebView
    try {
      // Create WebView controller
      final controller = WebViewController();
      controller
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (String url) {
              // WebView page finished
            },
          ),
        )
        ..loadRequest(Uri.parse(url));

      return Container(
        width: width,
        height: height,
        padding: const EdgeInsets.all(8.0),
        child: WebViewWidget(controller: controller),
      );
    } catch (e) {
      // WebView initialization error - show fallback
      return Container(
        width: width,
        height: height,
        padding: const EdgeInsets.all(8.0),
        child: Card(
          child: Center(
            child: Text('WebView Error: $e'),
          ),
        ),
      );
    }
  }

  Widget _buildFlutterProductSlider(Map<String, dynamic> sliderData) {
    List<dynamic> products = [];
    String? streamId;

    if (sliderData.containsKey('products')) {
      final productsData = sliderData['products'];

      if (productsData is List) {
        // If it comes as a direct list, use it
        products = productsData;
      } else if (productsData is Map) {
        // If products is a Map, check for product stream
        if (productsData['source'] == 'product_stream') {
          // Product stream - need to fetch products asynchronously
          streamId = productsData['value']?.toString();
        } else {
          // For other Map formats, check for list inside
          if (productsData.containsKey('elements')) {
            products = productsData['elements'] as List? ?? [];
          } else if (productsData.containsKey('items')) {
            products = productsData['items'] as List? ?? [];
          } else if (productsData.containsKey('data')) {
            products = productsData['data'] as List? ?? [];
          }
        }
      }
    }

    // If product stream exists, fetch products asynchronously and enrich with images
    if (streamId != null && streamId.isNotEmpty) {
      return FutureBuilder<List<Product>>(
        future: _getProductsWithDetailsFromStream(
          streamId,
          limit: 20,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SizedBox(
              height: sliderData['height']?.toDouble() ?? 280,
              child: const Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError) {
            return const SizedBox.shrink();
          }

          final detailedProducts = snapshot.data ?? [];

          if (detailedProducts.isEmpty) {
            return const SizedBox.shrink();
          }

          // ProductSlider şu an Map listesi beklediği için, Product'ları toJson ile geri Map'e çeviriyoruz.
          final productsWithImages =
              detailedProducts.map((p) => p.toJson()).toList();

          return ProductSlider(
            products: streamProducts,
            height: sliderData['height']?.toDouble() ?? 280,
          );
        },
      );
    }

    // If direct products list exists, use it
    if (products.isEmpty) {
      return const SizedBox.shrink();
    }

    return ProductSlider(
      products: products,
      title: sliderData['title'] as String?,
      height: sliderData['height']?.toDouble() ?? 280,
    );
  }

  /// Product stream'den gelen basit ürün listesi için,
  /// her ürünün detayını `/store-api/product/{id}` ile çekip
  /// imageUrl gibi alanları doldurur.
  Future<List<Product>> _getProductsWithDetailsFromStream(
    String streamId, {
    int limit = 20,
  }) async {
    try {
      final streamProducts =
          await _api.getProductsFromStream(streamId, limit: limit);

      if (streamProducts.isEmpty) {
        return [];
      }

      final futures = streamProducts.map((p) async {
        final id = p['id']?.toString();
        if (id == null || id.isEmpty) {
          return null;
        }
        try {
          return await _api.getProduct(id);
        } catch (_) {
          return null;
        }
      }).toList();

      final results = await Future.wait(futures);
      return results.whereType<Product>().toList();
    } catch (_) {
      return [];
    }
  }

  /// Statik ürün listesi (slotData['products']) için her ürünün detayını çeker.
  Future<List<Product>> _getProductsWithDetailsFromList(
    List<dynamic> products, {
    int? limit,
  }) async {
    try {
      if (products.isEmpty) {
        return [];
      }

      final futures = products.take(limit ?? products.length).map((p) async {
        if (p is Map && p['id'] != null) {
          final id = p['id'].toString();
          if (id.isEmpty) return null;
          try {
            return await _api.getProduct(id);
          } catch (_) {
            return null;
          }
        }
        return null;
      }).toList();

      final results = await Future.wait(futures);
      return results.whereType<Product>().toList();
    } catch (_) {
      return [];
    }
  }

  Widget _buildProductCard(Map<String, dynamic> cardData,
      [BuildContext? context]) {
    // Get product data
    final productData = cardData['product'];
    if (productData == null || productData is! Map<String, dynamic>) {
      return const SizedBox.shrink();
    }

    // Create Product model
    Product product;
    try {
      product = Product.fromJson(productData);
    } catch (e) {
      // Product parse error
      return const SizedBox.shrink();
    }

    // Get width and height values
    final width = cardData['width'] != null
        ? (cardData['width'] as num?)?.toDouble()
        : null;
    final height = cardData['height'] != null
        ? (cardData['height'] as num?)?.toDouble()
        : null;

    // Create onTap callback - Use Builder to get context
    return Builder(
      builder: (builderContext) {
        VoidCallback? onTap;
        if (product.id.isNotEmpty) {
          onTap = () {
            builderContext.push('/product/${product.id}');
          };
        }

        return ProductCard(
          product: product,
          onTap: onTap,
          width: width,
          height: height,
        );
      },
    );
  }

  Widget _buildInfoCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSections(List<dynamic> sections, BuildContext context) {
    List<Widget> widgets = [];

    for (var section in sections) {
      widgets.add(_buildSection(section, context));
      widgets.add(const SizedBox(height: 16));
    }

    return widgets;
  }

  Widget _buildSection(Map<String, dynamic> section, BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.view_module, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text(
                'Section: ${section['type'] ?? 'default'}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (section['blocks'] != null) ...[
            ..._buildBlocks(section['blocks']),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildBlocks(List<dynamic> blocks) {
    List<Widget> widgets = [];

    for (var block in blocks) {
      widgets.add(_buildBlock(block));
      widgets.add(const SizedBox(height: 12));
    }

    return widgets;
  }

  Widget _buildBlock(Map<String, dynamic> block) {
    String blockType = block['type'] ?? 'unknown';

    switch (blockType) {
      case 'text':
        return _buildTextBlock(block);
      case 'product-slider':
        return _buildProductSliderBlock(block);
      default:
        return _buildGenericBlock(block);
    }
  }

  Widget _buildTextBlock(Map<String, dynamic> block) {
    String content = '';

    // Find text content
    if (block['slots'] != null && block['slots'].isNotEmpty) {
      var slot = block['slots'][0];
      if (slot['data'] != null && slot['data']['content'] != null) {
        content = slot['data']['content'];
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border.all(color: Colors.blue.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.text_fields, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text(
                'Text Block',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (content.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                _cleanHtmlContent(content),
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ] else ...[
            const Text(
              'İçerik bulunamadı',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductSliderBlock(Map<String, dynamic> block) {
    // Get products from slot
    List<dynamic> products = [];
    String? title;

    if (block['slots'] != null && block['slots'].isNotEmpty) {
      var slot = block['slots'][0];
      var slotData = slot['data'];

      if (slotData != null && slotData['products'] != null) {
        products = List<dynamic>.from(slotData['products']);
      }

      // Get title
      var config = slot['config'];
      if (config != null && config['title'] != null) {
        title = config['title']['value'] as String?;
      }
    }

    // If no products, return empty container
    if (products.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        child: const Text(
          'No products found',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null && title.isNotEmpty) ...[
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        ProductSlider(
          products: products,
          height: 280,
        ),
      ],
    );
  }

  Widget _buildProductSliderConfig(Map<String, dynamic> slot) {
    var config = slot['config'] ?? {};

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildConfigItem(
              'Product Stream ID', config['products']?['value'] ?? 'None'),
          _buildConfigItem('Title', config['title']?['value'] ?? 'None'),
          _buildConfigItem(
              'Display Mode', config['displayMode']?['value'] ?? 'None'),
          _buildConfigItem(
              'Box Layout', config['boxLayout']?['value'] ?? 'None'),
          _buildConfigItem('Product Count',
              config['productStreamLimit']?['value']?.toString() ?? 'None'),
        ],
      ),
    );
  }

  Widget _buildConfigItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenericBlock(Map<String, dynamic> block) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.widgets, color: Colors.grey, size: 20),
              const SizedBox(width: 8),
              Text(
                'Block: ${block['type'] ?? 'unknown'}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'This block type is not yet supported',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  String _cleanHtmlContent(String htmlContent) {
    // Simple HTML cleaning
    return htmlContent
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildErrorWidget(String message) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
