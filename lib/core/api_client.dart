import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

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

          // Disable cache for all requests to ensure fresh content after language change
          options.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate';
          options.headers['Pragma'] = 'no-cache';
          options.headers['Expires'] = '0';

          // Debug: Log request information for layout and context endpoints
          if (kDebugMode) {
            final uri = options.uri.toString();
            if (uri.contains('/store-api/flutter/layout') || 
                uri.contains('/store-api/context') ||
                uri.contains('/store-api/product')) {
              print('=== API Request ===');
              print('Method: ${options.method}');
              print('URL: $uri');
              print('Headers:');
              options.headers.forEach((key, value) {
                if (key == 'sw-context-token' || key == 'sw-access-key') {
                  print('  $key: ${value.toString().substring(0, value.toString().length > 20 ? 20 : value.toString().length)}...');
                } else {
                  print('  $key: $value');
                }
              });
              if (options.data != null) {
                print('Body: ${options.data}');
              }
              if (options.queryParameters.isNotEmpty) {
                print('Query Params: ${options.queryParameters}');
              }
            }
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
          // Debug: Log response information for layout and context endpoints
          if (kDebugMode) {
            final uri = response.requestOptions.uri.toString();
            if (uri.contains('/store-api/flutter/layout') || 
                uri.contains('/store-api/context') ||
                uri.contains('/store-api/product')) {
              print('=== API Response ===');
              print('URL: $uri');
              print('Status Code: ${response.statusCode}');
              final responseToken = response.headers.value('sw-context-token');
              if (responseToken != null) {
                print('Response sw-context-token: ${responseToken.substring(0, responseToken.length > 20 ? 20 : responseToken.length)}...');
              }
              if (response.data is Map) {
                final data = response.data as Map;
                if (data.containsKey('language')) {
                  final lang = data['language'] as Map?;
                  print('Response Language ID: ${lang?['id']}, Name: ${lang?['name']}');
                }
              }
            }
          }
          return handler.next(response);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._internal();

  final Dio _dio;

  Dio get dio => _dio;
}
