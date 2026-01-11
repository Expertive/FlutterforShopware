import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'storage.dart';
import 'config/app_config.dart';

class ApiClient {
  ApiClient._internal()
      : _dio = Dio(
          BaseOptions(
            baseUrl: AppConfig.baseUrl,
            connectTimeout: AppConfig.connectTimeout,
            receiveTimeout: AppConfig.receiveTimeout,
            headers: {
              // Use string headers for cross-platform compatibility (web and mobile)
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              // Sales channel access key - only add if not empty
              // Will be loaded from backend config endpoint
              if (AppConfig.salesChannelAccessKey.isNotEmpty)
                'sw-access-key': AppConfig.salesChannelAccessKey,
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
          // Only add if access key is not empty (will be loaded from backend config)
          if (AppConfig.salesChannelAccessKey.isNotEmpty) {
            options.headers['sw-access-key'] = AppConfig.salesChannelAccessKey;
          }

          // Disable cache for all requests to ensure fresh content after language change
          // Note: On web platform, Cache-Control header causes CORS issues in preflight requests
          // So we only add these headers on mobile platforms
          if (!kIsWeb) {
            options.headers['Cache-Control'] =
                'no-cache, no-store, must-revalidate';
            options.headers['Pragma'] = 'no-cache';
            options.headers['Expires'] = '0';
          }

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
        onResponse: (response, handler) {
          return handler.next(response);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._internal();

  final Dio _dio;

  Dio get dio => _dio;
}
