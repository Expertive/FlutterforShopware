import 'package:dio/dio.dart';

import '../../core/api_client.dart';
import '../../core/storage.dart';

class AuthRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<void> login({required String email, required String password}) async {
    try {
      final response = await _dio.post(
        '/store-api/account/login',
        data: {
          // Some setups expect username, for compatibility we send both
          'email': email,
          'username': email,
          'password': password,
        },
      );

      // Try to read context token from headers first (Dio v5)
      final tokenFromHeader = response.headers.value('sw-context-token');
      if (tokenFromHeader != null && tokenFromHeader.isNotEmpty) {
        await TokenStorage.instance.saveContextToken(tokenFromHeader);
        return;
      }

      // Fallback: some setups return token in response body
      final body = response.data;
      if (body is Map && body['contextToken'] is String) {
        await TokenStorage.instance
            .saveContextToken(body['contextToken'] as String);
        return;
      }

      throw StateError('Context token not found after login');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Email or password is incorrect.');
      }
      final message = e.response?.data is Map &&
              (e.response?.data['errors'] is List)
          ? (e.response!.data['errors'][0]?['detail']?.toString() ?? e.message)
          : e.message;
      throw Exception(message);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/store-api/account/logout');
    } finally {
      await TokenStorage.instance.clear();
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String salutationId,
    required String firstName,
    required String lastName,
  }) async {
    final response = await _dio.post(
      '/store-api/account/register',
      data: {
        'email': email,
        'password': password,
        'salutationId': salutationId,
        'firstName': firstName,
        'lastName': lastName,
        // Basic minimal required fields; shipping/billing may be added later in checkout process
      },
    );

    final tokenFromHeader = response.headers.value('sw-context-token');
    if (tokenFromHeader != null && tokenFromHeader.isNotEmpty) {
      await TokenStorage.instance.saveContextToken(tokenFromHeader);
    }
  }

  Future<void> requestPasswordRecovery({required String email}) async {
    await _dio
        .post('/store-api/account/recovery-password', data: {'email': email});
  }

  Future<void> confirmPasswordRecovery({
    required String hash,
    required String newPassword,
    String? newPasswordConfirm,
  }) async {
    await _dio.post('/store-api/account/recovery-password-confirm', data: {
      'hash': hash,
      'newPassword': newPassword,
      if (newPasswordConfirm != null) 'newPasswordConfirm': newPasswordConfirm,
    });
  }

  Future<Map<String, dynamic>> me() async {
    final resp = await _dio.get('/store-api/account/customer');
    if (resp.data is Map<String, dynamic>) {
      return resp.data as Map<String, dynamic>;
    }
    return {'data': resp.data};
  }

  Future<void> changeProfile({
    String accountType = 'private',
    String? company,
    List<String>? vatIds,
    String? firstName,
    String? lastName,
  }) async {
    final payload = <String, dynamic>{
      'accountType': accountType,
      'company': company,
      'vatIds': vatIds,
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
    };
    await _dio.post('/store-api/account/change-profile', data: payload);
  }

  Future<void> changeEmail({
    required String email,
    required String emailConfirmation,
    required String password,
  }) async {
    await _dio.post('/store-api/account/change-email', data: {
      'email': email,
      'emailConfirmation': emailConfirmation,
      'password': password,
    });
  }

  Future<void> changePassword({
    required String password,
    required String newPassword,
    required String newPasswordConfirm,
  }) async {
    await _dio.post('/store-api/account/change-password', data: {
      'password': password,
      'newPassword': newPassword,
      'newPasswordConfirm': newPasswordConfirm,
    });
  }
}
