import 'package:flutter/material.dart';
import '../core/utils/color_utils.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../data/repositories/orders_repository.dart';
import '../core/config/app_config.dart';
import '../core/services/shopware_api.dart';
import '../core/utils/l10n_extension.dart';

class GuestOrderLookupScreen extends StatefulWidget {
  const GuestOrderLookupScreen({super.key});

  @override
  State<GuestOrderLookupScreen> createState() => _GuestOrderLookupScreenState();
}

class _GuestOrderLookupScreenState extends State<GuestOrderLookupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _zipcodeController = TextEditingController();
  final _deepLinkCodeController = TextEditingController();
  final _ordersRepo = OrdersRepository();
  final _api = ShopwareApi();
  bool _loading = false;
  List<Map<String, dynamic>> _orders = [];
  String? _error;
  late Color _primaryColor;

  @override
  void initState() {
    super.initState();
    // Start default color
    _primaryColor = _hexToColor(AppConfig.primaryColorHex);
    _loadPrimaryColor();
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

  @override
  void dispose() {
    _emailController.dispose();
    _zipcodeController.dispose();
    _deepLinkCodeController.dispose();
    super.dispose();
  }

  Future<void> _lookupOrders() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
      _orders = [];
    });

    try {
      final result = await _ordersRepo.listOrders(
        email: _emailController.text.trim(),
        zipcode: _zipcodeController.text.trim().isNotEmpty
            ? _zipcodeController.text.trim()
            : null,
        deepLinkCode: _deepLinkCodeController.text.trim().isNotEmpty
            ? _deepLinkCodeController.text.trim()
            : null,
      );

      final ordersData = result['orders'] as Map<String, dynamic>?;
      final elements = ordersData?['elements'] as List? ?? [];

      if (mounted) {
        setState(() {
          _orders = List<Map<String, dynamic>>.from(elements);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(context.l10n.guestOrderTitle),
        centerTitle: true,
        backgroundColor: _primaryColor,
        foregroundColor: ColorUtils.foregroundOn(_primaryColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Icon(
                Icons.search,
                size: 64,
                color: _primaryColor,
              ),
              const SizedBox(height: 24),
              Text(
                context.l10n.guestOrderHeading,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.guestOrderSubtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: context.l10n.commonEmail,
                  hintText: 'example@email.com',
                  prefixIcon: const Icon(Icons.email),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return context.l10n.contactEmailRequired;
                  }
                  if (!value.contains('@')) {
                    return context.l10n.contactEmailInvalid;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _zipcodeController,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  labelText: context.l10n.guestOrderPostalCode,
                  hintText: '34000',
                  prefixIcon: const Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _deepLinkCodeController,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  labelText: context.l10n.guestOrderCodeOptional,
                  hintText: 'ABC123',
                  prefixIcon: const Icon(Icons.confirmation_number),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _lookupOrders,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: ColorUtils.foregroundOn(_primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(context.l10n.guestOrderLookup),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[300]!),
                  ),
                  child: Text(
                    context.l10n.commonError(_error!),
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
              if (_orders.isNotEmpty) ...[
                const SizedBox(height: 32),
                Text(
                  context.l10n.guestOrderYourOrders,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ..._orders.map((order) => _buildOrderCard(context, order)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Map<String, dynamic> order) {
    final orderNumber = order['orderNumber']?.toString() ?? 'N/A';
    final orderDate = order['orderDateTime']?.toString();
    final price = order['price'] as Map<String, dynamic>?;
    final totalPrice = price?['totalPrice'] as num? ?? 0.0;
    final orderId = order['id']?.toString() ?? '';

    DateTime? parsedDate;
    if (orderDate != null) {
      try {
        parsedDate = DateTime.parse(orderDate);
      } catch (e) {
        // Ignore
      }
    }

    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    final formattedDate = parsedDate != null
        ? dateFormat.format(parsedDate)
        : context.l10n.dateUnknown;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/order/$orderId'),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.l10n.orderNumber(orderNumber),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    NumberFormat.currency(symbol: '€', decimalDigits: 2)
                        .format(totalPrice),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                formattedDate,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
