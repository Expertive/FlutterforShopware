import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/painting.dart' show imageCache;
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/services/dynamic_layout_service.dart';
import '../core/services/shopware_api.dart';
import '../core/config/app_config.dart';
import '../core/storage.dart';
import '../data/repositories/auth_repository.dart';
import '../core/models/sales_channel_info.dart';
import '../core/models/category.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DynamicLayoutService _layoutService = DynamicLayoutService();
  final ShopwareApi _api = ShopwareApi();

  Widget? _layoutWidget;
  bool _isLoading = true;
  String? _error;
  late Color _primaryColor;
  SalesChannelInfo? _salesChannelInfo;
  String? _appLogoUrl; // Config'den gelen logo URL'i
  int _currentIndex = 0;
  String? _drawerParentCategoryId; // current level
  final List<String> _drawerBreadcrumb = <String>[]; // path stack
  String? _drawerCurrentCategoryName; // current level name

  // For language and currency selection
  List<Map<String, dynamic>> _availableLanguages = [];
  List<Map<String, dynamic>> _availableCurrencies = [];
  bool _loadingLanguagesCurrencies = false;

  @override
  void initState() {
    super.initState();
    // Start default color
    _primaryColor = _hexToColor(AppConfig.primaryColorHex);
    _loadHomeLayout();
    _checkCookieConsent();
  }

  Future<void> _checkCookieConsent() async {
    final hasConsent = await TokenStorage.instance.getCookieConsent();
    if (!hasConsent && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showCookieDialog();
      });
    }
  }

  Future<void> _showCookieDialog() async {
    final consent = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Cookie Usage'),
        content: const Text(
          'This website uses cookies to improve your experience. '
          'By continuing to use our site, you agree to our cookie policy.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Decline'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Accept'),
          ),
        ],
      ),
    );

    if (consent != null) {
      await TokenStorage.instance.setCookieConsent(consent);
      // Cookie consent local stored in storage, this is enough
    }
  }

  Future<void> _loadHomeLayout() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // First load config (baseUrl can be updated)
      final config = await _api.getFlutterConfig();
      final apiBaseUrl = (config['apiBaseUrl'] as String?)?.trim();
      if (apiBaseUrl != null && apiBaseUrl.isNotEmpty) {
        AppConfig.update(newBaseUrl: apiBaseUrl);
        // Base URL updated
      }

      // After config is loaded, load sales channel context
      // So the correct baseUrl is used for requests
      try {
        final contextData = await _api.getSalesChannelContext();
        final salesChannelInfo = SalesChannelInfo.fromContext(contextData);
        if (mounted) {
          setState(() {
            _salesChannelInfo = salesChannelInfo;
          });
        }
        // Load language and currency lists
        _loadLanguagesAndCurrencies(contextData);
      } catch (e) {
        // Error loading sales channel context (continue even on error, use default values)
      }

      final primaryColorStr = config['primaryColor'] as String? ?? '#1976D2';
      final logoUrl = config['logoUrl'] as String?;
      setState(() {
        _primaryColor = _hexToColor(primaryColorStr);
        _appLogoUrl = logoUrl;
      });

      final homePageId = config['pages']?['home'];
      if (homePageId != null && homePageId.isNotEmpty) {
        try {
          final layoutWidget =
              await _layoutService.loadLayout(homePageId, context);
          if (mounted) {
            setState(() {
              _layoutWidget = layoutWidget ?? _buildEmptyLayout();
              _isLoading = false;
            });
          }
        } catch (layoutError) {
          // Layout loading error - show fallback layout (continue even on error, use default values)
          // Layout loading error - show fallback layout
          if (mounted) {
            setState(() {
              _layoutWidget = _buildEmptyLayout();
              _isLoading = false;
            });
          }
        }
      } else {
        setState(() {
          _layoutWidget = _buildEmptyLayout();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _layoutWidget = _buildEmptyLayout();
        });
      }
    }
  }

  /// Check if user is actually logged in (not just has context token)
  Future<bool> _checkIfLoggedIn() async {
    try {
      await AuthRepository().me();
      return true;
    } catch (e) {
      // 403 or any error means not logged in
      return false;
    }
  }

  /// Get category list for drawer
  /// Initially (_drawerParentCategoryId null) only show subcategories
  /// When a category is selected, show the subcategories of that category
  Future<List<Category>> _getCategoriesForDrawer() async {
    if (_drawerParentCategoryId != null) {
      // When a category is selected, get the subcategories of that category
      return await _api.getCategories(parentId: _drawerParentCategoryId);
    } else {
      // Initially: Get all categories (without filtering), only return subcategories (parentId != null)
      final allCategories = await _api.getCategories(limit: 100, showAll: true);
      // Only filter subcategories (parentId != null)
      return allCategories.where((cat) => cat.parentId != null).toList();
    }
  }

  Widget _buildEmptyLayout() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.storefront_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              AppConfig.appName,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Home page content is not available.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _loadHomeLayout,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _buildAppBarTitle(),
        centerTitle: true,
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
              icon: const Icon(Icons.shopping_cart),
              onPressed: () => context.go('/cart')),
        ],
      ),
      drawer: _buildDrawer(context),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildAppBarTitle() {
    // If still loading and salesChannelInfo is null, show loading
    if (_isLoading && _salesChannelInfo == null && _appLogoUrl == null) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    // AppBar'da sadece text göster (logo DrawerHeader'da)
    return Text(
      _salesChannelInfo?.name ?? AppConfig.appName,
      style: const TextStyle(fontSize: 18),
      overflow: TextOverflow.ellipsis,
    );
  }

  // Load language and currency lists
  Future<void> _loadLanguagesAndCurrencies(
      Map<String, dynamic>? contextData) async {
    if (_loadingLanguagesCurrencies) return;

    setState(() {
      _loadingLanguagesCurrencies = true;
    });

    try {
      final salesChannel =
          contextData?['salesChannel'] as Map<String, dynamic>?;

      // First load languages and currencies from sales channel
      var availableLanguages = salesChannel?['languages'] as List? ?? [];
      var availableCurrencies = salesChannel?['currencies'] as List? ?? [];

      // If not available in sales channel, get from API
      if (availableLanguages.isEmpty) {
        try {
          availableLanguages = await _api.getAvailableLanguages();
        } catch (e) {
          // Silently fail
        }
      }

      if (availableCurrencies.isEmpty) {
        try {
          availableCurrencies = await _api.getAvailableCurrencies();
        } catch (e) {
          // Silently fail
        }
      }

      if (mounted) {
        setState(() {
          _availableLanguages = List<Map<String, dynamic>>.from(
            availableLanguages.map((e) => Map<String, dynamic>.from(e as Map)),
          );
          _availableCurrencies = List<Map<String, dynamic>>.from(
            availableCurrencies.map((e) => Map<String, dynamic>.from(e as Map)),
          );
          _loadingLanguagesCurrencies = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingLanguagesCurrencies = false;
        });
      }
    }
  }

  // Update context (language or currency change)
  Future<void> _updateContext({String? languageId, String? currencyId}) async {
    try {
      // Update context
      await _api.updateContext(
        languageId: languageId,
        currencyId: currencyId,
      );

      // Wait for token to be saved
      // Wait for SharedPreferences to commit
      await Future.delayed(const Duration(milliseconds: 200));

      // Clear caches - to reload content after language change
      try {
        // Clear image cache
        imageCache.clear();
        imageCache.clearLiveImages();
      } catch (e) {
        // Silent fail on image cache clear error
      }

      // Layout widget'ını reset - to be loaded again in new language
      if (mounted) {
        setState(() {
          _layoutWidget = null;
          _isLoading = true;
        });
      }

      // Verify new context by reloading context
      // This ensures that new context token is used in API calls
      // Also verifies that new language information is in the context
      final newContext = await _api.getSalesChannelContext();
      final newLanguage = newContext['language'] as Map<String, dynamic>?;

      // Save new language information to state
      if (mounted && newLanguage != null) {
        final salesChannelInfo = SalesChannelInfo.fromContext(newContext);
        setState(() {
          _salesChannelInfo = salesChannelInfo;
        });
      }

      // Context updated, reload page
      await _loadHomeLayout();

      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Language/Currency updated'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Update error: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Get logo URL and normalize it (can be used for AppBar and DrawerHeader)
  String? _getLogoUrl() {
    // First check logo URL from AppConfig, then state variable, then salesChannelInfo
    String? logoUrl =
        AppConfig.logoUrl ?? _appLogoUrl ?? _salesChannelInfo?.logoUrl;

    // Logo URL priority: AppConfig > App Logo URL > Sales Channel Info

    // If logoUrl is relative, make it absolute by combining with base URL
    if (logoUrl != null && logoUrl.isNotEmpty) {
      if (logoUrl.startsWith('/') ||
          (!logoUrl.startsWith('http://') && !logoUrl.startsWith('https://'))) {
        // Relative URL - combine with base URL
        String baseUrl = AppConfig.baseUrl;
        if (baseUrl.endsWith('/store-api')) {
          baseUrl = baseUrl.replaceAll('/store-api', '');
        }
        if (baseUrl.endsWith('/public')) {
          baseUrl = baseUrl.replaceAll('/public', '');
        }
        if (baseUrl.endsWith('/')) {
          baseUrl = baseUrl.substring(0, baseUrl.length - 1);
        }
        if (!logoUrl.startsWith('/')) {
          logoUrl = '$baseUrl/$logoUrl';
        } else {
          logoUrl = '$baseUrl$logoUrl';
        }
      }
    }

    return logoUrl;
  }

  Widget _buildBody() {
    if (_currentIndex == 1) return const SizedBox.shrink();
    if (_currentIndex == 2) return const SizedBox.shrink();
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
          child: Text('Error: $_error',
              style: const TextStyle(color: Colors.red)));
    }
    return _layoutWidget ?? const Center(child: Text('Layout loading error'));
  }

  Widget _buildDrawer(BuildContext context) {
    final hasCurrent =
        _drawerParentCategoryId != null && _drawerParentCategoryId!.isNotEmpty;
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: _primaryColor,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo - get from all sources (AppConfig > App Logo URL > Sales Channel Info)
                  Builder(
                    builder: (context) {
                      final logoUrl = _getLogoUrl();
                      if (logoUrl != null && logoUrl.isNotEmpty) {
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            // DrawerHeader'ın mevcut genişliğine göre maksimum boyutlar
                            final maxWidth = constraints.maxWidth * 0.8;
                            final maxHeight = 80.0;
                            
                            return kIsWeb
                                ? SizedBox(
                                    width: maxWidth,
                                    height: maxHeight,
                                    child: Image.network(
                                      logoUrl,
                                      fit: BoxFit.contain,
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return const Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(
                                          Icons.store,
                                          size: 40,
                                          color: Colors.white,
                                        );
                                      },
                                    ),
                                  )
                                : SizedBox(
                                    width: maxWidth,
                                    height: maxHeight,
                                    child: CachedNetworkImage(
                                      imageUrl: logoUrl,
                                      fit: BoxFit.contain,
                                      memCacheWidth: 200,
                                      fadeInDuration:
                                          const Duration(milliseconds: 200),
                                      placeholder: (context, url) => const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      ),
                                      errorWidget: (context, url, error) {
                                        return const Icon(
                                          Icons.store,
                                          size: 40,
                                          color: Colors.white,
                                        );
                                      },
                                      httpHeaders: const {
                                        'Accept': 'image/*',
                                      },
                                    ),
                                  );
                          },
                        );
                      }
                      return const Icon(
                        Icons.store,
                        size: 40,
                        color: Colors.white,
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  // Language and Currency selection side by side
                  Row(
                    children: [
                      // Language selection
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.language,
                                size: 14, color: Colors.white70),
                            const SizedBox(width: 4),
                            Expanded(
                              child: DropdownButton<String>(
                                value:
                                    _salesChannelInfo?.languageId?.toString(),
                                isExpanded: true,
                                underline: const SizedBox(),
                                dropdownColor: _primaryColor,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                ),
                                icon: const Icon(Icons.arrow_drop_down,
                                    color: Colors.white70, size: 18),
                                items: _availableLanguages.isEmpty
                                    ? []
                                    : _availableLanguages.map((lang) {
                                        final id = lang['id']?.toString();
                                        final name = lang['name']?.toString() ??
                                            lang['translated']?['name']
                                                ?.toString() ??
                                            'Unknown';
                                        return DropdownMenuItem<String>(
                                          value: id,
                                          child: Text(
                                            name,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList(),
                                onChanged: (String? newLanguageId) {
                                  if (newLanguageId != null &&
                                      newLanguageId !=
                                          _salesChannelInfo?.languageId) {
                                    _updateContext(languageId: newLanguageId);
                                  }
                                },
                                hint: _loadingLanguagesCurrencies
                                    ? const SizedBox(
                                        width: 10,
                                        height: 10,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1.5,
                                          color: Colors.white70,
                                        ),
                                      )
                                    : Text(
                                        _salesChannelInfo?.languageName ??
                                            'Language',
                                        style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 11),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Currency selection
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Builder(
                              builder: (context) {
                                // Get current currency ISO code to show appropriate icon
                                final currentCurrencyIso = _salesChannelInfo
                                    ?.currencyIsoCode
                                    ?.toUpperCase();
                                IconData currencyIcon;
                                if (currentCurrencyIso == 'EUR') {
                                  currencyIcon = Icons.euro;
                                } else if (currentCurrencyIso == 'USD') {
                                  currencyIcon = Icons.attach_money;
                                } else if (currentCurrencyIso == 'GBP') {
                                  currencyIcon = Icons.currency_pound;
                                } else if (currentCurrencyIso == 'JPY') {
                                  currencyIcon = Icons.currency_yen;
                                } else {
                                  currencyIcon = Icons.attach_money;
                                }
                                return Icon(currencyIcon,
                                    size: 14, color: Colors.white70);
                              },
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Builder(
                                builder: (context) {
                                  // Get current currency ID as string
                                  final currentCurrencyId =
                                      _salesChannelInfo?.currencyId?.toString();

                                  // Build currency items
                                  final currencyItems = _availableCurrencies
                                          .isEmpty
                                      ? <DropdownMenuItem<String>>[]
                                      : _availableCurrencies.where((currency) {
                                          final id = currency['id']?.toString();
                                          return id != null && id.isNotEmpty;
                                        }).map((currency) {
                                          final id =
                                              currency['id']?.toString() ?? '';
                                          final isoCode =
                                              currency['isoCode']?.toString() ??
                                                  '';
                                          final name = currency['name']
                                                  ?.toString() ??
                                              currency['translated']?['name']
                                                  ?.toString() ??
                                              isoCode;
                                          return DropdownMenuItem<String>(
                                            value: id,
                                            child: Text(
                                              '$isoCode - $name',
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          );
                                        }).toList();

                                  // Check if current currency ID exists in items
                                  final currencyIdExists = currencyItems.any(
                                      (item) =>
                                          item.value == currentCurrencyId);

                                  return DropdownButton<String>(
                                    value: currencyIdExists
                                        ? currentCurrencyId
                                        : null,
                                    isExpanded: true,
                                    underline: const SizedBox(),
                                    dropdownColor: _primaryColor,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.white,
                                    ),
                                    icon: const Icon(Icons.arrow_drop_down,
                                        color: Colors.white70, size: 18),
                                    items: currencyItems,
                                    onChanged: (String? newCurrencyId) {
                                      if (newCurrencyId != null &&
                                          newCurrencyId.isNotEmpty) {
                                        final currentCurrencyId =
                                            _salesChannelInfo?.currencyId
                                                ?.toString();
                                        if (newCurrencyId !=
                                            currentCurrencyId) {
                                          _updateContext(
                                              currencyId: newCurrencyId);
                                        }
                                      }
                                    },
                                    hint: _loadingLanguagesCurrencies
                                        ? const SizedBox(
                                            width: 10,
                                            height: 10,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 1.5,
                                              color: Colors.white70,
                                            ),
                                          )
                                        : Text(
                                            _salesChannelInfo
                                                    ?.currencyIsoCode ??
                                                'Currency',
                                            style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 11),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () => Navigator.of(context).pop(),
            ),
            InkWell(
              onTap: () {
                setState(() {
                  _drawerParentCategoryId = null;
                  _drawerBreadcrumb.clear();
                  _drawerCurrentCategoryName = null;
                });
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text('Categories',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            if (hasCurrent) ...[
              ListTile(
                leading: const Icon(Icons.shopping_bag_outlined),
                // Use category name if known, otherwise fallback text
                title: Text(_drawerCurrentCategoryName ??
                    'Show products of this category'),
                onTap: () {
                  final id = _drawerParentCategoryId!;
                  Navigator.of(context).pop();
                  context.go('/category/$id');
                },
              ),
            ],
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: _getCategoriesForDrawer(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: LinearProgressIndicator(),
                    );
                  }
                  if (snapshot.hasError) {
                    // Error loading categories
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Categories not available'),
                    );
                  }
                  final elements = snapshot.data ?? [];
                  if (elements.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Category not found'),
                    );
                  }
                  return ListView.builder(
                    itemCount: elements.length,
                    itemBuilder: (context, index) {
                      final cat = elements[index];
                      // Category object or map
                      final String name;
                      final String id;

                      if (cat is Category) {
                        // Category object - name is now coming from translated.name
                        name =
                            cat.name.isNotEmpty ? cat.name : 'Unnamed Category';
                        id = cat.id;
                      } else if (cat is Map) {
                        // If map is received, check translated.name
                        final mapCat = cat as Map<String, dynamic>;
                        if (mapCat['name'] != null &&
                            mapCat['name'].toString().isNotEmpty) {
                          name = mapCat['name'].toString();
                        } else if (mapCat['translated'] != null &&
                            mapCat['translated'] is Map) {
                          final translated =
                              mapCat['translated'] as Map<String, dynamic>;
                          name = translated['name']?.toString() ??
                              'Unnamed Category';
                        } else {
                          name = 'Unnamed Category';
                        }
                        id = (mapCat['id']?.toString() ?? '');
                      } else {
                        name = 'Unknown Category';
                        id = '';
                      }

                      return ListTile(
                        dense: true,
                        title: Text(name),
                        onTap: () {
                          // drill-down to children and store current name
                          setState(() {
                            _drawerBreadcrumb.add(id);
                            _drawerParentCategoryId = id;
                            _drawerCurrentCategoryName = name;
                          });
                        },
                        trailing: IconButton(
                          icon: const Icon(Icons.chevron_right),
                          tooltip: 'Show products',
                          onPressed: () {
                            Navigator.of(context).pop();
                            context.go('/category/$id');
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            FutureBuilder<bool>(
              future: _checkIfLoggedIn(),
              builder: (context, snapshot) {
                final isLoggedIn = snapshot.data ?? false;
                if (isLoggedIn) {
                  return ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Logout'),
                    onTap: () async {
                      Navigator.of(context).pop();
                      try {
                        await AuthRepository().logout();
                        if (mounted && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Logged out')));
                        }
                      } catch (e) {
                        if (mounted && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')));
                        }
                      }
                    },
                  );
                }
                return Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.login),
                      title: const Text('Login'),
                      onTap: () {
                        Navigator.of(context).pop();
                        context.go('/login');
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.person_add),
                      title: const Text('Register'),
                      onTap: () async {
                        Navigator.of(context).pop();
                        // Open Shopware storefront register page in browser
                        final baseUrl = AppConfig.baseUrl.endsWith('/')
                            ? AppConfig.baseUrl
                            : '${AppConfig.baseUrl}/';
                        final registerUrl = '${baseUrl}account/register';
                        final uri = Uri.parse(registerUrl);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                        }
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _currentIndex,
      backgroundColor: Colors.white,
      selectedItemColor: _primaryColor,
      unselectedItemColor: Colors.grey,
      onTap: (index) {
        setState(() => _currentIndex = index);
        if (index == 1) {
          context.go('/search');
        } else if (index == 2) {
          context.go('/account');
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
      ],
    );
  }

  Color _hexToColor(String hex) {
    try {
      hex = hex.replaceAll('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      return Colors.blue;
    }
  }
}
