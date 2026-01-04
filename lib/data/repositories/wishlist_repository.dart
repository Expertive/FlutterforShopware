import 'package:dio/dio.dart';

import '../../core/api_client.dart';

class WishlistRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<Map<String, dynamic>>> list() async {
    final resp = await _dio.get('/store-api/customer/wishlist');
    final data = resp.data;
    if (data is Map && data['products'] is List) {
      return List<Map<String, dynamic>>.from(data['products']);
    }
    if (data is Map && data['elements'] is List) {
      return List<Map<String, dynamic>>.from(data['elements']);
    }
    return [];
  }

  Future<void> add(String productId) async {
    await _dio.post('/store-api/customer/wishlist/add/$productId');
  }

  Future<void> remove(String productId) async {
    await _dio.post('/store-api/customer/wishlist/delete/$productId');
  }

  Future<void> merge(List<String> productIds) async {
    await _dio.post('/store-api/customer/wishlist/merge', data: {
      'productIds': productIds,
    });
  }
}


