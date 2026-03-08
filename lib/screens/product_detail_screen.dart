import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../core/models/product.dart';
import '../core/services/shopware_api.dart';
import '../data/repositories/cart_repository.dart';
import '../core/storage.dart';
import '../core/config/app_config.dart';
import '../core/api_client.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ShopwareApi _api = ShopwareApi();
  final CartRepository _cartRepo = CartRepository();

  Product? _product;
  List<Map<String, dynamic>> _configurator = [];
  Map<String, String> _selectedOptions = {}; // groupId -> optionId
  String? _selectedVariantId;
  bool _isLoading = true;
  String? _error;
  late Color _primaryColor;

  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  void initState() {
    super.initState();
    // Start default color
    _primaryColor = _hexToColor(AppConfig.primaryColorHex);
    _loadPrimaryColor();
    _loadProduct();
  }

  Future<void> _loadPrimaryColor() async {
    try {
      final config = await _api.getFlutterConfig();
      final primaryColorStr =
          config['primaryColor'] as String? ?? AppConfig.primaryColorHex;
      if (mounted) {
        setState(() {
          _primaryColor = _hexToColor(primaryColorStr);
        });
      }
    } catch (e) {
      // Use default color if error occurs
      if (mounted) {
        setState(() {
          _primaryColor = _hexToColor(AppConfig.primaryColorHex);
        });
      }
    }
  }

  Color _hexToColor(String hex) {
    try {
      hex = hex.replaceAll('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      return Colors.blue;
    }
  }

  Future<void> _loadProduct() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Check UUID format and if necessary find the actual UUID
      final isUuid = RegExp(r'^[0-9a-f]{32}$', caseSensitive: false)
          .hasMatch(widget.productId);
      String actualProductId = widget.productId;

      if (!isUuid) {
        try {
          final dio = ApiClient.instance.dio;
          final searchResponse = await dio.post(
            '/store-api/search',
            data: {
              'search': widget.productId,
              'limit': 1,
            },
          );

          final elements = searchResponse.data['elements'] as List? ?? [];
          if (elements.isNotEmpty) {
            final product = elements.first as Map<String, dynamic>;
            actualProductId = product['id'] as String? ?? widget.productId;
          }
        } catch (searchError) {
          // Product search error
          // Product search error, use original ID (will error but try)
        }
      }

      // Product detail by POST method for configurator information
      final dio = ApiClient.instance.dio;
      final response = await dio.post(
        '/store-api/product/$actualProductId',
        data: const {},
      );

      final productData = response.data as Map<String, dynamic>;
      final productJson =
          productData['product'] as Map<String, dynamic>? ?? productData;

      final product = Product.fromJson(productJson);
      final configurator = productData['configurator'] as List? ?? [];

      setState(() {
        _product = product;
        _configurator = List<Map<String, dynamic>>.from(
          configurator.map((e) => Map<String, dynamic>.from(e as Map)),
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _selectVariantOption(String groupId, String optionId) async {
    setState(() {
      _selectedOptions[groupId] = optionId;
    });

    // Tüm seçenekler seçildiyse varyantı bul
    if (_selectedOptions.length == _configurator.length) {
      try {
        final result = await _api.findProductVariant(
          productId: widget.productId,
          options: _selectedOptions,
        );

        final foundCombination =
            result['foundCombination'] as Map<String, dynamic>?;
        final variantId = foundCombination?['variantId']?.toString();

        if (variantId != null) {
          // Variant found, reload product
          setState(() {
            _selectedVariantId = variantId;
          });
          await _loadProduct();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Variant not found: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        title: Text(
          AppConfig.appName,
          style: const TextStyle(fontSize: 18),
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _handleBack(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.go('/search'),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading product information...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Error: $_error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProduct,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_product == null) {
      return const Center(
        child: Text('Product not found'),
      );
    }

    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image - Modern Hero Section
          Container(
            height: 400,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.grey[50]!,
                  Colors.white,
                ],
              ),
            ),
            child: _product!.imageUrl != null
                ? Stack(
                    children: [
                      Center(
                        child: CachedNetworkImage(
                          imageUrl: _product!.imageUrl!,
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: 400,
                          placeholder: (context, url) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.grey[200]!,
                                  Colors.grey[300]!,
                                ],
                              ),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.grey[200]!,
                                  Colors.grey[300]!,
                                ],
                              ),
                            ),
                            child: Icon(
                              Icons.image_not_supported_rounded,
                              color: Colors.grey[400],
                              size: 64,
                            ),
                          ),
                        ),
                      ),
                      // Availability Badge
                      if (!_product!.available)
                        Positioned(
                          top: 16,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red[600],
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.close,
                                    color: Colors.white, size: 16),
                                SizedBox(width: 4),
                                Text(
                                  'Out of Stock',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  )
                : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.grey[200]!,
                          Colors.grey[300]!,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.image_not_supported_rounded,
                        color: Colors.grey[400],
                        size: 64,
                      ),
                    ),
                  ),
          ),

          // Product Information - Modern Card Design
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Name
                Text(
                  _product!.name,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -0.5,
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 12),

                // Price and Stock Status Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      NumberFormat.currency(
                        locale: 'de_DE',
                        symbol: '€',
                        decimalDigits: 2,
                      ).format(_product!.price),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                        letterSpacing: -1,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStockColor(_product!.availableStock)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getStockColor(_product!.availableStock),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _product!.available
                                ? Icons.check_circle_rounded
                                : Icons.cancel_rounded,
                            color: _getStockColor(_product!.availableStock),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _getStockStatusText(_product!.availableStock),
                            style: TextStyle(
                              color: _getStockColor(_product!.availableStock),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Variant Selection
                if (_configurator.isNotEmpty) ...[
                  Text(
                    'Variant Selection',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._configurator.map((group) => _buildVariantGroup(group)),
                  const SizedBox(height: 24),
                ],

                // Description - Modern Card
                if (_product!.description.isNotEmpty) ...[
                  Text(
                    'Product Description',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _product!.description,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: Colors.grey[800],
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Categories - Modern Chips
                if (_product!.categories.isNotEmpty) ...[
                  Text(
                    'Categories',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10.0,
                    runSpacing: 10.0,
                    children: _product!.categories.map((category) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              theme.colorScheme.primary.withOpacity(0.1),
                              theme.colorScheme.primary.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.primary.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),

          // Cross-Selling Bölümü
          const SizedBox(height: 24),
          _buildCrossSelling(),
        ],
      ),
    );
  }

  Widget _buildCrossSelling() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _api.getCrossSelling(widget.productId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final crossSellings = snapshot.data!;
        final allProducts = <Map<String, dynamic>>[];

        for (final crossSelling in crossSellings) {
          final products = crossSelling['products'] as List? ?? [];
          allProducts
              .addAll(products.map((p) => Map<String, dynamic>.from(p as Map)));
        }

        if (allProducts.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Related Products',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 280,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: allProducts.length,
                itemBuilder: (context, index) {
                  final productData = allProducts[index];
                  final productId = productData['id']?.toString() ?? '';
                  final productName = productData['name']?.toString() ?? '';
                  final calculatedPrice =
                      productData['calculatedPrice'] as Map<String, dynamic>?;
                  final price = calculatedPrice?['unitPrice'] as num? ?? 0.0;
                  final cover = productData['cover'] as Map<String, dynamic>?;
                  final coverUrl = cover?['media']?['url']?.toString();

                  String? imageUrl;
                  if (coverUrl != null) {
                    imageUrl =
                        coverUrl.startsWith('http') || coverUrl.startsWith('//')
                            ? coverUrl
                            : '${AppConfig.baseUrl}$coverUrl';
                  }

                  return SizedBox(
                    width: 200,
                    child: Card(
                      margin: const EdgeInsets.only(right: 12),
                      child: InkWell(
                        onTap: () {
                          context.push('/product/$productId');
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (imageUrl != null)
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                                child: CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  width: 200,
                                  height: 150,
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) =>
                                      Container(
                                    width: 200,
                                    height: 150,
                                    color: Colors.grey[300],
                                    child:
                                        const Icon(Icons.image_not_supported),
                                  ),
                                ),
                              )
                            else
                              Container(
                                width: 200,
                                height: 150,
                                color: Colors.grey[300],
                                child: const Icon(Icons.image_not_supported),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    productName,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    NumberFormat.currency(
                                      symbol: '€',
                                      decimalDigits: 2,
                                    ).format(price),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: _primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildVariantGroup(Map<String, dynamic> group) {
    final groupId = group['id']?.toString() ?? '';
    final groupName = group['name']?.toString() ?? 'Seçenek';
    final options = group['options'] as List? ?? [];
    final selectedOptionId = _selectedOptions[groupId];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            groupName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: options.map((option) {
              final optionId = option['id']?.toString() ?? '';
              final optionName = option['name']?.toString() ?? '';
              final isSelected = selectedOptionId == optionId;
              final colorHex = option['colorHexCode']?.toString();

              return InkWell(
                onTap: () => _selectVariantOption(groupId, optionId),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _primaryColor.withOpacity(0.1)
                        : Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? _primaryColor : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (colorHex != null && colorHex.isNotEmpty) ...[
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: _hexToColor(colorHex),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        optionName,
                        style: TextStyle(
                          color: isSelected ? _primaryColor : Colors.black87,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    if (_product == null || !_product!.available) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    // Login check
                    final token =
                        await TokenStorage.instance.loadContextToken();
                    if (token == null || token.isEmpty) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Please log in'),
                            backgroundColor: Colors.orange,
                            duration: const Duration(seconds: 3),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            action: SnackBarAction(
                              label: 'Log In',
                              textColor: Colors.white,
                              onPressed: () {
                                context.go('/login');
                              },
                            ),
                          ),
                        );
                      }
                      return;
                    }

                    // If logged in, add to cart
                    try {
                      final productIdToAdd =
                          _selectedVariantId ?? widget.productId;
                      await _cartRepo.addProduct(
                          productId: productIdToAdd, quantity: 1);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${_product!.name} added to cart'),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.shopping_cart_outlined, size: 20),
                  label: const Text('Add to Cart'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: IconButton(
                  onPressed: () => context.go('/cart'),
                  icon: Stack(
                    children: [
                      const Icon(
                        Icons.shopping_bag_outlined,
                        size: 24,
                        color: Colors.black87,
                      ),
                    ],
                  ),
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    minimumSize: const Size(56, 56),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Return color based on stock status
  /// If less than 0, return red, if 1, return yellow, if greater than 1, return green
  Color _getStockColor(int? availableStock) {
    if (availableStock == null) {
      // If stock information is not available, return green (current behavior)
      return Colors.green;
    }

    if (availableStock < 0) {
      return Colors.red;
    } else if (availableStock == 0) {
      return Colors.red;
    } else if (availableStock == 1) {
      return Colors.yellow;
    } else {
      return Colors.green;
    }
  }

  /// Return text based on stock status
  String _getStockStatusText(int? availableStock) {
    if (availableStock == null) {
      return 'In Stock';
    }

    if (availableStock < 0) {
      return 'Out of Stock';
    } else if (availableStock == 0) {
      return 'Out of Stock';
    } else if (availableStock == 1) {
      return 'Last 1 Item';
    } else {
      return 'In Stock';
    }
  }
}
