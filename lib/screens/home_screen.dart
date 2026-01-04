import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/services/dynamic_layout_service.dart';
import '../core/services/shopware_api.dart';
import '../core/config.dart';
import '../core/config/app_config.dart' as AppConfigCore;
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

  @override
  void initState() {
    super.initState();
    // Başlangıçta AppConfig'den primary color'ı al (main()'de yüklenmiş olacak)
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

      // Config yüklendikten sonr a sales channel context'i yüklenir
      // So the correct baseUrl is used for requests
      try {
        final contextData = await _api.getSalesChannelContext();
        final salesChannelInfo = SalesChannelInfo.fromContext(contextData);
        if (mounted) {
          setState(() {
            _salesChannelInfo = salesChannelInfo;
          });
        }
      } catch (e) {
        // Error loading sales channel context (continue even on error, use default values)
        // Continue even on error, use default values
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
              _layoutWidget = layoutWidget ?? _buildTestLayout();
              _isLoading = false;
            });
          }
        } catch (layoutError) {
          // Layout loading error - show fallback layout (continue even on error, use default values)
          // Layout loading error - show fallback layout
          if (mounted) {
            setState(() {
              _layoutWidget = _buildTestLayout();
              _isLoading = false;
            });
          }
        }
      } else {
        setState(() {
          _layoutWidget = _buildTestLayout();
          _isLoading = false;
        });
      }
    } catch (e) {
      // General error - show fallback layout
      if (mounted) {
        setState(() {
          _error =
              null; // Error message - show fallback layout (continue even on error, use default values)
          _isLoading = false;
          _layoutWidget = _buildTestLayout();
        });
      }
    }
  }

  /// Drawer için kategori listesini getir
  /// Başlangıçta (_drawerParentCategoryId null) sadece alt kategorileri göster
  /// Ana kategori seçildiğinde o ana kategorinin alt kategorilerini göster
  Future<List<Category>> _getCategoriesForDrawer() async {
    if (_drawerParentCategoryId != null) {
      // Ana kategori seçilmişse, o ana kategorinin alt kategorilerini getir
      return await _api.getCategories(parentId: _drawerParentCategoryId);
    } else {
      // Başlangıçta: Tüm kategorileri al (filtreleme yapmadan), sadece alt kategorileri (parentId != null) döndür
      final allCategories = await _api.getCategories(limit: 100, showAll: true);
      // Sadece alt kategorileri filtrele (parentId != null)
      return allCategories.where((cat) => cat.parentId != null).toList();
    }
  }

  Widget _buildTestLayout() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FlutterforShopware',
            style: TextStyle(
                fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Welcome!',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                  SizedBox(height: 8),
                  Text('Welcome to FlutterforShopware.',
                      style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _buildAppBarTitle(),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => context.go('/search')),
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

    // First check logo URL from AppConfig, then state variable, then salesChannelInfo
    final logoUrl = AppConfigCore.AppConfig.logoUrl ??
        _appLogoUrl ??
        _salesChannelInfo?.logoUrl;

    // Logo URL priority: AppConfig > App Logo URL > Sales Channel Info

    // If logo exists, show logo + name, otherwise only name
    if (logoUrl != null && logoUrl.isNotEmpty) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // On Web platform, CachedNetworkImage may cause CORS issues, so use Image.network
          kIsWeb
              ? Image.network(
                  logoUrl,
                  width: 32,
                  height: 32,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    // Image.network error
                    return const Icon(Icons.store, size: 24);
                  },
                )
              : CachedNetworkImage(
                  imageUrl: logoUrl,
                  width: 32,
                  height: 32,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  errorWidget: (context, url, error) {
                    // CachedNetworkImage error
                    return const Icon(Icons.store, size: 24);
                  },
                ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              _salesChannelInfo?.name ?? AppConfigCore.AppConfig.appName,
              style: const TextStyle(fontSize: 18),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }
    // SalesChannelInfo exists, otherwise use app name from AppConfig
    return Text(_salesChannelInfo?.name ?? AppConfigCore.AppConfig.appName);
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  if (_salesChannelInfo?.logoUrl != null &&
                      _salesChannelInfo!.logoUrl!.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: _salesChannelInfo!.logoUrl!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const SizedBox(
                        width: 80,
                        height: 80,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.store,
                        size: 60,
                        color: Colors.white,
                      ),
                    )
                  else
                    const Icon(
                      Icons.store,
                      size: 60,
                      color: Colors.white,
                    ),
                  const SizedBox(height: 12),
                  // Mağaza adı
                  Text(
                    _salesChannelInfo?.name ?? AppConfigCore.AppConfig.appName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (_salesChannelInfo?.currencyIsoCode != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _salesChannelInfo!.currencyIsoCode!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () => Navigator.of(context).pop(),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text('Categories',
                  style: TextStyle(fontWeight: FontWeight.bold)),
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
              ListTile(
                leading: const Icon(Icons.arrow_upward),
                title: const Text('Parent Category'),
                onTap: () {
                  if (_drawerBreadcrumb.isNotEmpty) {
                    setState(() {
                      _drawerBreadcrumb.removeLast();
                      _drawerParentCategoryId = _drawerBreadcrumb.isEmpty
                          ? null
                          : _drawerBreadcrumb.last;
                      _drawerCurrentCategoryName = null; // reset name on up
                    });
                  } else {
                    setState(() {
                      _drawerParentCategoryId = null;
                      _drawerCurrentCategoryName = null;
                    });
                  }
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
                        // Category objesi - name artık translated.name'den geliyor
                        name =
                            cat.name.isNotEmpty ? cat.name : 'Unnamed Category';
                        id = cat.id;
                      } else if (cat is Map) {
                        // Map formatında gelirse - translated.name kontrol et
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
            FutureBuilder<String?>(
              future: TokenStorage.instance.loadContextToken(),
              builder: (context, snapshot) {
                final hasToken =
                    (snapshot.data != null && snapshot.data!.isNotEmpty);
                if (hasToken) {
                  return ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Logout'),
                    onTap: () async {
                      Navigator.of(context).pop();
                      try {
                        await AuthRepository().logout();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Logged out')));
                        }
                      } catch (e) {
                        if (mounted) {
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
                        // Shopware storefront register sayfasını browser'da aç
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
          context.go('/cart');
        } else if (index == 2) {
          context.go('/account');
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Cart'),
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
