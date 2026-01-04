import 'package:dio/dio.dart';

import '../../core/api_client.dart';

class NewsletterRepository {
  final Dio _dio = ApiClient.instance.dio;

  // Public subscribe (login gerektirmez)
  Future<void> subscribe(String email) async {
    await _dio.post('/store-api/newsletter/subscribe', data: {
      'email': email,
    });
  }

  Future<void> unsubscribe(String email) async {
    await _dio.post('/store-api/newsletter/unsubscribe', data: {
      'email': email,
    });
  }

  // Account-bound preference (login gerektirir)
  Future<void> setAccountNewsletter({required String email, required bool subscribe}) async {
    await _dio.post('/store-api/account/newsletter-recipient', data: {
      'email': email,
      'option': subscribe ? 'subscribe' : 'unsubscribe',
    });
  }
}


