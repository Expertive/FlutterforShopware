import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/config/app_config.dart' as AppConst;

class MainDrawer extends StatelessWidget {
  const MainDrawer({
    super.key,
    required this.headerColor,
  });

  final Color headerColor;

  void _navigate(BuildContext context, String route) {
    Navigator.of(context).pop();
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: headerColor),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.storefront,
                    size: 56,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppConst.AppConfig.appName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Where do you want to continue?',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            _DrawerTile(
              icon: Icons.home,
              label: 'Home',
              onTap: () => _navigate(context, '/'),
            ),
            _DrawerTile(
              icon: Icons.search,
              label: 'Search',
              onTap: () => _navigate(context, '/search'),
            ),
            _DrawerTile(
              icon: Icons.shopping_cart_outlined,
              label: 'Cart',
              onTap: () => _navigate(context, '/cart'),
            ),
            _DrawerTile(
              icon: Icons.favorite_border,
              label: 'Wishlist',
              onTap: () => _navigate(context, '/wishlist'),
            ),
            _DrawerTile(
              icon: Icons.person_outline,
              label: 'My Account',
              onTap: () => _navigate(context, '/account'),
            ),
            const Spacer(),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Text(
                '© ${DateTime.now().year} ${AppConst.AppConfig.appName}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: onTap,
    );
  }
}
