import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/config/app_config.dart';
import '../core/services/shopware_api.dart';
import '../data/repositories/address_repository.dart';
import '../data/repositories/cart_repository.dart';
import '../data/repositories/checkout_repository.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final CheckoutRepository _repo = CheckoutRepository();
  final ShopwareApi _api = ShopwareApi();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _shippingMethods = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _paymentMethods = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _addresses = <Map<String, dynamic>>[];
  String? _selectedShipping;
  String? _selectedPayment;
  String? _selectedBillingAddressId;
  String? _selectedShippingAddressId;
  bool _placing = false;
  Map<String, dynamic>? _orderResponse;
  Map<String, dynamic>? _paymentResponse;
  OrderIdentifiers? _orderIdentifiers;
  late Color _primaryColor;

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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await Future.wait([
        _repo.getShippingMethods(),
        _repo.getPaymentMethods(),
        AddressRepository().listAddresses(),
      ]);
      setState(() {
        _shippingMethods = res[0] as List<Map<String, dynamic>>;
        _paymentMethods = res[1] as List<Map<String, dynamic>>;
        _addresses = res[2] as List<Map<String, dynamic>>;
        _selectedShipping = _shippingMethods.isNotEmpty
            ? _shippingMethods.first['id']?.toString()
            : null;
        _selectedPayment = _paymentMethods.isNotEmpty
            ? _paymentMethods.first['id']?.toString()
            : null;
        if (_addresses.isNotEmpty) {
          // Select first address as default (user can change it)
          _selectedBillingAddressId = _addresses.first['id']?.toString();
          _selectedShippingAddressId = _addresses.first['id']?.toString();
        }
      });
      // Update context on first load (address + methods)
      await _repo.updateContext(
        shippingMethodId: _selectedShipping,
        paymentMethodId: _selectedPayment,
        billingAddressId: _selectedBillingAddressId,
        shippingAddressId: _selectedShippingAddressId,
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _placeOrder() async {
    if (_selectedShipping == null ||
        _selectedPayment == null ||
        _selectedBillingAddressId == null ||
        _selectedShippingAddressId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all fields')),
        );
      }
      return;
    }
    setState(() => _placing = true);

    // Check cart - show errors (before try block)
    final cart = await CartRepository().getCart();
    final errors = cart['errors'];
    if (errors != null) {
      List<dynamic> errorList;
      if (errors is List) {
        errorList = errors;
      } else if (errors is Map) {
        // If errors is a Map, get values
        errorList = errors.values.toList();
      } else {
        errorList = [];
      }

      if (errorList.isNotEmpty) {
        final errorMessages = errorList
            .map((e) {
              if (e is Map) {
                final msg =
                    e['message']?.toString() ?? e['detail']?.toString() ?? '';
                final key = e['key']?.toString() ?? '';
                if (key.contains('shipping-address-blocked')) {
                  return 'This shipping method cannot be used for the selected shipping address. Please select a different address or shipping method.';
                }
                return msg.isNotEmpty ? msg : 'Unknown error';
              }
              return 'Unknown error';
            })
            .where((msg) => msg.isNotEmpty)
            .toList();

        if (errorMessages.isNotEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(errorMessages.join('\n')),
              duration: const Duration(seconds: 5),
              backgroundColor: Colors.red,
            ));
          }
          setState(() => _placing = false);
          return; // Exit method
        }
      }
    }

    try {
      // Check if customer is in context
      try {
        final apiService = ShopwareApi();
        final contextData = await apiService.getSalesChannelContext();
        final customer = contextData['customer'];
        if (customer == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please log in to create an order.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
          setState(() => _placing = false);
          return;
        }
      } catch (e) {
        // Error checking customer context
        // Continue even if customer context check fails
      }

      // First update context with all information
      await _repo.updateContext(
        shippingMethodId: _selectedShipping,
        paymentMethodId: _selectedPayment,
        billingAddressId: _selectedBillingAddressId,
        shippingAddressId: _selectedShippingAddressId,
      );

      // Then create order
      final orderResp = await _repo.createOrder(
        shippingMethodId: _selectedShipping,
        paymentMethodId: _selectedPayment,
        billingAddressId: _selectedBillingAddressId,
        shippingAddressId: _selectedShippingAddressId,
      );

      final identifiers = _repo.extractOrderIdentifiers(orderResp);

      setState(() {
        _orderResponse = orderResp;
        _orderIdentifiers = identifiers;
      });

      if (!identifiers.hasRequiredIds) {
        // Order created but required identifiers for payment are missing
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Order created. Required information for payment could not be retrieved.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
            ),
          );
        }
        return; // Order created but payment cannot be made
      }

      // Start payment process
      try {
        final paymentResp = await _repo.handlePayment(
          orderId: identifiers.orderId!,
          orderTransactionId: identifiers.orderTransactionId!,
          finishUrl: _buildFinishUrl(),
          errorUrl: _buildErrorUrl(),
        );

        setState(() {
          _paymentResponse = paymentResp.isEmpty ? null : paymentResp;
        });

        if (mounted) {
          await _handlePaymentResult(paymentResp);
        }
      } catch (paymentError) {
        // Payment error (but order created)
        // Payment error (but order created)

        // Log payment error but show success message to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Your order has been successfully created. Please try again later for payment or contact customer service.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      String errorMessage = 'Payment error: $e';

      // Parse DioException errors
      if (e is DioException && e.response != null) {
        final data = e.response?.data;
        if (data is Map) {
          final errors = data['errors'];
          if (errors != null) {
            List<dynamic> errorList;
            if (errors is List) {
              errorList = errors;
            } else if (errors is Map) {
              errorList = errors.values.toList();
            } else {
              errorList = [];
            }

            if (errorList.isNotEmpty) {
              final firstError = errorList.first;
              if (firstError is Map) {
                final detail = firstError['detail']?.toString() ?? '';
                final key = firstError['key']?.toString() ?? '';

                if (key.contains('shipping-address-blocked')) {
                  errorMessage =
                      'This shipping method cannot be used for the selected shipping address. Please select a different address or shipping method.';
                } else if (detail.isNotEmpty) {
                  errorMessage = detail;
                }
              }
            }
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(errorMessage),
          duration: const Duration(seconds: 5),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        centerTitle: true,
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _handleBack(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.go('/search'),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              const Text(
                'Payment step failed.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Login and try again.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _load,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Shipping Address',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedShippingAddressId,
            isExpanded: true,
            items: _addresses
                .map((e) => DropdownMenuItem(
                      value: e['id']?.toString(),
                      child: Text(_formatAddress(e)),
                    ))
                .toList(),
            onChanged: (v) async {
              setState(() => _selectedShippingAddressId = v);
              await _repo.updateContext(shippingAddressId: v);
            },
          ),
          const SizedBox(height: 16),
          const Text('Billing Address',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedBillingAddressId,
            isExpanded: true,
            items: _addresses
                .map((e) => DropdownMenuItem(
                      value: e['id']?.toString(),
                      child: Text(_formatAddress(e)),
                    ))
                .toList(),
            onChanged: (v) async {
              setState(() => _selectedBillingAddressId = v);
              await _repo.updateContext(billingAddressId: v);
            },
          ),
          const SizedBox(height: 24),
          const Text('Shipping Method',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedShipping,
            isExpanded: true,
            items: _shippingMethods
                .map((e) => DropdownMenuItem(
                      value: e['id']?.toString(),
                      child: Text(e['name']?.toString() ?? 'Shipping'),
                    ))
                .toList(),
            onChanged: (v) async {
              setState(() => _selectedShipping = v);
              await _repo.updateContext(shippingMethodId: v);
            },
          ),
          const SizedBox(height: 16),
          const Text('Payment Method',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedPayment,
            isExpanded: true,
            items: _paymentMethods
                .map((e) => DropdownMenuItem(
                      value: e['id']?.toString(),
                      child: Text(e['name']?.toString() ?? 'Payment'),
                    ))
                .toList(),
            onChanged: (v) async {
              setState(() => _selectedPayment = v);
              await _repo.updateContext(paymentMethodId: v);
            },
          ),
          const SizedBox(height: 24),
          if (_orderResponse != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order created',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_orderIdentifiers?.orderId != null) ...[
                    const SizedBox(height: 8),
                    Text('Order ID: ${_orderIdentifiers!.orderId}'),
                  ],
                  if (_orderIdentifiers?.orderTransactionId != null) ...[
                    const SizedBox(height: 4),
                    Text(
                        'Transaction ID: ${_orderIdentifiers!.orderTransactionId}'),
                  ],
                  if (_paymentResponse != null &&
                      _paymentResponse!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Payment status: ${_describePaymentResult(_paymentResponse)}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ] else ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Your order has been successfully created.',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ],
              ),
            )
        ],
      ),
    );
  }

  Future<void> _completePayment() async {
    if (_orderIdentifiers?.orderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order ID not found')),
      );
      return;
    }

    try {
      final baseUrl = _storefrontBaseUrl();
      final orderId = _orderIdentifiers!.orderId!;
      final paymentUrl = '${baseUrl}account/order/edit/$orderId';
      final uri = Uri.parse(paymentUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open payment page')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget _buildBottomBar() {
    // If order is created, show "Complete Payment" button
    if (_orderIdentifiers?.orderId != null) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _completePayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Complete Payment'),
            ),
          ),
        ),
      );
    }

    // If order is not created, show "Complete Order" button
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _placing ? null : _placeOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
            ),
            child: _placing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Complete Order'),
          ),
        ),
      ),
    );
  }

  String _formatAddress(Map<String, dynamic> a) {
    final first = a['firstName']?.toString() ?? '';
    final last = a['lastName']?.toString() ?? '';
    final street = a['street']?.toString() ?? '';
    final city = a['city']?.toString() ?? '';
    final country = a['country']?['name']?.toString() ?? '';
    return [
      [first, last].where((s) => s.isNotEmpty).join(' '),
      [street, city].where((s) => s.isNotEmpty).join(', '),
      country
    ].where((s) => s.isNotEmpty).join(' • ');
  }

  Future<void> _handlePaymentResult(Map<String, dynamic> paymentResult) async {
    if (!mounted) return;

    final errors = paymentResult['errors'];
    if (errors is List && errors.isNotEmpty) {
      final firstError = errors.first;
      String message = 'An error occurred during payment.';
      if (firstError is Map) {
        message = firstError['detail']?.toString() ??
            firstError['message']?.toString() ??
            message;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final redirectUrl = paymentResult['redirectUrl']?.toString();
    if (redirectUrl != null && redirectUrl.isNotEmpty) {
      final uri = Uri.tryParse(redirectUrl);
      if (uri != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Redirecting to payment provider...'),
          ),
        );
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!launched) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open browser: $redirectUrl'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid redirect URL: $redirectUrl'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final statusMessage = _describePaymentResult(paymentResult);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(statusMessage),
      ),
    );
  }

  String _describePaymentResult(Map<String, dynamic>? paymentResult) {
    if (paymentResult == null || paymentResult.isEmpty) {
      return 'Payment request sent successfully.';
    }
    final message = paymentResult['message']?.toString();
    if (message != null && message.isNotEmpty) {
      return message;
    }
    final status = paymentResult['paymentStatus'] ??
        paymentResult['status'] ??
        paymentResult['paymentState'] ??
        paymentResult['state'];
    if (status != null && status.toString().isNotEmpty) {
      return 'Payment status: ${status.toString()}';
    }
    return 'Payment request sent successfully.';
  }

  String _buildFinishUrl() {
    return '${_storefrontBaseUrl()}checkout/finish';
  }

  String _buildErrorUrl() {
    return '${_storefrontBaseUrl()}checkout/error';
  }

  String _storefrontBaseUrl() {
    var base = AppConfig.baseUrl.trim();
    if (base.endsWith('/store-api')) {
      base = base.substring(0, base.length - '/store-api'.length);
    }
    base = base.replaceAll(RegExp(r'/+$'), '');
    return '$base/';
  }
}
