import '../config/app_config.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String? imageUrl;
  final bool available;
  final List<String> categories;
  final Map<String, dynamic>? additionalData;
  final int? availableStock; // Stok miktarı

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
    required this.available,
    this.categories = const [],
    this.additionalData,
    this.availableStock,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // Shopware uses calculatedPrice.unitPrice for price
    double price = 0.0;
    if (json.containsKey('calculatedPrice') &&
        json['calculatedPrice'] != null) {
      price = (json['calculatedPrice']['unitPrice'] ?? 0.0).toDouble();
    } else if (json.containsKey('price')) {
      price = (json['price']?['gross'] ?? 0.0).toDouble();
    }

    // Get image URL from cover media
    String? imageUrl;
    if (json.containsKey('cover') && json['cover'] != null) {
      final cover = json['cover'];
      if (cover.containsKey('media') && cover['media'] != null) {
        final media = cover['media'];
        if (media.containsKey('url')) {
          String url = media['url'];
          // Add base URL if not already present
          if (!url.startsWith('http://') && !url.startsWith('https://')) {
            url = '${AppConfig.baseUrl}$url';
          }
          imageUrl = url;
        }
      }
    }

    // Strip HTML from description
    String description = json['description'] ?? '';
    if (description.isNotEmpty) {
      // Simple HTML stripping (for production, use html package)
      description = description
          .replaceAll(RegExp(r'<[^>]*>'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
    }

    // Get stock information
    int? availableStock;
    if (json.containsKey('availableStock') && json['availableStock'] != null) {
      availableStock = json['availableStock'] as int?;
    } else if (json.containsKey('stock') && json['stock'] != null) {
      availableStock = json['stock'] as int?;
    }

    return Product(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: description,
      price: price,
      imageUrl: imageUrl,
      available: json['available'] ?? true,
      categories: List<String>.from(json['categories'] ?? []),
      additionalData: json,
      availableStock: availableStock,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': {'gross': price},
      'imageUrl': imageUrl,
      'available': available,
      'categories': categories,
      'additionalData': additionalData,
      'availableStock': availableStock,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    bool? available,
    List<String>? categories,
    Map<String, dynamic>? additionalData,
    int? availableStock,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      available: available ?? this.available,
      categories: categories ?? this.categories,
      additionalData: additionalData ?? this.additionalData,
      availableStock: availableStock ?? this.availableStock,
    );
  }

  @override
  String toString() {
    return 'Product(id: $id, name: $name, price: $price, available: $available)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
