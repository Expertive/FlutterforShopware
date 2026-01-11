import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/repositories/wishlist_repository.dart';
import '../core/config/app_config.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final WishlistRepository _repo = WishlistRepository();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = <Map<String, dynamic>>[];
  Color _primaryColor = Colors.blue;

  @override
  void initState() {
    super.initState();
    _primaryColor = _hexToColor(AppConfig.primaryColorHex);
    _load();
  }

  Color _hexToColor(String hex) {
    try {
      hex = hex.replaceAll('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return Colors.blue;
    }
  }

  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _repo.list();
      setState(() => _items = list);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _handleBack(context),
        ),
        title: const Text('İstek Listem'),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text('Hata: $_error'));
    if (_items.isEmpty) return const Center(child: Text('İstek listeniz boş'));
    return ListView.separated(
      itemCount: _items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final p = _items[index];
        final name = p['name']?.toString() ?? 'Product';
        final id = p['id']?.toString() ?? '';
        return ListTile(
          title: Text(name),
          subtitle: Text(id),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              try {
                await _repo.remove(id);
                await _load();
              } catch (e) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('Hata: $e')));
              }
            },
          ),
        );
      },
    );
  }
}
