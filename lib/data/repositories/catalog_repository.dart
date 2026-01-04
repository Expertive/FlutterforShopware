import 'package:dio/dio.dart';

import '../../core/api_client.dart';

class CatalogRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<Map<String, dynamic>> fetchCategories({String? parentId, String? search, int limit = 50}) async {
    final resp = await _dio.get(
      '/store-api/flutter/categories',
      queryParameters: {
        if (parentId != null) 'parentId': parentId,
        if (search != null && search.isNotEmpty) 'search': search,
        'limit': limit,
      },
    );
    return (resp.data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> fetchCategory(String categoryId) async {
    final resp = await _dio.get('/store-api/flutter/categories/$categoryId');
    return (resp.data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> fetchProducts({String? categoryId, String? search, int limit = 20, int page = 1}) async {
    final resp = await _dio.get(
      '/store-api/flutter/products',
      queryParameters: {
        if (categoryId != null) 'categoryId': categoryId,
        if (search != null && search.isNotEmpty) 'search': search,
        'limit': limit,
        'page': page,
      },
    );
    return (resp.data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> fetchProduct(String productId) async {
    final resp = await _dio.get('/store-api/flutter/products/$productId');
    return (resp.data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> fetchLayoutByPageId(String pageId) async {
    final resp = await _dio.get('/store-api/flutter/layout/$pageId');
    return (resp.data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> fetchCmsPages() async {
    final resp = await _dio.get('/store-api/flutter/cms-pages');
    return (resp.data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> fetchAppConfig() async {
    final resp = await _dio.get('/store-api/flutter/config');
    return (resp.data as Map).cast<String, dynamic>();
  }
}


