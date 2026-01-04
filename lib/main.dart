import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'package:webview_flutter_web/webview_flutter_web.dart';

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
import 'core/services/shopware_api.dart';
import 'core/config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Web platform for webview
  if (kIsWeb) {
    WebViewPlatform.instance = WebWebViewPlatform();
  }

  // Hive init
  await Hive.initFlutter();

  // Load config before app starts
  // So the correct access key and primary color is used on first launch
  try {
    final api = ShopwareApi();
    final config = await api.getFlutterConfig();
    final primaryColorStr = config['primaryColor'] as String? ?? '#1976D2';
    AppConfig.update(newPrimaryColorHex: primaryColorStr);
  } catch (e) {
    // Continue even on error, fallback values will be used (default values)
  }

  runApp(
    ProviderScope(
      child: FlutterShopApp(),
    ),
  );
}

class FlutterShopApp extends StatelessWidget {
  const FlutterShopApp({super.key});

  Color _hexToColor(String hex) {
    try {
      hex = hex.replaceAll('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get primary color from AppConfig (will be updated after config is loaded)
    final primaryColor = _hexToColor(AppConfig.primaryColorHex);

    return MaterialApp.router(
      title: 'FlutterforShopware',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.light,
        ),
        appBarTheme: AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 1,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black87,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
        cardTheme: CardTheme(
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
        return CategoryScreen(categoryId: categoryId);
      },
    ),
    GoRoute(
      path: '/product/:productId',
      builder: (context, state) {
        final productId = state.pathParameters['productId']!;
        return ProductDetailScreen(productId: productId);
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
