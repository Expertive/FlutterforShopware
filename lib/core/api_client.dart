import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'config.dart';
import 'storage.dart';
import 'package:flutter_shop_app/core/config/app_config.dart' as AppConst;

class ApiClient {
  ApiClient._internal()
      : _dio = Dio(
          BaseOptions(
            baseUrl: AppConfig.baseUrl,
            connectTimeout: AppConfig.connectTimeout,
            receiveTimeout: AppConfig.receiveTimeout,
            headers: {
              HttpHeaders.contentTypeHeader: 'application/json',
              HttpHeaders.acceptHeader: 'application/json',
              // For public Store API access, sales channel access key
              // Note: This value is updated in the interceptor for each request
              'sw-access-key': AppConst.AppConfig.salesChannelAccessKey,
            },
          ),
        ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Refresh baseUrl in case it changed at runtime
          if (options.baseUrl != AppConfig.baseUrl) {
            options.baseUrl = AppConfig.baseUrl;
          }

          // Attach sw-context-token if present
          final token = await TokenStorage.instance.loadContextToken();
          if (token != null && token.isNotEmpty) {
            options.headers['sw-context-token'] = token;
          }

          // Ensure sw-access-key header is always present (use current value from AppConfig)
          // Always use the current value (updated when access key changes)
          options.headers['sw-access-key'] =
              AppConst.AppConfig.salesChannelAccessKey;

          return handler.next(options);
        },
        onError: (e, handler) {
          // Handle 500 errors from layout endpoints silently
          final uri = e.requestOptions.uri.toString();
          final isLayoutEndpoint = uri.contains('/store-api/flutter/layout');
          final is500Error = e.response?.statusCode == 500;

          if (isLayoutEndpoint && is500Error) {
            // Log 500 errors from layout endpoints (fallback layout will be used)
            return handler.next(e);
          }

          return handler.next(e);
        },
        onResponse: (response, handler) => handler.next(response),
      ),
    );
  }

  static final ApiClient instance = ApiClient._internal();

  final Dio _dio;

  Dio get dio => _dio;
}
