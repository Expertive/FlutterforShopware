import 'package:dio/dio.dart';

import '../../core/api_client.dart';

class CartRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<Map<String, dynamic>> getCart() async {
    try {
      final resp = await _dio.get('/store-api/checkout/cart');
      return (resp.data as Map).cast<String, dynamic>();
    } catch (e) {
      // Sepet yoksa oluştur
      if (e is DioException && (e.response?.statusCode == 404 || e.response?.statusCode == 400)) {
        return await createCart();
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createCart() async {
    final resp = await _dio.post('/store-api/checkout/cart', data: {});
    return (resp.data as Map).cast<String, dynamic>();
  }

  Future<void> _ensureCart() async {
    try {
      await _dio.get('/store-api/checkout/cart');
    } catch (e) {
      if (e is DioException && (e.response?.statusCode == 404 || e.response?.statusCode == 400)) {
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
            'referencedId': productId,
            'quantity': quantity,
          }
        ]
      },
    );
    return (resp.data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> removeLineItem({required String lineItemId}) async {
    final resp = await _dio.post(
      '/store-api/checkout/cart/line-item/delete',
      data: {
        'ids': [lineItemId],
      },
    );
    return (resp.data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> updateQuantity({
    required String lineItemId,
    required int quantity,
    String? referencedProductId,
  }) async {
    await _ensureCart();
    
    // Önce sepeti alıp mevcut satırı bulalım
    final cart = await getCart();
    final lineItems = cart['lineItems'] as List?;
    final currentItem = lineItems?.firstWhere(
      (item) => (item as Map)['id']?.toString() == lineItemId,
      orElse: () => null,
    ) as Map<String, dynamic>?;
    
    if (currentItem == null) {
      // Satır bulunamadı, referencedId ile yeni ekle
      if (referencedProductId != null && quantity > 0) {
        return addProduct(productId: referencedProductId, quantity: quantity);
      }
      throw Exception('Satır bulunamadı ve referencedId verilmemiş');
    }
    
    // Mevcut satırın type ve referencedId bilgilerini al
    final type = currentItem['type']?.toString() ?? 'product';
    final referencedId = currentItem['referencedId']?.toString() ?? referencedProductId;
    
    if (referencedId == null) {
      throw Exception('referencedId bulunamadı');
    }
    
    // Eğer miktar 0 veya daha azsa, satırı sil
    if (quantity <= 0) {
      await removeLineItem(lineItemId: lineItemId);
      return await getCart();
    }
    
    // Satırı silip yeni miktarla yeniden ekle (garantili çalışır)
    await removeLineItem(lineItemId: lineItemId);
    if (type == 'product' && referencedId.isNotEmpty) {
      return addProduct(productId: referencedId, quantity: quantity);
    }
    
    // Type ve referencedId ile birlikte güncelle (fallback)
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
    return (resp.data as Map).cast<String, dynamic>();
  }
}


