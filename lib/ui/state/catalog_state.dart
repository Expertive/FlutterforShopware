import 'package:flutter/foundation.dart';

import '../../data/repositories/catalog_repository.dart';

class CatalogState extends ChangeNotifier {
  CatalogState({CatalogRepository? repository})
      : _repository = repository ?? CatalogRepository();

  final CatalogRepository _repository;

  bool _loading = false;
  String? _error;

  List<dynamic> categories = <dynamic>[];
  List<dynamic> products = <dynamic>[];
  Map<String, dynamic>? productDetail;
  Map<String, dynamic>? appConfig;

  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadRootCategories() async {
    _setLoading(true);
    try {
      final data = await _repository.fetchCategories();
      categories = (data['categories'] as List?) ?? <dynamic>[];
      _error = null;
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadProducts({String? categoryId, String? search, int page = 1, int limit = 20}) async {
    _setLoading(true);
    try {
      final data = await _repository.fetchProducts(categoryId: categoryId, search: search, page: page, limit: limit);
      products = (data['products'] as List?) ?? <dynamic>[];
      _error = null;
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadProductDetail(String productId) async {
    _setLoading(true);
    try {
      final data = await _repository.fetchProduct(productId);
      productDetail = data['product'] as Map<String, dynamic>?;
      _error = null;
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadAppConfig() async {
    _setLoading(true);
    try {
      final data = await _repository.fetchAppConfig();
      appConfig = (data['data'] as Map?)?.cast<String, dynamic>();
      _error = null;
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }
}


