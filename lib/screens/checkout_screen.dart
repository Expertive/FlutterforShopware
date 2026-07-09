import 'package:dio/dio.dart';
import '../core/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/config/app_config.dart';
import '../core/utils/storefront_url.dart';
import '../core/utils/storefront_navigation.dart';
import '../core/services/shopware_api.dart';
import '../data/repositories/address_repository.dart';
import '../data/repositories/cart_repository.dart';
import '../data/repositories/checkout_repository.dart';
import '../core/utils/l10n_extension.dart';

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
    if (!mounted) return;
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
      if (!mounted) return;
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
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _placeOrder() async {
    if (_selectedShipping == null ||
        _selectedPayment == null ||
        _selectedBillingAddressId == null ||
        _selectedShippingAddressId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.checkoutFillAllFields)),
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
                  return context.l10n.checkoutShippingBlocked;
                }
                return msg.isNotEmpty ? msg : context.l10n.commonUnknown;
              }
              return context.l10n.commonUnknown;
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
          if (!mounted) return;
          setState(() => _placing = false);
          return;
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
              SnackBar(
                content: Text(context.l10n.checkoutLoginRequired),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          }
          if (!mounted) return;
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

      if (!mounted) return;
      setState(() {
        _orderResponse = orderResp;
        _orderIdentifiers = identifiers;
      });

      if (!identifiers.hasRequiredIds) {
        // Order created but required identifiers for payment are missing
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.l10n.checkoutOrderCreatedMissingPayment,
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
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

        if (!mounted) return;
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
            SnackBar(
              content: Text(context.l10n.checkoutOrderCreatedPaymentRetry),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      String errorMessage = context.l10n.checkoutPaymentError(e.toString());

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
                  errorMessage = context.l10n.checkoutShippingBlocked;
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
        title: Text(context.l10n.checkoutTitle),
        centerTitle: true,
        backgroundColor: _primaryColor,
        foregroundColor: ColorUtils.foregroundOn(_primaryColor),
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
      body: _buildBody(context),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildBody(BuildContext context) {
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
              Text(
                context.l10n.checkoutPaymentStepFailed,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.checkoutLoginAndTryAgain,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _load,
                child: Text(context.l10n.commonTryAgain),
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
          Text(
            context.l10n.checkoutShippingAddress,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
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
          Text(
            context.l10n.checkoutBillingAddress,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
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
          Text(
            context.l10n.checkoutShippingMethod,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedShipping,
            isExpanded: true,
            items: _shippingMethods
                .map((e) => DropdownMenuItem(
                      value: e['id']?.toString(),
                      child: Text(
                        e['name']?.toString() ?? context.l10n.commonShipping,
                      ),
                    ))
                .toList(),
            onChanged: (v) async {
              setState(() => _selectedShipping = v);
              await _repo.updateContext(shippingMethodId: v);
            },
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.checkoutPaymentMethod,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedPayment,
            isExpanded: true,
            items: _paymentMethods
                .map((e) => DropdownMenuItem(
                      value: e['id']?.toString(),
                      child: Text(
                        e['name']?.toString() ?? context.l10n.commonPayment,
                      ),
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
                  Text(
                    context.l10n.checkoutOrderCreated,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_orderIdentifiers?.orderId != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      context.l10n.checkoutOrderId(
                        _orderIdentifiers!.orderId!,
                      ),
                    ),
                  ],
                  if (_orderIdentifiers?.orderTransactionId != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.checkoutTransactionId(
                        _orderIdentifiers!.orderTransactionId!,
                      ),
                    ),
                  ],
                  if (_paymentResponse != null &&
                      _paymentResponse!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      context.l10n.checkoutPaymentStatus(
                        _describePaymentResult(context, _paymentResponse),
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ] else ...[
                    const SizedBox(height: 12),
                    Text(
                      context.l10n.checkoutOrderCreatedSuccess,
                      style: const TextStyle(fontWeight: FontWeight.w500),
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
        SnackBar(content: Text(context.l10n.checkoutOrderIdNotFound)),
      );
      return;
    }

    await StorefrontNavigation.open(
      context,
      StorefrontUrl.orderEdit(_orderIdentifiers!.orderId!),
      title: context.l10n.commonPayment,
    );
  }

  Widget _buildBottomBar(BuildContext context) {
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
                foregroundColor: ColorUtils.foregroundOn(_primaryColor),
              ),
              child: Text(context.l10n.checkoutCompletePayment),
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
              foregroundColor: ColorUtils.foregroundOn(_primaryColor),
            ),
            child: _placing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(context.l10n.checkoutCompleteOrder),
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
      String message = context.l10n.commonUnknown;
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
          SnackBar(
            content: Text(context.l10n.checkoutRedirectingPayment),
          ),
        );
        StorefrontNavigation.open(
          context,
          redirectUrl,
          title: context.l10n.commonPayment,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.checkoutInvalidRedirectUrl(redirectUrl),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final statusMessage = _describePaymentResult(context, paymentResult);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(statusMessage),
      ),
    );
  }

  String _describePaymentResult(
    BuildContext context,
    Map<String, dynamic>? paymentResult,
  ) {
    if (paymentResult == null || paymentResult.isEmpty) {
      return context.l10n.checkoutOrderCreatedSuccess;
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
      return context.l10n.checkoutPaymentStatus(status.toString());
    }
    return context.l10n.checkoutOrderCreatedSuccess;
  }

  String _buildFinishUrl() => '${StorefrontUrl.base()}checkout/finish';

  String _buildErrorUrl() => '${StorefrontUrl.base()}checkout/error';
}
