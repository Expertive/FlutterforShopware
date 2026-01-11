import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/services/shopware_api.dart';
import '../widgets/product_card.dart';
import '../core/storage.dart';
import '../data/repositories/auth_repository.dart';
import '../core/config/app_config.dart';
import '../core/models/category.dart';

class CategoryScreen extends StatefulWidget {
  final String categoryId;

  const CategoryScreen({
    super.key,
    required this.categoryId,
  });

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final ShopwareApi _api = ShopwareApi();

  List<dynamic> _products = [];
  List<dynamic> _subcategories = [];
  bool _isLoading = true;
  String? _error;
  String? _categoryName;
  late Color _primaryColor;

  @override
  void initState() {
    super.initState();
    // Start default color
    _primaryColor = _hexToColor(AppConfig.primaryColorHex);
    _loadPrimaryColor();
    _loadCategoryData();
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
      // Error
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

  Future<void> _loadCategoryData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      if (widget.categoryId != 'root') {
        final category = await _api.getCategory(widget.categoryId);
        setState(() {
          _categoryName = category.name;
        });
      } else {
        setState(() {
          _categoryName = 'Categories';
        });
      }

      // Get subcategories
      final subcategories = await _api.getCategories(
        parentId: widget.categoryId == 'root' ? null : widget.categoryId,
      );

      // Get products
      final products = await _api.getProducts(
        categoryId: widget.categoryId == 'root' ? null : widget.categoryId,
      );

      setState(() {
        _subcategories = subcategories;
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(context),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _handleBack(context),
        ),
        title: Text(_categoryName ?? 'Categories'),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.go('/search'),
          ),
        ],
      ),
      body: _buildBody(),
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
            Text('Loading category information...'),
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
              onPressed: _loadCategoryData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subcategories
          if (_subcategories.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Subcategories',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12.0,
                  crossAxisSpacing: 12.0,
                  childAspectRatio: 1.2,
                ),
                itemCount: _subcategories.length,
                itemBuilder: (context, index) {
                  final category = _subcategories[index];
                  // Category object is direct access to properties
                  final String name;
                  final String id;
                  final String? imageUrl;

                  if (category is Category) {
                    name =
                        category.name.isNotEmpty ? category.name : 'Category';
                    id = category.id;
                    imageUrl = category.imageUrl;
                  } else {
                    // Fallback: Map formatında gelirse
                    name = (category['name']?.toString() ?? 'Category');
                    id = (category['id']?.toString() ?? '');
                    imageUrl = category['imageUrl']?.toString();
                  }

                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      onTap: () => context.go('/category/$id'),
                      borderRadius: BorderRadius.circular(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (imageUrl != null && imageUrl.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                imageUrl,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.category,
                                    size: 60,
                                    color: _primaryColor,
                                  );
                                },
                              ),
                            )
                          else
                            Icon(
                              Icons.category,
                              size: 60,
                              color: _primaryColor,
                            ),
                          const SizedBox(height: 8),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Products
          if (_products.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Products',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8.0,
                crossAxisSpacing: 8.0,
                childAspectRatio: 0.75,
              ),
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final product = _products[index];
                return ProductCard(
                  product: product,
                  onTap: () => context.go('/product/${product.id}'),
                );
              },
            ),
          ],

          // Empty state
          if (_products.isEmpty && _subcategories.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'No products or subcategories found in this category yet.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DrawerHeader(
              child: Text(
                'Menu',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () => context.go('/'),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text('Categories',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: _api.getCategories(parentId: null),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: LinearProgressIndicator(),
                    );
                  }
                  final elements = snapshot.data ?? [];
                  if (elements.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No categories found'),
                    );
                  }
                  return ListView.builder(
                    itemCount: elements.length,
                    itemBuilder: (context, index) {
                      final cat = elements[index];
                      final name =
                          (cat.name ?? cat['name']?.toString()) ?? 'Category';
                      final id = (cat.id ?? cat['id']?.toString()) ?? '';
                      return ListTile(
                        dense: true,
                        title: Text(name),
                        onTap: () {
                          Navigator.of(context).pop();
                          context.go('/category/$id');
                        },
                      );
                    },
                  );
                },
              ),
            ),
            FutureBuilder<String?>(
              future: TokenStorage.instance.loadContextToken(),
              builder: (context, snapshot) {
                final hasToken =
                    (snapshot.data != null && snapshot.data!.isNotEmpty);
                if (hasToken) {
                  return ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Logout'),
                    onTap: () async {
                      Navigator.of(context).pop();
                      try {
                        await AuthRepository().logout();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Logged out')));
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')));
                        }
                      }
                    },
                  );
                }
                return ListTile(
                  leading: const Icon(Icons.login),
                  title: const Text('Login'),
                  onTap: () => context.go('/login'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
