class Category {
  final String id;
  final String name;
  final String description;
  final String? imageUrl;
  final String? parentId;
  final List<Category> children;
  final Map<String, dynamic>? additionalData;

  const Category({
    required this.id,
    required this.name,
    required this.description,
    this.imageUrl,
    this.parentId,
    this.children = const [],
    this.additionalData,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    // Shopware Store API's response may contain null name.
    // We should use translated.name.
    String categoryName = '';
    if (json['name'] != null && json['name'].toString().isNotEmpty) {
      categoryName = json['name'].toString();
    } else if (json['translated'] != null && json['translated'] is Map) {
      final translated = json['translated'] as Map<String, dynamic>;
      categoryName = translated['name']?.toString() ?? '';
    }

    // For description, we use the same logic.
    String categoryDescription = '';
    if (json['description'] != null &&
        json['description'].toString().isNotEmpty) {
      categoryDescription = json['description'].toString();
    } else if (json['translated'] != null && json['translated'] is Map) {
      final translated = json['translated'] as Map<String, dynamic>;
      categoryDescription = translated['description']?.toString() ?? '';
    }

    // imageUrl için media control.
    String? imageUrl = json['imageUrl'];
    if (imageUrl == null && json['media'] != null && json['media'] is Map) {
      final media = json['media'] as Map<String, dynamic>;
      if (media['url'] != null) {
        imageUrl = media['url'].toString();
      }
    }

    return Category(
      id: json['id'] ?? '',
      name: categoryName,
      description: categoryDescription,
      imageUrl: imageUrl,
      parentId: json['parentId'],
      children: (json['children'] as List?)
              ?.map((child) => Category.fromJson(child))
              .toList() ??
          [],
      additionalData: json['additionalData'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'parentId': parentId,
      'children': children.map((child) => child.toJson()).toList(),
      'additionalData': additionalData,
    };
  }

  Category copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    String? parentId,
    List<Category>? children,
    Map<String, dynamic>? additionalData,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      parentId: parentId ?? this.parentId,
      children: children ?? this.children,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  bool get isParent => parentId == null;
  bool get hasChildren => children.isNotEmpty;

  @override
  String toString() {
    return 'Category(id: $id, name: $name, hasChildren: $hasChildren)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
