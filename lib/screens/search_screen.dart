import 'package:flutter/material.dart';
import '../core/utils/color_utils.dart';
import 'package:go_router/go_router.dart';

import '../core/models/product.dart';
import '../core/services/shopware_api.dart';
import '../widgets/product_card.dart';
import '../core/config/app_config.dart';
import '../core/utils/l10n_extension.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ShopwareApi _api = ShopwareApi();
  final TextEditingController _searchController = TextEditingController();

  List<Product> _products = [];
  bool _isLoading = false;
  bool _hasSearchError = false;
  String _lastSearchQuery = '';
  late Color _primaryColor;
  int _searchRequestId = 0;

  @override
  void initState() {
    super.initState();
    // Start default color
    _primaryColor = _hexToColor(AppConfig.primaryColorHex);
    _loadPrimaryColor();
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

  @override
  void dispose() {
    _searchRequestId++;
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      if (!mounted) return;
      setState(() {
        _products = [];
        _hasSearchError = false;
      });
      return;
    }

    final requestId = ++_searchRequestId;

    try {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
        _hasSearchError = false;
      });

      final products = await _api.searchProducts(
        term: query.trim(),
        limit: 50,
      );

      if (!mounted || requestId != _searchRequestId) return;
      setState(() {
        _products = products;
        _lastSearchQuery = query.trim();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted || requestId != _searchRequestId) return;
      setState(() {
        _hasSearchError = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.searchTitle),
        centerTitle: true,
        backgroundColor: _primaryColor,
        foregroundColor: ColorUtils.foregroundOn(_primaryColor),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: context.l10n.searchHint,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _products = [];
                                _hasSearchError = false;
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  onSubmitted: (q) {
                    _performSearch(q);
                  },
                  onChanged: (value) {
                    if (value.trim().length >= 3) {
                      _performSearch(value);
                    }
                  },
                ),
              ],
            ),
          ),

          // Results
          Expanded(
            child: _buildResults(context),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(context.l10n.searchSearching),
          ],
        ),
      );
    }

    if (_hasSearchError) {
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
              context.l10n.searchError,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _performSearch(_lastSearchQuery),
              child: Text(context.l10n.commonTryAgain),
            ),
          ],
        ),
      );
    }

    if (_products.isEmpty && _lastSearchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.searchNoResults,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.searchTryDifferent,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.searchPrompt,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Result count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            context.l10n.searchResultsCount(
              _lastSearchQuery,
              _products.length,
            ),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Product list
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8.0,
              crossAxisSpacing: 8.0,
              childAspectRatio: 0.68,
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
        ),
      ],
    );
  }
}
