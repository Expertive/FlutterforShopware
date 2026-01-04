class FlutterLayout {
  final String pageId;
  final Map<String, dynamic> layoutData;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const FlutterLayout({
    required this.pageId,
    required this.layoutData,
    this.createdAt,
    this.updatedAt,
  });

  factory FlutterLayout.fromJson(Map<String, dynamic> json) {
    return FlutterLayout(
      pageId: json['pageId'] ?? '',
      layoutData: json['layoutData'] ?? {},
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pageId': pageId,
      'layoutData': layoutData,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  FlutterLayout copyWith({
    String? pageId,
    Map<String, dynamic>? layoutData,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FlutterLayout(
      pageId: pageId ?? this.pageId,
      layoutData: layoutData ?? this.layoutData,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'FlutterLayout(pageId: $pageId, hasLayoutData: ${layoutData.isNotEmpty})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FlutterLayout && other.pageId == pageId;
  }

  @override
  int get hashCode => pageId.hashCode;
}
