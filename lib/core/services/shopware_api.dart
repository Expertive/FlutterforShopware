import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/painting.dart';
import 'dart:convert';

import '../models/product.dart';
import '../models/category.dart';
import '../config/app_config.dart';
import '../api_client.dart';
import '../storage.dart';

class ShopwareApi {
  static final ShopwareApi _instance = ShopwareApi._internal();
  factory ShopwareApi() => _instance;
  ShopwareApi._internal() {
    initialize();
  }

  late Dio _dio;

  void initialize() {
    // Use centralized ApiClient (Dio) so sw-context-token is automatically added
    _dio = ApiClient.instance.dio;
  }

  Future<Map<String, dynamic>> getLayout(String pageId) async {
    try {
      String url = '${AppConfig.layoutEndpoint}/$pageId';
      final queryParams = <String, String>{
        '_t': DateTime.now().millisecondsSinceEpoch.toString(),
      };

      final languageId = await TokenStorage.instance.loadLanguageId();
      if (languageId != null && languageId.isNotEmpty) {
        queryParams['languageId'] = languageId;
      }

      final uri = Uri.parse(url).replace(queryParameters: queryParams);

      // Note: Cache-Control headers are handled by ApiClient interceptor
      // On web platform, these headers are not sent to avoid CORS issues
      final response = await _dio.get(uri.toString());

      return response.data;
    } on DioException catch (e) {
      // Check response body even if 500 error occurs
      // Backend sometimes returns JSON with 500 (containing error message)
      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final responseData = e.response!.data;

        // Parse response data
        Map<String, dynamic>? dataMap;

        if (responseData is Map) {
          dataMap = Map<String, dynamic>.from(responseData);
        } else if (responseData is String) {
          // If String, try to parse as JSON
          try {
            final decoded = jsonDecode(responseData) as Map<String, dynamic>;
            dataMap = decoded;
          } catch (parseError) {
            // Silent fail on parse error
          }
        }

        // If Map was parsed and has child/type field, use it
        if (dataMap != null) {
          if (dataMap.containsKey('child') || dataMap.containsKey('type')) {
            return dataMap;
          }
        }

        if (statusCode == 500 || statusCode == 404) {
          // Server error and no valid layout data - return empty Map
          return {};
        }
      }
      // Return empty Map for other errors (fallback layout will be used)
      return {};
    } catch (e) {
      // Return empty Map on error (fallback layout will be used)
      return {};
    }
  }

  Future<List<Product>> getProducts({
    String? categoryId,
    String? search,
    int limit = 20,
    int page = 1,
  }) async {
    try {
      Response response;
      if (categoryId != null && categoryId.isNotEmpty) {
        // Kategori listesi: product-listing/{categoryId} POST ile çağrılır
        response = await _dio.post(
          '/store-api/product-listing/$categoryId',
          data: {
            'limit': limit,
            'p': page,
            if (search != null && search.isNotEmpty) 'search': search,
          },
        );
      } else {
        // General product list
        response = await _dio.get(
          AppConfig.productsEndpoint,
          queryParameters: {
            'limit': limit,
            'p': page,
            if (search != null && search.isNotEmpty) 'search': search,
          },
        );
      }

      final List<dynamic> elements = (response.data['elements'] as List?) ??
          (response.data['products'] as List? /* backward compat */) ??
          <dynamic>[];

      return elements.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Product> getProduct(String productId) async {
    try {
      // Check UUID format (32 character hex string)
      final isUuid =
          RegExp(r'^[0-9a-f]{32}$', caseSensitive: false).hasMatch(productId);

      String actualProductId = productId;

      // If not UUID, search by product number or SEO URL
      if (!isUuid) {
        try {
          // Search by product number
          final searchResponse = await _dio.post(
            '/store-api/search',
            data: {
              'search': productId,
              'limit': 1,
            },
          );

          final elements = searchResponse.data['elements'] as List? ?? [];
          if (elements.isNotEmpty) {
            final product = elements.first as Map<String, dynamic>;
            actualProductId = product['id'] as String? ?? productId;
          } else {
            // Product not found, use original ID
            actualProductId = productId;
          }
        } catch (searchError) {
          // Search error, use original ID
          actualProductId = productId;
        }
      }

      // Store API product detail is called with POST
      final response = await _dio.post(
        '${AppConfig.productsEndpoint}/$actualProductId',
        data: const {},
      );

      final Map<String, dynamic> map =
          (response.data as Map).cast<String, dynamic>();
      final Map<String, dynamic> payload =
          (map['product'] as Map<String, dynamic>?) ?? map; // compat
      return Product.fromJson(payload);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getCrossSelling(String productId) async {
    try {
      // Check UUID format and find real UUID if needed
      final isUuid =
          RegExp(r'^[0-9a-f]{32}$', caseSensitive: false).hasMatch(productId);
      String actualProductId = productId;

      if (!isUuid) {
        try {
          final searchResponse = await _dio.post(
            '/store-api/search',
            data: {
              'search': productId,
              'limit': 1,
            },
          );

          final elements = searchResponse.data['elements'] as List? ?? [];
          if (elements.isNotEmpty) {
            final product = elements.first as Map<String, dynamic>;
            actualProductId = product['id'] as String? ?? productId;
          }
        } catch (searchError) {
          // Return empty list on error
          return [];
        }
      }

      // Shopware Store API cross-selling endpoint POST metodunu kullanır
      final response =
          await _dio.post('/store-api/product/$actualProductId/cross-selling');
      final data = response.data;
      if (data is Map && data['elements'] is List) {
        return List<Map<String, dynamic>>.from(data['elements']);
      }
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getProductsFromStream(
    String streamId, {
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/store-api/flutter/products/stream/$streamId',
        queryParameters: {
          'limit': limit,
        },
      );

      if (response.data is Map && response.data['success'] == true) {
        final products = response.data['products'] as List? ?? [];
        return products.map((p) => p as Map<String, dynamic>).toList();
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Category>> getCategories({
    String? parentId,
    String? search,
    int limit = 50,
    bool showAll = false, // Tüm kategorileri getir (filtreleme yapmadan)
  }) async {
    try {
      // Store API category list is supported with GET
      final queryParams = <String, dynamic>{
        'limit': limit,
      };
      if (parentId != null) {
        queryParams['parentId'] = parentId;
      }
      if (search != null) {
        queryParams['search'] = search;
      }

      final response = await _dio.get(
        AppConfig.categoriesEndpoint,
        queryParameters: queryParams,
      );

      // Backend'den gelen response'da 'categories' array'i var
      final List<dynamic> elements = (response.data['categories'] as List?) ??
          (response.data['elements'] as List?) ??
          <dynamic>[];

      // ParentId filtrelemesi client-side yapılıyor
      List<dynamic> filtered = elements;
      if (showAll) {
        // Tüm kategorileri getir, filtreleme yapma
        filtered = elements;
      } else if (parentId != null) {
        filtered = elements
            .where((e) =>
                (e['parentId'] ?? (e is Category ? e.parentId : null)) ==
                parentId)
            .toList();
      } else {
        filtered = elements
            .where((e) =>
                (e['parentId'] ?? (e is Category ? e.parentId : null)) == null)
            .toList();
      }

      final categories = filtered.map((json) {
        return Category.fromJson(json);
      }).toList();

      return categories;
    } on DioException {
      // Network hatası durumunda boş liste döndür (sessizce geç)
      // Connection refused, timeout vb. hatalar için
      return [];
    } catch (_) {
      // Diğer hatalar için de boş liste döndür
      return [];
    }
  }

  Future<Category> getCategory(String categoryId) async {
    try {
      final response = await _dio.get(
        '${AppConfig.categoriesEndpoint}/$categoryId',
      );

      final Map<String, dynamic> map =
          (response.data as Map).cast<String, dynamic>();
      final Map<String, dynamic> payload =
          (map['category'] as Map<String, dynamic>?) ?? map; // compat
      return Category.fromJson(payload);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Product>> searchProducts({
    required String term,
    int limit = 24,
    int page = 1,
  }) async {
    try {
      final payload = <String, dynamic>{
        'search': term,
        'limit': limit,
        'page': page,
      };

      final response = await _dio.post(
        '/store-api/search',
        data: payload,
      );

      final data = response.data;

      final List<dynamic> elements = (data is Map && data['elements'] is List)
          ? data['elements'] as List
          : (data is Map &&
                  data['data'] is Map &&
                  (data['data'] as Map)['elements'] is List)
              ? (data['data'] as Map)['elements'] as List
              : <dynamic>[];

      return elements.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Search method
  Future<Map<String, dynamic>> search({
    String? query,
    String? categoryId,
    int limit = 20,
    int page = 1,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        'page': page,
      };

      if (query != null && query.isNotEmpty) {
        queryParams['search'] = query;
      }

      if (categoryId != null) {
        queryParams['categoryId'] = categoryId;
      }

      final response = await _dio.get(
        AppConfig.productsEndpoint,
        queryParameters: queryParams,
      );

      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Suggest method
  Future<List<String>> searchSuggest(String term, {int limit = 10}) async {
    final resp = await _dio.post(
      '/store-api/search-suggest',
      data: {
        'search': term,
        'limit': limit,
      },
    );
    final List<dynamic> suggestions = (resp.data['suggestions'] as List?) ??
        (resp.data['elements'] as List? /* variant formats */) ??
        <dynamic>[];
    return suggestions.map((e) => e.toString()).toList();
  }

  // CMS Pages list with Store API
  Future<List<Map<String, dynamic>>> getCmsPages({
    int limit = 20,
    int page = 1,
  }) async {
    try {
      final response = await _dio.get(
        '/store-api/flutter/cms-pages',
      );

      if (response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      } else {
        throw Exception('Failed to load CMS pages: ${response.data['error']}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Lookups
  Future<List<Map<String, dynamic>>> getSalutations() async {
    final resp = await _dio.get('/store-api/salutation');
    final data = resp.data;
    if (data is Map && data['elements'] is List) {
      return List<Map<String, dynamic>>.from(data['elements']);
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getCountries() async {
    final resp = await _dio.get('/store-api/country');
    final data = resp.data;
    if (data is Map && data['elements'] is List) {
      return List<Map<String, dynamic>>.from(data['elements']);
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getCountryStates(String countryId) async {
    final resp = await _dio.get('/store-api/country-state/$countryId');
    final data = resp.data;
    if (data is Map && data['elements'] is List) {
      return List<Map<String, dynamic>>.from(data['elements']);
    }
    return [];
  }

  // Cache clearing helper method
  Future<void> _clearCaches() async {
    try {
      // Clear context token
      await TokenStorage.instance.clear();

      // Clear image cache (CachedNetworkImage)
      // CachedNetworkImage uses its own cache manager
      // imageCache.clear() can be used for cache clearing
      try {
        imageCache.clear();
        imageCache.clearLiveImages();
      } catch (e) {
        // Silent fail on image cache clear error
      }
    } catch (e) {
      // Silent fail on cache clear error
    }
  }

  // Update AppConfig from Shopware config
  Future<void> _updateAppConfig(Map<String, dynamic> configData) async {
    try {
      bool configChanged = false;

      // App Name
      if (configData['appName'] != null) {
        final newAppName = configData['appName'] as String;
        if (AppConfig.appName != newAppName) {
          AppConfig.appName = newAppName;
          configChanged = true;
        }
      }

      // API Base URL
      if (configData['apiBaseUrl'] != null) {
        final apiBaseUrl = (configData['apiBaseUrl'] as String).trim();
        if (apiBaseUrl.isNotEmpty) {
          // Don't use localhost baseUrl from backend - ignore it
          if (apiBaseUrl.contains('localhost') || apiBaseUrl.contains('127.0.0.1')) {
            // Don't update baseUrl if it's localhost - continue with other config values
          } else {
            // Normalize baseUrl - ensure it ends with / for proper URL construction
            String normalizedBaseUrl = apiBaseUrl;
            if (!normalizedBaseUrl.endsWith('/')) {
              normalizedBaseUrl = '$normalizedBaseUrl/';
            }
            // Update baseUrl (single source of truth)
            if (AppConfig.baseUrl != normalizedBaseUrl) {
              AppConfig.update(newBaseUrl: normalizedBaseUrl);
              // Also update Dio's baseUrl immediately
              ApiClient.instance.dio.options.baseUrl = normalizedBaseUrl;
              configChanged = true;
            }
          }
        }
      }

      // Sales Channel Access Key
      if (configData['salesChannelAccessKey'] != null) {
        final accessKey =
            (configData['salesChannelAccessKey'] as String).trim();
        if (accessKey.isNotEmpty) {
          final oldKey = AppConfig.salesChannelAccessKey;
          if (oldKey != accessKey) {
            AppConfig.salesChannelAccessKey = accessKey;
            configChanged = true;
            ApiClient.instance.dio.options.headers['sw-access-key'] = accessKey;
          }
        }
      }

      // Home Page ID
      if (configData['pages'] != null) {
        final pages = configData['pages'] as Map<String, dynamic>?;
        if (pages != null && pages['home'] != null) {
          final newHomePageId = pages['home'] as String? ?? '';
          if (AppConfig.defaultHomePageId != newHomePageId) {
            AppConfig.defaultHomePageId = newHomePageId;
            configChanged = true;
          }
        }
      }

      // Primary Color
      if (configData['primaryColor'] != null) {
        final primaryColorStr = (configData['primaryColor'] as String).trim();
        if (primaryColorStr.isNotEmpty) {
          // Update primaryColorHex in AppConfig
          final currentColor = AppConfig.primaryColorHex;
          if (currentColor != primaryColorStr) {
            AppConfig.update(newPrimaryColorHex: primaryColorStr);
            configChanged = true;
          }
        }
      }

      // Logo URL
      if (configData['logoUrl'] != null) {
        final logoUrlStr = (configData['logoUrl'] as String).trim();
        if (logoUrlStr.isNotEmpty && AppConfig.logoUrl != logoUrlStr) {
          AppConfig.logoUrl = logoUrlStr;
          configChanged = true;
        }
      } else {
        // Set Logo URL to null if not present
        if (AppConfig.logoUrl != null) {
          AppConfig.logoUrl = null;
          configChanged = true;
        }
      }

      // If config changed, clear caches and update config cache
      if (configChanged) {
        await _clearCaches();
        // Also update config cache (save new config)
        await TokenStorage.instance.saveFlutterConfig(configData);
      }
    } catch (e) {
      // Silent fail on AppConfig update error
    }
  }

  /// Bootstrap: fetch access key using mobileSalesChannelId + mobileAppSecret.
  /// Returns true when access key was obtained successfully.
  Future<bool> bootstrapAccessKey() async {
    try {
      final salesChannelId = AppConfig.mobileSalesChannelId;
      if (salesChannelId.isEmpty || AppConfig.mobileAppSecret.isEmpty) {
        return false;
      }

      final bootstrapDio = Dio(BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
      ));

      final response = await bootstrapDio.get(
        '/flutter/bootstrap',
        queryParameters: {
          'salesChannelId': salesChannelId,
          'appSecret': AppConfig.mobileAppSecret,
        },
      );

      if (response.statusCode == 200 &&
          response.data is Map &&
          response.data['success'] == true) {
        final accessKey = response.data['accessKey'] as String? ?? '';
        if (accessKey.isNotEmpty) {
          AppConfig.salesChannelAccessKey = accessKey;
          ApiClient.instance.dio.options.headers['sw-access-key'] = accessKey;
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // Get Flutter app configuration
  // With cache mechanism: Read from cache first, then update from backend
  Future<Map<String, dynamic>> getFlutterConfig(
      {bool forceRefresh = false}) async {
    // Default config
    final defaultConfig = {
      'appName': 'FlutterforShopware',
      'apiBaseUrl': AppConfig.baseUrl,
      'salesChannelAccessKey': AppConfig.salesChannelAccessKey,
      'primaryColor': '#1976D2',
      'pages': {
        'home': null,
        'category': null,
        'productDetail': null,
        'search': null,
      }
    };

    // Load from cache (if not forceRefresh)
    if (!forceRefresh) {
      final cachedConfig = await TokenStorage.instance.loadFlutterConfig();
      if (cachedConfig != null) {
        // Check if cached config has invalid baseUrl (localhost)
        final cachedBaseUrl = (cachedConfig['apiBaseUrl'] as String?)?.trim() ?? '';
        if (cachedBaseUrl.contains('localhost') || cachedBaseUrl.contains('127.0.0.1')) {
          // Cache'de localhost varsa cache'i temizle ve backend'den yükle
          await TokenStorage.instance.clearFlutterConfig();
          // Continue to fetch from backend
        } else {
          // Check if cached access key matches current default access key
          // If different, clear cache to force reload with new key
          final cachedAccessKey = (cachedConfig['salesChannelAccessKey'] as String?)?.trim() ?? '';
          final currentDefaultKey = AppConfig.salesChannelAccessKey;
          
          // If access key changed in code (different from cached), clear cache
          if (cachedAccessKey.isNotEmpty && 
              currentDefaultKey.isNotEmpty && 
              cachedAccessKey != currentDefaultKey) {
            await TokenStorage.instance.clearFlutterConfig();
            // Continue to fetch from backend with new key
          } else {
            // Apply cached config to AppConfig (includes access key)
            await _updateAppConfig(cachedConfig);

            // Fetch latest config from backend in background and compare
            _refreshConfigInBackground();

            return cachedConfig;
          }
        }
      }
    }

    // No cache or forceRefresh=true, fetch from backend
    return await _fetchConfigFromBackend(defaultConfig);
  }

  // Fetch config from backend and save to cache
  Future<Map<String, dynamic>> _fetchConfigFromBackend(
      Map<String, dynamic> defaultConfig) async {
    try {
      // Try to fetch config - if access key is missing, this will fail
      // but we'll handle it gracefully
      final response = await _dio.get(
        '/store-api/flutter/config',
        options: Options(
          responseType:
              ResponseType.plain, // First get as plain text, then parse
          validateStatus: (status) => true, // Accept all status codes
        ),
      );

      // Check response data
      if (response.data == null) {
        return Map<String, dynamic>.from(defaultConfig);
      }

      // Check HTML response (String and contains HTML tags)
      if (response.data is String) {
        final dataStr = response.data as String;
        if (dataStr.trim().startsWith('<') ||
            dataStr.contains('<br') ||
            dataStr.contains('<b>')) {
          return Map<String, dynamic>.from(defaultConfig);
        }
        // If String but not HTML, try to parse as JSON
        try {
          final decoded = jsonDecode(dataStr) as Map<String, dynamic>;
          response.data = decoded;
        } catch (e) {
          return Map<String, dynamic>.from(defaultConfig);
        }
      }

      // Map check
      if (response.data is Map) {
        final dataMap = response.data as Map;
        if (dataMap['success'] == true) {
          final configData =
              Map<String, dynamic>.from(dataMap['data'] ?? defaultConfig);

          // Check if apiBaseUrl is localhost - if so, use default baseUrl instead
          final apiBaseUrl = (configData['apiBaseUrl'] as String?)?.trim() ?? '';
          if (apiBaseUrl.contains('localhost') || apiBaseUrl.contains('127.0.0.1')) {
            configData['apiBaseUrl'] = AppConfig.baseUrl; // Use default baseUrl
          }

          // Update AppConfig
          await _updateAppConfig(configData);

          // Save to cache
          await TokenStorage.instance.saveFlutterConfig(configData);

          return configData;
        } else {
          return Map<String, dynamic>.from(defaultConfig);
        }
      } else {
        return Map<String, dynamic>.from(defaultConfig);
      }
    } on DioException catch (e) {
      // DioException caught - check response body
      if (e.response != null) {
        final responseData = e.response!.data;

        // Check HTML response
        if (responseData is String) {
          if (responseData.trim().startsWith('<') ||
              responseData.contains('<br') ||
              responseData.contains('<b>')) {
            return Map<String, dynamic>.from(defaultConfig);
          }
        }
      }
      // Return default config on error
      return Map<String, dynamic>.from(defaultConfig);
    } catch (e) {
      // Return default config on error
      return Map<String, dynamic>.from(defaultConfig);
    }
  }

  // Refresh config in background (if cache exists)
  void _refreshConfigInBackground() {
    // Run in background, don't await
    Future.microtask(() async {
      try {
        final defaultConfig = {
          'appName': 'FlutterforShopware',
          'apiBaseUrl': AppConfig.baseUrl,
          'salesChannelAccessKey': AppConfig.salesChannelAccessKey,
          'primaryColor': '#1976D2',
          'pages': {
            'home': null,
            'category': null,
            'productDetail': null,
            'search': null,
          }
        };

        final newConfig = await _fetchConfigFromBackend(defaultConfig);
        final cachedConfig = await TokenStorage.instance.loadFlutterConfig();

        // Check if config changed
        if (cachedConfig != null) {
          final configChanged = _hasConfigChanged(cachedConfig, newConfig);
          if (configChanged) {
            // AppConfig already updated in _fetchConfigFromBackend
          }
        }
      } catch (e) {
        // Silent fail on background refresh error
      }
    });
  }

  // Check if two configs are different
  bool _hasConfigChanged(
      Map<String, dynamic> oldConfig, Map<String, dynamic> newConfig) {
    // Compare important fields
    final importantKeys = [
      'appName',
      'apiBaseUrl',
      'salesChannelAccessKey',
      'primaryColor',
      'logoUrl',
    ];

    for (final key in importantKeys) {
      if (oldConfig[key] != newConfig[key]) {
        return true;
      }
    }

    // Pages check
    final oldPages = oldConfig['pages'] as Map<String, dynamic>?;
    final newPages = newConfig['pages'] as Map<String, dynamic>?;
    if (oldPages != null && newPages != null) {
      for (final pageKey in ['home', 'category', 'productDetail', 'search']) {
        if (oldPages[pageKey] != newPages[pageKey]) {
          return true;
        }
      }
    }

    return false;
  }

  // Get Sales Channel Context information
  Future<Map<String, dynamic>> getSalesChannelContext() async {
    try {
      final response = await _dio.get('/store-api/context');

      await TokenStorage.instance.saveContextTokenFromResponse(response);

      final contextData = Map<String, dynamic>.from(response.data ?? {});

      // Get language ID from header if available and language is null in body
      final languageIdFromHeader = response.headers.value('sw-language-id');
      if (languageIdFromHeader != null &&
          (!contextData.containsKey('language') ||
              contextData['language'] == null)) {
        // Add language ID to context data if not present
        contextData['language'] = {
          'id': languageIdFromHeader,
          'name': 'Unknown', // Will be fetched separately if needed
        };
      }

      return contextData;
    } catch (e) {
      rethrow;
    }
  }

  // Find product variant
  Future<Map<String, dynamic>> findProductVariant({
    required String productId,
    required Map<String, String> options,
    String? switchedGroup,
  }) async {
    try {
      final payload = <String, dynamic>{
        'options': options,
      };
      if (switchedGroup != null) {
        payload['switchedGroup'] = switchedGroup;
      }

      final response = await _dio.post(
        '/store-api/product/$productId/find-variant',
        data: payload,
      );
      return Map<String, dynamic>.from(response.data ?? {});
    } catch (e) {
      rethrow;
    }
  }

  // Update context (language, currency, etc.)
  Future<Map<String, dynamic>> updateContext({
    String? currencyId,
    String? languageId,
    String? billingAddressId,
    String? shippingAddressId,
    String? paymentMethodId,
    String? shippingMethodId,
    String? countryId,
    String? countryStateId,
  }) async {
    try {
      if (languageId != null) {
        await TokenStorage.instance.saveLanguageId(languageId);
      }
      if (currencyId != null) {
        await TokenStorage.instance.saveCurrencyId(currencyId);
      }

      final hasOtherFields = billingAddressId != null ||
          shippingAddressId != null ||
          paymentMethodId != null ||
          shippingMethodId != null ||
          countryId != null ||
          countryStateId != null;

      // Web browsers often block PATCH via CORS; fetch a new context with
      // sw-language-id / sw-currency-id headers instead.
      if (kIsWeb && !hasOtherFields) {
        await TokenStorage.instance.clearContextToken();
        return getSalesChannelContext();
      }

      final payload = <String, dynamic>{};
      if (currencyId != null) payload['currencyId'] = currencyId;
      if (languageId != null) payload['languageId'] = languageId;
      if (billingAddressId != null) {
        payload['billingAddressId'] = billingAddressId;
      }
      if (shippingAddressId != null) {
        payload['shippingAddressId'] = shippingAddressId;
      }
      if (paymentMethodId != null) payload['paymentMethodId'] = paymentMethodId;
      if (shippingMethodId != null) {
        payload['shippingMethodId'] = shippingMethodId;
      }
      if (countryId != null) payload['countryId'] = countryId;
      if (countryStateId != null) payload['countryStateId'] = countryStateId;

      final response = await _dio.patch('/store-api/context', data: payload);
      await TokenStorage.instance.saveContextTokenFromResponse(response);

      return Map<String, dynamic>.from(response.data ?? {});
    } catch (e) {
      rethrow;
    }
  }

  // Get cookie groups
  Future<Map<String, dynamic>> getCookieGroups() async {
    try {
      final response = await _dio.get('/store-api/cookie-groups');
      return Map<String, dynamic>.from(response.data ?? {});
    } catch (e) {
      rethrow;
    }
  }

  // Get available languages from Store API
  Future<List<Map<String, dynamic>>> getAvailableLanguages() async {
    try {
      final response = await _dio.get('/store-api/language');
      final data = response.data;
      if (data is Map && data['elements'] is List) {
        return List<Map<String, dynamic>>.from(data['elements']);
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  // Get available currencies from Store API
  Future<List<Map<String, dynamic>>> getAvailableCurrencies() async {
    try {
      final response = await _dio.get('/store-api/currency');
      final data = response.data;

      if (data is Map && data['elements'] is List) {
        return List<Map<String, dynamic>>.from(data['elements']);
      }

      // Try alternative format - maybe data is directly a list
      if (data is List) {
        return List<Map<String, dynamic>>.from(
            data.map((e) => Map<String, dynamic>.from(e as Map)));
      }

      return [];
    } catch (e) {
      rethrow;
    }
  }

  // Send contact form
  Future<void> sendContactForm({
    required String email,
    required String subject,
    required String comment,
    String? salutationId,
    String? firstName,
    String? lastName,
    String? phone,
    String? navigationId,
    String? slotId,
    String? cmsPageType,
    String? entityName,
  }) async {
    try {
      final payload = <String, dynamic>{
        'email': email,
        'subject': subject,
        'comment': comment,
      };
      if (salutationId != null) payload['salutationId'] = salutationId;
      if (firstName != null) payload['firstName'] = firstName;
      if (lastName != null) payload['lastName'] = lastName;
      if (phone != null) payload['phone'] = phone;
      if (navigationId != null) payload['navigationId'] = navigationId;
      if (slotId != null) payload['slotId'] = slotId;
      if (cmsPageType != null) payload['cmsPageType'] = cmsPageType;
      if (entityName != null) payload['entityName'] = entityName;

      await _dio.post('/store-api/contact-form', data: payload);
    } catch (e) {
      rethrow;
    }
  }
}
