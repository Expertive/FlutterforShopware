import 'package:dio/dio.dart';

import '../../core/api_client.dart';

class CheckoutRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<Map<String, dynamic>>> getShippingMethods() async {
    final resp = await _dio.get('/store-api/shipping-method');
    final data = resp.data;
    if (data is Map && data['elements'] is List) {
      return List<Map<String, dynamic>>.from(data['elements']);
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getPaymentMethods() async {
    final resp = await _dio.get('/store-api/payment-method');
    final data = resp.data;
    if (data is Map && data['elements'] is List) {
      return List<Map<String, dynamic>>.from(data['elements']);
    }
    return [];
  }

  Future<Map<String, dynamic>> updateContext({
    String? shippingMethodId,
    String? paymentMethodId,
    String? billingAddressId,
    String? shippingAddressId,
  }) async {
    final payload = <String, dynamic>{};
    if (shippingMethodId != null) payload['shippingMethodId'] = shippingMethodId;
    if (paymentMethodId != null) payload['paymentMethodId'] = paymentMethodId;
    if (billingAddressId != null) payload['billingAddressId'] = billingAddressId;
    if (shippingAddressId != null) payload['shippingAddressId'] = shippingAddressId;
    // Store API: /store-api/context => PATCH
    final resp = await _dio.patch('/store-api/context', data: payload);
    return (resp.data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> createOrder({
    String? shippingMethodId,
    String? paymentMethodId,
    String? billingAddressId,
    String? shippingAddressId,
    Map<String, dynamic>? affiliate,
  }) async {
    // Best practice: önce context'i güncelle, sonra siparişi oluştur
    await updateContext(
      shippingMethodId: shippingMethodId,
      paymentMethodId: paymentMethodId,
      billingAddressId: billingAddressId,
      shippingAddressId: shippingAddressId,
    );
    final resp = await _dio.post('/store-api/checkout/order', data: {});
    return (resp.data as Map).cast<String, dynamic>();
  }

  /// Store API `handle-payment` endpoint
  Future<Map<String, dynamic>> handlePayment({
    required String orderId,
    required String orderTransactionId,
    String? finishUrl,
    String? errorUrl,
    Map<String, dynamic>? additionalData,
  }) async {
    final payload = <String, dynamic>{
      'orderId': orderId,
      'orderTransactionId': orderTransactionId,
    };
    if (finishUrl != null && finishUrl.isNotEmpty) {
      payload['finishUrl'] = finishUrl;
    }
    if (errorUrl != null && errorUrl.isNotEmpty) {
      payload['errorUrl'] = errorUrl;
    }
    if (additionalData != null && additionalData.isNotEmpty) {
      payload.addAll(additionalData);
    }

    final resp = await _dio.post('/store-api/handle-payment', data: payload);
    final data = resp.data;
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return <String, dynamic>{};
  }

  OrderIdentifiers extractOrderIdentifiers(dynamic response) {
    String? orderId;
    String? orderTransactionId;

    // Eğer response Map değilse, boş döndür
    if (response is! Map) {
      // Non-Map response received
      return OrderIdentifiers(orderId: null, orderTransactionId: null);
    }

    final responseMap = Map<String, dynamic>.from(response as Map);

    void readFromMap(dynamic data) {
      if (data is! Map) return;
      final dataMap = Map<String, dynamic>.from(data);
      try {
        orderId ??= dataMap['id']?.toString();
        orderId ??= dataMap['orderId']?.toString();

        if (dataMap['orderTransactionId'] != null) {
          orderTransactionId ??= dataMap['orderTransactionId'].toString();
        }

        // Attributes kontrolü
        final attributes = dataMap['attributes'];
        if (attributes != null) {
          if (attributes is Map) {
            final attrMap = Map<String, dynamic>.from(attributes);
            orderId ??= attrMap['id']?.toString();
            if (attrMap['orderTransactionId'] != null) {
              orderTransactionId ??= attrMap['orderTransactionId'].toString();
            }

            final attrTransactions = attrMap['transactions'];
            if (attrTransactions != null) {
              if (attrTransactions is List && attrTransactions.isNotEmpty) {
                final first = attrTransactions.first;
                if (first is Map && first['id'] != null) {
                  orderTransactionId ??= first['id'].toString();
                }
              } else if (attrTransactions is Map) {
                final transMap = Map<String, dynamic>.from(attrTransactions);
                if (transMap['id'] != null) {
                  orderTransactionId ??= transMap['id'].toString();
                }
              }
            }
          }
        }

        // Relationships kontrolü
        final relationships = data['relationships'];
        if (relationships != null && relationships is Map) {
          final relMap = Map<String, dynamic>.from(relationships);
          final transactions = relMap['transactions'];
          if (transactions != null) {
            if (transactions is Map) {
              final transMap = Map<String, dynamic>.from(transactions);
              final relData = transMap['data'];
              if (relData != null) {
                if (relData is List && relData.isNotEmpty) {
                  final first = relData.first;
                  if (first is Map && first['id'] != null) {
                    orderTransactionId ??= first['id'].toString();
                  }
                } else if (relData is Map) {
                  final dataMap = Map<String, dynamic>.from(relData);
                  if (dataMap['id'] != null) {
                    orderTransactionId ??= dataMap['id'].toString();
                  }
                }
              }
            } else if (transactions is List && transactions.isNotEmpty) {
              final first = transactions.first;
              if (first is Map && first['id'] != null) {
                orderTransactionId ??= first['id'].toString();
              }
            }
          }
        }

        // Direct transactions kontrolü
        final transactions = dataMap['transactions'];
        if (transactions != null) {
          if (transactions is List && transactions.isNotEmpty) {
            final first = transactions.first;
            if (first is Map && first['id'] != null) {
              orderTransactionId ??= first['id'].toString();
            }
          } else if (transactions is Map) {
            final transMap = Map<String, dynamic>.from(transactions);
            if (transMap['id'] != null) {
              orderTransactionId ??= transMap['id'].toString();
            }
            // Eğer transactions bir Map içinde data array'i varsa
            final transData = transMap['data'];
            if (transData is List && transData.isNotEmpty) {
              final first = transData.first;
              if (first is Map && first['id'] != null) {
                orderTransactionId ??= first['id'].toString();
              }
            }
          }
        }
      } catch (e) {
        // Error extracting order identifiers
      }
    }

    try {
      // data field kontrolü
      final dataField = responseMap['data'];
      if (dataField != null) {
        readFromMap(dataField);
      }

      // order field kontrolü
      final orderField = responseMap['order'];
      if (orderField != null) {
        readFromMap(orderField);
      }

      // Root level id kontrolü
      if (orderId == null && responseMap['id'] != null) {
        orderId = responseMap['id'].toString();
      }
      if (orderTransactionId == null && responseMap['orderTransactionId'] != null) {
        orderTransactionId = responseMap['orderTransactionId'].toString();
      }

      // Included array kontrolü
      final included = responseMap['included'];
      if (included != null && included is List) {
        for (final entry in included) {
          if (entry is Map) {
            try {
              final entryMap = Map<String, dynamic>.from(entry);
              final type = entryMap['type']?.toString();
              if (type == 'order_transaction') {
                final id = entryMap['id'];
                if (id != null) {
                  orderTransactionId ??= id.toString();
                }
              }
            } catch (e) {
              // Skip invalid entries
            }
          }
        }
      }

    } catch (e) {
      // Silent fail on response structure processing error
    }

    return OrderIdentifiers(
      orderId: orderId,
      orderTransactionId: orderTransactionId,
    );
  }
}

class OrderIdentifiers {
  const OrderIdentifiers({
    this.orderId,
    this.orderTransactionId,
  });

  final String? orderId;
  final String? orderTransactionId;

  bool get hasRequiredIds => orderId != null && orderTransactionId != null;
}


