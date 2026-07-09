import 'package:flutter/material.dart';
import '../core/utils/color_utils.dart';
import '../core/utils/logo_url.dart';
import '../core/utils/l10n_extension.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../core/locale/locale_notifier.dart';

import '../core/services/dynamic_layout_service.dart';
import '../core/services/shopware_api.dart';
import '../core/config/app_config.dart';
import '../core/utils/storefront_url.dart';
import '../core/utils/storefront_navigation.dart';
import '../core/storage.dart';
import '../data/repositories/auth_repository.dart';
import '../core/models/sales_channel_info.dart';
import '../core/models/category.dart';
import '../widgets/app_bar_brand_title.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final DynamicLayoutService _layoutService = DynamicLayoutService();
  final ShopwareApi _api = ShopwareApi();

  Widget? _layoutWidget;
  bool _isLoading = true;
  String? _error;
  late Color _primaryColor;
  Color get _onPrimaryColor => ColorUtils.foregroundOn(_primaryColor);

  Color get _onPrimaryMuted => ColorUtils.foregroundOnMuted(_primaryColor);

  Color get _onPrimaryDivider => ColorUtils.dividerOn(_primaryColor);

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
        title: Text(context.l10n.cookieTitle),
        content: Text(context.l10n.cookieMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.cookieDecline),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: ColorUtils.foregroundOn(_primaryColor),
            ),
            child: Text(context.l10n.cookieAccept),
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
        if (salesChannelInfo.languageId != null &&
            salesChannelInfo.languageId!.isNotEmpty) {
          final storedLangId = await TokenStorage.instance.loadLanguageId();
          if (storedLangId == null || storedLangId.isEmpty) {
            await TokenStorage.instance.saveLanguageId(
              salesChannelInfo.languageId!,
            );
          }
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

  /// Whether the current sales channel context has a logged-in customer.
  bool get _isLoggedIn => _salesChannelInfo?.hasCustomer ?? false;

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
              context.l10n.homeContentUnavailable,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _loadHomeLayout,
              icon: const Icon(Icons.refresh),
              label: Text(context.l10n.commonRetry),
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
        backgroundColor: _primaryColor,
        foregroundColor: ColorUtils.foregroundOn(_primaryColor),
        actions: [
          IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => context.go('/search')),
        ],
      ),
      drawer: _buildDrawer(context),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildAppBarTitle() {
    return AppBarBrandTitle(
      configLogoUrl: _appLogoUrl,
      salesChannelLogoUrl: _salesChannelInfo?.logoUrl,
      isLoading: _isLoading && LogoUrl.resolve(
            configLogoUrl: _appLogoUrl,
            salesChannelLogoUrl: _salesChannelInfo?.logoUrl,
          ) ==
          null,
      foregroundColor: _onPrimaryColor,
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
        final savedTag = await TokenStorage.instance.loadLocaleTag();
        final langId = _salesChannelInfo?.languageId;
        if (savedTag == null && langId != null) {
          await ref.read(localeProvider.notifier).setFromLanguageId(
                langId,
                _availableLanguages,
              );
        }
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

      if (languageId != null) {
        await ref.read(localeProvider.notifier).setFromLanguageId(
              languageId,
              _availableLanguages,
            );
      }

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
      // Save new language/currency information to state
      if (mounted) {
        var info = SalesChannelInfo.fromContext(newContext);
        if (languageId != null) {
          String? langName;
          for (final lang in _availableLanguages) {
            if (lang['id']?.toString() == languageId) {
              langName = lang['name']?.toString() ??
                  lang['translated']?['name']?.toString();
              break;
            }
          }
          info = info.copyWith(
            languageId: languageId,
            languageName: langName ?? info.languageName,
          );
        }
        if (currencyId != null) {
          String? currencyIso;
          for (final currency in _availableCurrencies) {
            if (currency['id']?.toString() == currencyId) {
              currencyIso = currency['isoCode']?.toString();
              break;
            }
          }
          info = info.copyWith(
            currencyId: currencyId,
            currencyIsoCode: currencyIso ?? info.currencyIsoCode,
          );
        }
        setState(() => _salesChannelInfo = info);
      }

      // Context updated, reload config + page in new language
      await _api.getFlutterConfig(forceRefresh: true);
      await _loadHomeLayout();

      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.languageCurrencyUpdated),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.languageCurrencyUpdateError(e.toString())),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  String? _getLogoUrl() => LogoUrl.resolve(
        configLogoUrl: _appLogoUrl,
        salesChannelLogoUrl: _salesChannelInfo?.logoUrl,
      );

  Widget _buildBody() {
    if (_currentIndex == 1) return const SizedBox.shrink();
    if (_currentIndex == 2) return const SizedBox.shrink();
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
          child: Text(context.l10n.commonError(_error!),
              style: const TextStyle(color: Colors.red)));
    }
    return _layoutWidget ??
        Center(child: Text(context.l10n.homeLayoutError));
  }

  Widget _buildDrawer(BuildContext context) {
    final hasCurrent =
        _drawerParentCategoryId != null && _drawerParentCategoryId!.isNotEmpty;
    return Drawer(
      // Drawer opened background color
      // primary color should be used
      backgroundColor: _primaryColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: _primaryColor,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo - get from all sources (AppConfig > App Logo URL > Sales Channel Info)
                  Builder(
                    builder: (context) {
                      final logoUrl = _getLogoUrl();
                      if (logoUrl != null && logoUrl.isNotEmpty) {
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final maxWidth = constraints.maxWidth * 0.75;
                            const maxHeight = 52.0;
                            
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
                                        return Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: _onPrimaryColor,
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        return Icon(
                                          Icons.store,
                                          size: 40,
                                          color: _onPrimaryColor,
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
                                      placeholder: (context, url) => Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: _onPrimaryColor,
                                        ),
                                      ),
                                      errorWidget: (context, url, error) {
                                        return Icon(
                                          Icons.store,
                                          size: 40,
                                          color: _onPrimaryColor,
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
                      return Icon(
                        Icons.store,
                        size: 40,
                        color: _onPrimaryColor,
                      );
                    },
                  ),
                  Divider(
                    color: _onPrimaryDivider,
                    thickness: 1,
                    height: 8,
                  ),
                  const SizedBox(height: 2),
                  // Language and Currency selection side by side
                  SizedBox(
                    height: 28,
                    child: Row(
                      children: [
                        // Language selection
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.language,
                                size: 14,
                                color: _onPrimaryMuted,
                              ),
                              const SizedBox(width: 1),
                              Expanded(
                                child: DropdownButton<String>(
                                  value:
                                      _salesChannelInfo?.languageId?.toString(),
                                  isExpanded: true,
                                  isDense: true, // Yüksekliği azalt
                                  underline: const SizedBox(),
                                  dropdownColor: _primaryColor,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _onPrimaryColor,
                                  ),
                                  icon: Icon(
                                    Icons.arrow_drop_down,
                                    color: _onPrimaryMuted,
                                    size: 16,
                                  ),
                                  items: _availableLanguages.isEmpty
                                      ? []
                                      : _availableLanguages.map((lang) {
                                          final id = lang['id']?.toString();
                                          final name =
                                              lang['name']?.toString() ??
                                                  lang['translated']?['name']
                                                      ?.toString() ??
                                                  context.l10n.commonUnknown;
                                          return DropdownMenuItem<String>(
                                            value: id,
                                            child: Text(
                                              name,
                                              style: TextStyle(
                                                  color: _onPrimaryColor,
                                                  fontSize: 14),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          );
                                        }).toList(),
                                  onChanged: (String? newLanguageId) {
                                    if (newLanguageId != null &&
                                        newLanguageId !=
                                            _salesChannelInfo?.languageId) {
                                      _updateContext(
                                          languageId: newLanguageId);
                                    }
                                  },
                                  hint: _loadingLanguagesCurrencies
                                      ? SizedBox(
                                          width: 10,
                                          height: 10,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 1.5,
                                            color: _onPrimaryMuted,
                                          ),
                                        )
                                      : Text(
                                          _salesChannelInfo?.languageName ??
                                              context.l10n.languageLabel,
                                          style: TextStyle(
                                            color: _onPrimaryMuted,
                                            fontSize: 11,
                                          ),
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
                                    size: 14, color: _onPrimaryMuted);
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
                                              style: TextStyle(
                                                  color: _onPrimaryColor,
                                                  fontSize: 14),
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
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _onPrimaryColor,
                                    ),
                                    icon: Icon(Icons.arrow_drop_down,
                                        color: _onPrimaryMuted, size: 18),
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
                                        ? SizedBox(
                                            width: 10,
                                            height: 10,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 1.5,
                                              color: _onPrimaryMuted,
                                            ),
                                          )
                                        : Text(
                                            _salesChannelInfo
                                                    ?.currencyIsoCode ??
                                                context.l10n.currencyLabel,
                                            style: TextStyle(
                                                color: _onPrimaryMuted,
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
                  ),
                ],
              ),
            ),
            // Header altındaki Home ve Categories satırlarını beyaz zemin üzerinde göster
            Material(
              color: Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.home),
                    title: Text(context.l10n.navHome),
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  ListTile(
                    leading: const Icon(Icons.category),
                    title: Text(
                      context.l10n.commonCategories,
                      style: const TextStyle(color: Colors.black),
                    ),
                    onTap: () {
                      setState(() {
                        _drawerParentCategoryId = null;
                        _drawerBreadcrumb.clear();
                        _drawerCurrentCategoryName = null;
                      });
                    },
                  ),
                ],
              ),
            ),
            if (hasCurrent) ...[
              Material(
                color: Colors.white,
                child: ListTile(
                  leading: const Icon(Icons.shopping_bag_outlined),
                  title: Text(_drawerCurrentCategoryName ??
                      context.l10n.showProductsTooltip),
                  onTap: () {
                    final id = _drawerParentCategoryId!;
                    Navigator.of(context).pop();
                    context.go('/category/$id');
                  },
                ),
              ),
            ],
            Expanded(
              
              child: FutureBuilder<List<dynamic>>(
              
                future: _getCategoriesForDrawer(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      color: Colors.white,
                      child: const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: LinearProgressIndicator(),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    // Error loading categories
                    return Container(
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(context.l10n.categoriesNotAvailable),
                      ),
                    );
                  }
                  final elements = snapshot.data ?? [];
                  if (elements.isEmpty) {
                    return Container(
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(context.l10n.categoryNotFound),
                      ),
                    );
                  }
                  return Material(
                    color: Colors.white,
                    child: ListView.builder(
                      itemCount: elements.length,
                      itemBuilder: (context, index) {
                        final cat = elements[index];
                        // Category object or map
                        final String name;
                        final String id;

                        if (cat is Category) {
                          // Category object - name is now coming from translated.name
                          name =
                              cat.name.isNotEmpty ? cat.name : context.l10n.unnamedCategory;
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
                          name = context.l10n.unknownCategory;
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
                            tooltip: context.l10n.showProductsTooltip,
                            onPressed: () {
                              Navigator.of(context).pop();
                              context.go('/category/$id');
                            },
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            if (_isLoggedIn)
              ListTile(
                leading: const Icon(Icons.logout),
                title: Text(context.l10n.commonLogout),
                onTap: () async {
                  Navigator.of(context).pop();
                  try {
                    await AuthRepository().logout();
                    if (mounted) {
                      setState(() => _salesChannelInfo = null);
                      await _loadHomeLayout();
                    }
                    if (mounted && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(context.l10n.commonLoggedOut)),
                      );
                    }
                  } catch (e) {
                    if (mounted && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(context.l10n.commonError(e.toString())),
                        ),
                      );
                    }
                  }
                },
              )
            else
              Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.login),
                    title: Text(context.l10n.commonLogin),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go('/login');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.person_add),
                    title: Text(context.l10n.commonRegister),
                    onTap: () {
                      Navigator.of(context).pop();
                      StorefrontNavigation.open(
                        context,
                        StorefrontUrl.accountRegister(),
                        title: context.l10n.commonRegister,
                      );
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    final l10n = context.l10n;
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _currentIndex,
      backgroundColor: Colors.white,
      selectedItemColor: ColorUtils.accentOnSurface(
        _primaryColor,
        Colors.white,
      ),
      unselectedItemColor: Colors.grey,
      onTap: (index) {
        setState(() => _currentIndex = index);
        if (index == 1) {
          context.go('/cart');
        } else if (index == 2) {
          context.go('/account');
        }
      },
      items: [
        BottomNavigationBarItem(icon: const Icon(Icons.home), label: l10n.navHome),
        BottomNavigationBarItem(
          icon: const Icon(Icons.shopping_cart),
          label: l10n.navCart,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.person),
          label: l10n.navAccount,
        ),
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
