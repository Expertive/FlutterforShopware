import 'package:dio/dio.dart';

import '../../core/api_client.dart';

class ReviewsRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<Map<String, dynamic>>> list(String productId, {int limit = 20, int page = 1}) async {
    final resp = await _dio.get('/store-api/product/$productId/reviews', queryParameters: {
      'limit': limit,
      'p': page,
    });
    final data = resp.data;
    if (data is Map && data['elements'] is List) {
      return List<Map<String, dynamic>>.from(data['elements']);
    }
    return [];
  }

  Future<void> add(String productId, {required int rating, String? title, String? content}) async {
    await _dio.post('/store-api/product/$productId/review', data: {
      'points': rating,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
    });
  }
}


