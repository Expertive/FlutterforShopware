import 'package:flutter/material.dart';
import '../core/utils/color_utils.dart';
import 'package:go_router/go_router.dart';

import '../data/repositories/cart_repository.dart';
import '../data/repositories/auth_repository.dart';
import '../core/services/shopware_api.dart';
import '../core/config/app_config.dart';
import '../core/models/sales_channel_info.dart';
import '../core/utils/currency_formatter.dart';
import '../core/utils/storefront_url.dart';
import '../core/utils/storefront_navigation.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartRepository _repo = CartRepository();
  final AuthRepository _authRepo = AuthRepository();
  final ShopwareApi _api = ShopwareApi();
  Map<String, dynamic>? _cart;
  bool _loading = true;
  String? _error;
  late Color _primaryColor;
  String _currencyIsoCode = 'EUR';

  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  void initState() {
    super.initState();
    // Start default color
    _primaryColor = _hexToColor(AppConfig.primaryColorHex);
    _loadPrimaryColor();
    _load();
  }

  Future<void> _loadPrimaryColor() async {
    try {
      final config = await _api.getFlutterConfig();
      final primaryColorStr =
          config['primaryColor'] as String? ?? AppConfig.primaryColorHex;
      if (mounted) {
        setState(() {
          _primaryColor = _hexToColor(primaryColorStr);
        });
      }
    } catch (e) {
      // Use default color if error occurs
      if (mounted) {
        setState(() {
          _primaryColor = _hexToColor(AppConfig.primaryColorHex);
        });
      }
    }
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

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _repo.getCart(),
        _api.getSalesChannelContext(),
      ]);
      if (!mounted) return;
      final data = results[0];
      final contextData = results[1];
      final salesChannelInfo = SalesChannelInfo.fromContext(contextData);
      setState(() {
        _cart = data;
        _currencyIsoCode = salesChannelInfo.currencyIsoCode ?? 'EUR';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  String _formatPrice(dynamic amount) =>
      CurrencyFormatter.format(amount, _currencyIsoCode);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _handleBack(context),
        ),
        title: const Text('Cart'),
        centerTitle: true,
        backgroundColor: _primaryColor,
        foregroundColor: ColorUtils.foregroundOn(_primaryColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.go('/search'),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }
    final items = (_cart?['lineItems'] as List?) ?? [];
    if (items.isEmpty) {
      return const Center(child: Text('Your cart is empty'));
    }
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = items[index] as Map<String, dynamic>;
              final label = item['label']?.toString() ?? 'Product';
              final qty =
                  int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
              final id = item['id']?.toString();
              final referencedId = item['referencedId']?.toString();
              final unitPrice = item['price']?['unitPrice'];
              final totalPrice = item['price']?['totalPrice'];
              return ListTile(
                title: Text(label),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (unitPrice != null) Text('Unit: ${_formatPrice(unitPrice)}'),
                    if (totalPrice != null) Text('Total: ${_formatPrice(totalPrice)}'),
                  ],
                ),
                trailing: SizedBox(
                  width: 170,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: id == null || qty <= 1
                            ? null
                            : () async {
                                try {
                                  await _repo.updateQuantity(
                                    lineItemId: id,
                                    quantity: qty - 1,
                                    referencedProductId: referencedId,
                                  );
                                  await _load();
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e')),
                                    );
                                  }
                                }
                              },
                      ),
                      Text('$qty'),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: id == null
                            ? null
                            : () async {
                                try {
                                  await _repo.updateQuantity(
                                    lineItemId: id,
                                    quantity: qty + 1,
                                    referencedProductId: referencedId,
                                  );
                                  await _load();
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e')),
                                    );
                                  }
                                }
                              },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: id == null
                            ? null
                            : () async {
                                try {
                                  await _repo.removeLineItem(lineItemId: id);
                                  await _load();
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e')),
                                    );
                                  }
                                }
                              },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        _buildTotals(),
      ],
    );
  }

  Widget _buildTotals() {
    final price = _cart?['price'] as Map<String, dynamic>?;
    if (price == null) return const SizedBox.shrink();
    final positionPrice = price['positionPrice'];
    final totalPrice = price['totalPrice'];
    final netPrice = price['netPrice'];
    final calculatedTaxes = price['calculatedTaxes'] as List?;
    final deliveries = _cart?['deliveries'] as List?;
    dynamic shippingCost;
    if (deliveries != null && deliveries.isNotEmpty) {
      final delivery = deliveries[0] as Map<String, dynamic>?;
      shippingCost = delivery?['shippingCosts']?['totalPrice'];
    }
    final lineItems = _cart?['lineItems'] as List?;
    final promotions = lineItems?.where((item) {
          final map = item as Map<String, dynamic>;
          return map['type']?.toString() == 'promotion';
        }).toList() ??
        [];
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (promotions.isNotEmpty) ...[
            const Text('Applied Discounts',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...promotions.map((p) {
              final label = p['label']?.toString() ?? 'Discount';
              final discount = p['price']?['totalPrice'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label, style: const TextStyle(color: Colors.green)),
                    Text(
                      _formatPrice(discount),
                      style: const TextStyle(color: Colors.green),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
          if (positionPrice != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal'),
                Text(_formatPrice(positionPrice)),
              ],
            ),
          if (shippingCost != null && shippingCost != 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Shipping'),
                Text(_formatPrice(shippingCost)),
              ],
            ),
          ],
          if (calculatedTaxes != null && calculatedTaxes.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...calculatedTaxes.map((tax) {
              final rate = tax['taxRate']?.toString() ?? '';
              final amount = tax['tax'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('VAT (%$rate)'),
                    Text(_formatPrice(amount)),
                  ],
                ),
              );
            }),
          ],
          if (netPrice != null && netPrice != positionPrice) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Excluding VAT'),
                Text(_formatPrice(netPrice)),
              ],
            ),
          ],
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(
                _formatPrice(totalPrice),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final items = (_cart?['lineItems'] as List?) ?? [];
    if (items.isEmpty) return const SizedBox.shrink();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              final isLoggedIn = await _authRepo.isLoggedIn();
              if (!isLoggedIn) {
                if (mounted) context.go('/login');
                return;
              }
              if (!mounted) return;
              await StorefrontNavigation.open(
                context,
                StorefrontUrl.checkoutConfirm(),
                title: 'Checkout',
              );
            },
            child: const Text('Complete Order'),
          ),
        ),
      ),
    );
  }
}
