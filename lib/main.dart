import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:go_router/go_router.dart';

import 'l10n/app_localizations.dart';
import 'core/locale/locale_notifier.dart';

import 'screens/home_screen.dart';
import 'screens/category_screen.dart';
import 'screens/product_detail_screen.dart';
import 'screens/search_screen.dart';
import 'screens/login_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/account_screen.dart';
import 'screens/register_screen.dart';
import 'screens/address_list_screen.dart';
import 'screens/address_edit_screen.dart';
import 'screens/wishlist_screen.dart';
import 'screens/reviews_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/order_list_screen.dart';
import 'screens/order_detail_screen.dart';
import 'screens/password_reset_request_screen.dart';
import 'screens/password_reset_confirm_screen.dart';
import 'screens/guest_order_lookup_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/contact_form_screen.dart';
import 'screens/storefront_webview_screen.dart';
import 'core/services/shopware_api.dart';
import 'core/config/app_config.dart';
import 'core/utils/color_utils.dart';
import 'core/utils/l10n_extension.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  final api = ShopwareApi();
  final bootstrapped = await api.bootstrapAccessKey();

  if (!bootstrapped) {
    runApp(const BootstrapErrorApp());
    return;
  }

  try {
    final config = await api.getFlutterConfig();
    final primaryColorStr = config['primaryColor'] as String? ?? '#1976D2';
    AppConfig.update(newPrimaryColorHex: primaryColorStr);
    final appName = config['appName'] as String?;
    if (appName != null && appName.isNotEmpty) {
      AppConfig.appName = appName;
    }
  } catch (_) {
    // Continue with defaults
  }

  runApp(
    const ProviderScope(
      child: FlutterShopApp(),
    ),
  );
}

/// Shown when bootstrap fails (missing secret, wrong channel, app disabled).
class BootstrapErrorApp extends StatelessWidget {
  const BootstrapErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 24),
                  Text(
                    context.l10n.bootstrapErrorTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.l10n.bootstrapErrorBody,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FlutterShopApp extends ConsumerWidget {
  const FlutterShopApp({super.key});

  Color _hexToColor(String hex) => ColorUtils.hexToColor(hex);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primaryColor = _hexToColor(AppConfig.primaryColorHex);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 1,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black87,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryColor, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
      routerConfig: _router,
    );
  }
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/category/:categoryId',
      builder: (context, state) {
        final categoryId = state.pathParameters['categoryId']!;
        return CategoryScreen(
          key: ValueKey(categoryId),
          categoryId: categoryId,
        );
      },
    ),
    GoRoute(
      path: '/product/:productId',
      builder: (context, state) {
        final productId = state.pathParameters['productId']!;
        return ProductDetailScreen(
          key: ValueKey(productId),
          productId: productId,
        );
      },
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) => const SearchScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/cart',
      builder: (context, state) => const CartScreen(),
    ),
    GoRoute(
      path: '/account',
      builder: (context, state) => const AccountScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/addresses',
      builder: (context, state) => const AddressListScreen(),
    ),
    GoRoute(
      path: '/address/edit',
      builder: (context, state) =>
          AddressEditScreen(initial: state.extra as Map<String, dynamic>?),
    ),
    GoRoute(
      path: '/wishlist',
      builder: (context, state) => const WishlistScreen(),
    ),
    GoRoute(
      path: '/product/:productId/reviews',
      builder: (context, state) =>
          ReviewsScreen(productId: state.pathParameters['productId']!),
    ),
    GoRoute(
      path: '/checkout',
      builder: (context, state) => const CheckoutScreen(),
    ),
    GoRoute(
      path: '/storefront',
      builder: (context, state) {
        final url = state.uri.queryParameters['url'];
        if (url == null || url.isEmpty) {
          return Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: Text(context.l10n.urlRequired),
              ),
            ),
          );
        }
        return StorefrontWebViewScreen(
          url: url,
          title: state.uri.queryParameters['title'] ?? 'Shop',
        );
      },
    ),
    GoRoute(
      path: '/orders',
      builder: (context, state) => const OrderListScreen(),
    ),
    GoRoute(
      path: '/order/:orderId',
      builder: (context, state) {
        final orderId = state.pathParameters['orderId']!;
        return OrderDetailScreen(orderId: orderId);
      },
    ),
    GoRoute(
      path: '/password-reset',
      builder: (context, state) => const PasswordResetRequestScreen(),
    ),
    GoRoute(
      path: '/password-reset/confirm/:hash',
      builder: (context, state) {
        final hash = state.pathParameters['hash']!;
        return PasswordResetConfirmScreen(hash: hash);
      },
    ),
    GoRoute(
      path: '/guest-orders',
      builder: (context, state) => const GuestOrderLookupScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/contact',
      builder: (context, state) => const ContactFormScreen(),
    ),
  ],
);
