import 'package:dio/dio.dart';

import '../../core/api_client.dart';

class OrdersRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<Map<String, dynamic>> listOrders({
    int page = 1,
    int limit = 20,
    String? email,
    String? zipcode,
    String? deepLinkCode,
    bool login = false,
  }) async {
    final payload = <String, dynamic>{
      'page': page,
      'limit': limit,
      'associations': {
        'transactions': {
          'associations': {
            'stateMachineState': {}
          }
        }
      }
    };

    if (email != null) payload['email'] = email;
    if (zipcode != null) payload['zipcode'] = zipcode;
    if (deepLinkCode != null) {
      payload['filter'] = [
        {
          'type': 'equals',
          'field': 'deepLinkCode',
          'value': deepLinkCode,
        }
      ];
    }
    if (login) payload['login'] = true;

    final resp = await _dio.post('/store-api/order', data: payload);
    return Map<String, dynamic>.from(resp.data);
  }

  Future<Map<String, dynamic>> getOrder(String orderId) async {
    final resp = await _dio.post('/store-api/order', data: {
      'filter': [
        {
          'type': 'equals',
          'field': 'id',
          'value': orderId,
        }
      ],
      'limit': 1,
      'associations': {
        'transactions': {
          'associations': {
            'stateMachineState': {}
          }
        },
        'deliveries': {
          'associations': {
            'stateMachineState': {},
            'shippingOrderAddress': {
              'associations': {
                'country': {}
              }
            }
          }
        },
        'billingAddress': {
          'associations': {
            'country': {}
          }
        },
        'lineItems': {
          'associations': {
            'cover': {}
          }
        }
      }
    });
    final data = resp.data;
    if (data is Map && data['orders'] is Map && data['orders']['elements'] is List) {
      final elements = data['orders']['elements'] as List;
      if (elements.isNotEmpty) {
        return Map<String, dynamic>.from(elements.first);
      }
    }
    throw Exception('Sipariş bulunamadı');
  }

  Future<void> retryPayment({
    required String orderId,
    required String paymentMethodId,
  }) async {
    await _dio.post('/store-api/order/payment', data: {
      'orderId': orderId,
      'paymentMethodId': paymentMethodId,
    });
  }

  Future<Map<String, dynamic>> cancelOrder(String orderId) async {
    final resp = await _dio.post('/store-api/order/state/cancel', data: {
      'orderId': orderId,
    });
    return Map<String, dynamic>.from(resp.data);
  }

  Future<void> downloadDocument({
    required String documentId,
    required String deepLinkCode,
  }) async {
    await _dio.post(
      '/store-api/document/download/$documentId/$deepLinkCode',
      options: Options(responseType: ResponseType.bytes),
    );
  }
}


