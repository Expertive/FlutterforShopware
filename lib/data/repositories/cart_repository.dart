import 'package:dio/dio.dart';

import '../../core/api_client.dart';
import '../../core/storage.dart';

class CartRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<void> _saveContextTokenFromResponse(
    Response<dynamic> response,
  ) async {
    await TokenStorage.instance.saveContextTokenFromResponse(response);
  }

  Future<void> _ensureContextToken() async {
    final token = await TokenStorage.instance.loadContextToken();
    if (token != null && token.isNotEmpty) return;

    final resp = await _dio.get('/store-api/context');
    await _saveContextTokenFromResponse(resp);
  }

  Future<Map<String, dynamic>> getCart() async {
    await _ensureContextToken();
    try {
      final resp = await _dio.get('/store-api/checkout/cart');
      await _saveContextTokenFromResponse(resp);
      return (resp.data as Map).cast<String, dynamic>();
    } catch (e) {
      // If cart not found, create it
      if (e is DioException &&
          (e.response?.statusCode == 404 || e.response?.statusCode == 400)) {
        return await createCart();
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createCart() async {
    await _ensureContextToken();
    final resp = await _dio.post('/store-api/checkout/cart', data: {});
    await _saveContextTokenFromResponse(resp);
    return (resp.data as Map).cast<String, dynamic>();
  }

  Future<void> _ensureCart() async {
    await _ensureContextToken();
    try {
      final resp = await _dio.get('/store-api/checkout/cart');
      await _saveContextTokenFromResponse(resp);
    } catch (e) {
      if (e is DioException &&
          (e.response?.statusCode == 404 || e.response?.statusCode == 400)) {
        await createCart();
      } else {
        rethrow;
      }
    }
  }

  Future<Map<String, dynamic>> addProduct({
    required String productId,
    int quantity = 1,
  }) async {
    await _ensureCart();
    final resp = await _dio.post(
      '/store-api/checkout/cart/line-item',
      data: {
        'items': [
          {
            'type': 'product',
            'id': productId,
            'referencedId': productId,
            'quantity': quantity,
          }
        ]
      },
    );
    await _saveContextTokenFromResponse(resp);
    return (resp.data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> removeLineItem(
      {required String lineItemId}) async {
    final resp = await _dio.post(
      '/store-api/checkout/cart/line-item/delete',
      data: {
        'ids': [lineItemId],
      },
    );
    await _saveContextTokenFromResponse(resp);
    return (resp.data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> updateQuantity({
    required String lineItemId,
    required int quantity,
    String? referencedProductId,
  }) async {
    await _ensureCart();

    // First get the cart and find the current line
    final cart = await getCart();
    final lineItems = cart['lineItems'] as List?;
    final currentItem = lineItems?.firstWhere(
      (item) => (item as Map)['id']?.toString() == lineItemId,
      orElse: () => null,
    ) as Map<String, dynamic>?;

    if (currentItem == null) {
      // Line not found, add new with referencedId
      if (referencedProductId != null && quantity > 0) {
        return addProduct(productId: referencedProductId, quantity: quantity);
      }
      throw Exception('Line not found and referencedId not provided');
    }

    // Get the type and referencedId of the current line
    final type = currentItem['type']?.toString() ?? 'product';
    final referencedId =
        currentItem['referencedId']?.toString() ?? referencedProductId;

    if (referencedId == null) {
      throw Exception('referencedId not found');
    }

    // If quantity is 0 or less, remove the line
    if (quantity <= 0) {
      await removeLineItem(lineItemId: lineItemId);
      return await getCart();
    }

    // Remove the line and add new with quantity (guaranteed to work)
    await removeLineItem(lineItemId: lineItemId);
    if (type == 'product' && referencedId.isNotEmpty) {
      return addProduct(productId: referencedId, quantity: quantity);
    }

    // Update with type and referencedId (fallback)
    final resp = await _dio.post(
      '/store-api/checkout/cart/line-item',
      data: {
        'items': [
          {
            'type': type,
            'referencedId': referencedId,
            'quantity': quantity,
          }
        ]
      },
    );
    await _saveContextTokenFromResponse(resp);
    return (resp.data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> addPromotionCode(String code) async {
    await _ensureCart();
    final resp = await _dio.post(
      '/store-api/checkout/cart/line-item',
      data: {
        'items': [
          {
            'type': 'promotion',
            'referencedId': code,
          }
        ]
      },
    );
    await _saveContextTokenFromResponse(resp);
    return (resp.data as Map).cast<String, dynamic>();
  }
}
