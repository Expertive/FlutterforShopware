import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../core/models/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '₺',
      decimalDigits: 2,
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: height != null ? MainAxisSize.max : MainAxisSize.min,
            children: [
              // Product Image with modern styling
              height != null
                  ? Expanded(
                      flex: 3,
                      child: _buildImageContainer(),
                    )
                  : AspectRatio(
                      aspectRatio: 1.0,
                      child: _buildImageContainer(),
                    ),
              // Product Info with modern styling
              height != null
                  ? Expanded(
                      flex: 2,
                      child: _buildProductInfo(context, theme, currencyFormat),
                    )
                  : _buildProductInfo(context, theme, currencyFormat),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageContainer() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[50],
      ),
      child: product.imageUrl != null
          ? Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: product.imageUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
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
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
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
                        size: 40,
                      ),
                    ),
                  ),
                ),
                // Availability badge
                if (!product.available)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red[600],
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text(
                        'Out of Stock',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
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
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.image_not_supported_rounded,
                  color: Colors.grey[400],
                  size: 40,
                ),
              ),
            ),
    );
  }

  Widget _buildProductInfo(
      BuildContext context, ThemeData theme, NumberFormat currencyFormat) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Product Name
          Text(
            product.name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
              height: 1.2,
              letterSpacing: -0.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          // Price and Availability
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  currencyFormat.format(product.price),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                    letterSpacing: -0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (product.available)
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _getStockColor(product.availableStock),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _getStockColor(product.availableStock)
                            .withOpacity(0.4),
                        blurRadius: 3,
                        spreadRadius: 0.5,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Stok durumuna göre renk döndürür
  /// 0'dan aşağı ise kırmızı, 1 ise sarı, 1'den yüksek ise yeşil
  Color _getStockColor(int? availableStock) {
    if (availableStock == null) {
      // Stok bilgisi yoksa yeşil (mevcut davranış)
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
}
