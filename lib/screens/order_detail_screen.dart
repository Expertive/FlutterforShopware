import 'package:flutter/material.dart';
import '../core/utils/color_utils.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../data/repositories/orders_repository.dart';
import '../core/config/app_config.dart';
import '../core/utils/storefront_url.dart';
import '../core/utils/storefront_navigation.dart';
import '../core/services/shopware_api.dart';
import '../core/utils/l10n_extension.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final OrdersRepository _repo = OrdersRepository();
  final ShopwareApi _api = ShopwareApi();

  Map<String, dynamic>? _order;
  bool _loading = true;
  String? _error;
  late Color _primaryColor;

  @override
  void initState() {
    super.initState();
    // Start default color
    _primaryColor = _hexToColor(AppConfig.primaryColorHex);
    _loadPrimaryColor();
    _loadOrder();
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

  Future<void> _loadOrder() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final order = await _repo.getOrder(widget.orderId);

      // Order loaded successfully

      if (mounted) {
        setState(() {
          _order = order;
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

  String _getPaymentStatusText(BuildContext context, String? stateName) {
    if (stateName == null || stateName.isEmpty) {
      return context.l10n.paymentStatusUnknown;
    }

    switch (stateName.toLowerCase()) {
      case 'open':
        return context.l10n.paymentStatusOpen;
      case 'paid':
        return context.l10n.paymentStatusPaid;
      case 'paid_partially':
        return context.l10n.paymentStatusPartiallyPaid;
      case 'in_progress':
        return context.l10n.paymentStatusInProgress;
      case 'authorized':
        return context.l10n.paymentStatusAuthorized;
      case 'cancelled':
        return context.l10n.paymentStatusCancelled;
      case 'refunded':
        return context.l10n.paymentStatusRefunded;
      case 'refunded_partially':
        return context.l10n.paymentStatusPartiallyRefunded;
      case 'reminded':
        return context.l10n.paymentStatusReminded;
      case 'failed':
        return context.l10n.paymentStatusFailed;
      case 'reopen':
        return context.l10n.paymentStatusReopened;
      default:
        return stateName.split('_').map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        }).join(' ');
    }
  }

  String? _getPaymentStatusFromOrder(Map<String, dynamic> order) {
    // First check transactions list from order
    final transactions = order['transactions'] as List?;
    if (transactions != null && transactions.isNotEmpty) {
      final firstTransaction = transactions[0] as Map<String, dynamic>?;
      final transactionState =
          firstTransaction?['stateMachineState'] as Map<String, dynamic>?;
      final stateName = transactionState?['name']?.toString() ??
          transactionState?['technicalName']?.toString();
      if (stateName != null && stateName.isNotEmpty) {
        return stateName;
      }
    }

    // if transaction state is not found, check order's own state
    final stateMachineState =
        order['stateMachineState'] as Map<String, dynamic>?;
    return stateMachineState?['name']?.toString() ??
        stateMachineState?['technicalName']?.toString();
  }

  String _getShippingStatusText(BuildContext context, String? stateName) {
    if (stateName == null || stateName.isEmpty) {
      return context.l10n.shippingStatusUnknown;
    }

    switch (stateName.toLowerCase()) {
      case 'open':
        return context.l10n.shippingStatusOpen;
      case 'shipped':
        return context.l10n.shippingStatusShipped;
      case 'shipped_partially':
        return context.l10n.shippingStatusPartiallyShipped;
      case 'cancelled':
        return context.l10n.shippingStatusCancelled;
      case 'returned':
        return context.l10n.shippingStatusReturned;
      case 'returned_partially':
        return context.l10n.shippingStatusPartiallyReturned;
      case 'reopen':
        return context.l10n.shippingStatusReopened;
      default:
        return stateName.split('_').map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        }).join(' ');
    }
  }

  String? _getShippingStatusFromOrder(Map<String, dynamic> order) {
    // Check shipping status from deliveries list
    final deliveries = order['deliveries'] as List?;
    if (deliveries != null && deliveries.isNotEmpty) {
      // Get last delivery (usually the latest state)
      final lastDelivery =
          deliveries[deliveries.length - 1] as Map<String, dynamic>?;
      final deliveryState =
          lastDelivery?['stateMachineState'] as Map<String, dynamic>?;
      final stateName = deliveryState?['name']?.toString() ??
          deliveryState?['technicalName']?.toString();
      if (stateName != null && stateName.isNotEmpty) {
        return stateName;
      }
    }

    return null;
  }

  Future<void> _openOrderList() async {
    await StorefrontNavigation.open(
      context,
      StorefrontUrl.accountOrders(),
      title: context.l10n.commonOrders,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(context.l10n.orderDetailTitle),
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
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(context.l10n.commonError(_error!)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadOrder,
              child: Text(context.l10n.commonRetry),
            ),
          ],
        ),
      );
    }

    if (_order == null) {
      return Center(child: Text(context.l10n.orderDetailNotFound));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOrderHeader(context),
          const SizedBox(height: 24),
          _buildOrderItems(context),
          const SizedBox(height: 24),
          _buildAddresses(context),
          const SizedBox(height: 24),
          _buildOrderSummary(context),
          const SizedBox(height: 24),
          _buildActions(context),
        ],
      ),
    );
  }

  Widget _buildOrderHeader(BuildContext context) {
    final orderNumber = _order!['orderNumber']?.toString() ?? 'N/A';
    final orderDate = _order!['orderDateTime']?.toString();

    // Get payment status from order
    final rawPaymentStatus = _getPaymentStatusFromOrder(_order!);
    final paymentStatus =
        _getPaymentStatusText(context, rawPaymentStatus);

    // Get shipping status from order
    final rawShippingStatus = _getShippingStatusFromOrder(_order!);
    final shippingStatus =
        _getShippingStatusText(context, rawShippingStatus);

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
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Chip(
                  label: Text(paymentStatus),
                  backgroundColor: _primaryColor.withOpacity(0.1),
                  labelStyle: TextStyle(color: _primaryColor),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 12),
                Chip(
                  label: Text(
                    context.l10n.orderDetailShippingStatus(shippingStatus),
                  ),
                  backgroundColor: Colors.green.withOpacity(0.1),
                  labelStyle: const TextStyle(color: Colors.green),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItems(BuildContext context) {
    final lineItems = _order!['lineItems'] as List? ?? [];

    if (lineItems.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.orderDetailItems,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.orderDetailNoItems,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.orderDetailItems,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...lineItems.map(
              (item) => _buildLineItem(context, item as Map<String, dynamic>),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineItem(BuildContext context, Map<String, dynamic> item) {
    final label = item['label']?.toString() ?? context.l10n.commonProduct;
    final quantity = item['quantity'] as int? ?? 1;
    final price = item['price'] as Map<String, dynamic>?;
    final totalPrice = price?['totalPrice'] as num? ?? 0.0;
    final cover = item['cover'] as Map<String, dynamic>?;
    final coverUrl = cover?['url']?.toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (coverUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                coverUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image_not_supported),
                ),
              ),
            )
          else
            Container(
              width: 60,
              height: 60,
              color: Colors.grey[300],
              child: const Icon(Icons.image_not_supported),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.orderDetailQuantity('$quantity'),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${NumberFormat.currency(symbol: '€', decimalDigits: 2).format(totalPrice)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddresses(BuildContext context) {
    final billingAddress = _order!['billingAddress'] as Map<String, dynamic>?;
    final shippingAddress = _order!['deliveries']?[0]?['shippingOrderAddress']
        as Map<String, dynamic>?;

    // If both addresses are not found, show nothing
    if (billingAddress == null && shippingAddress == null) {
      return const SizedBox.shrink();
    }

    // If only one address is found, show it full width
    if (billingAddress == null || shippingAddress == null) {
      return billingAddress != null
          ? _buildAddressCard(
              context,
              context.l10n.orderDetailBillingAddress,
              billingAddress,
            )
          : _buildAddressCard(
              context,
              context.l10n.orderDetailShippingAddress,
              shippingAddress!,
            );
    }

    // If both addresses are found, show them side by side
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildAddressCard(
            context,
            context.l10n.orderDetailBillingAddress,
            billingAddress,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildAddressCard(
            context,
            context.l10n.orderDetailShippingAddress,
            shippingAddress,
          ),
        ),
      ],
    );
  }

  Widget _buildAddressCard(
    BuildContext context,
    String title,
    Map<String, dynamic> address,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildAddressContent(address),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressContent(Map<String, dynamic> address) {
    final firstName = address['firstName']?.toString() ?? '';
    final lastName = address['lastName']?.toString() ?? '';
    final street = address['street']?.toString() ?? '';
    final zipcode = address['zipcode']?.toString() ?? '';
    final city = address['city']?.toString() ?? '';
    final country = address['country']?['name']?.toString() ?? '';
    final phoneNumber = address['phoneNumber']?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (firstName.isNotEmpty || lastName.isNotEmpty)
          Text(
            '$firstName $lastName'.trim(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        if (street.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            street,
            style: const TextStyle(fontSize: 14),
          ),
        ],
        if (zipcode.isNotEmpty || city.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            '$zipcode $city'.trim(),
            style: const TextStyle(fontSize: 14),
          ),
        ],
        if (country.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            country,
            style: const TextStyle(fontSize: 14),
          ),
        ],
        if (phoneNumber.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.phone, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                phoneNumber,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildOrderSummary(BuildContext context) {
    final price = _order!['price'] as Map<String, dynamic>?;
    final netPrice = price?['netPrice'] as num? ?? 0.0;
    final totalPrice = price?['totalPrice'] as num? ?? 0.0;
    final shippingCosts = _order!['shippingCosts'] as Map<String, dynamic>?;
    final shippingTotal = shippingCosts?['totalPrice'] as num? ?? 0.0;

    // Calculate taxes
    final calculatedTaxes = price?['calculatedTaxes'] as List?;
    num totalTax = 0.0;
    num? taxRate;

    if (calculatedTaxes != null && calculatedTaxes.isNotEmpty) {
      // Add up all taxes
      for (var tax in calculatedTaxes) {
        if (tax is Map<String, dynamic>) {
          final taxAmount = tax['tax'] as num? ?? 0.0;
          totalTax += taxAmount;
          // Get first tax rate (usually all the same)
          if (taxRate == null) {
            taxRate = tax['taxRate'] as num?;
          }
        }
      }
    } else {
      // If calculatedTaxes is not found, calculate from totalPrice - netPrice
      totalTax = totalPrice - netPrice;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.orderDetailSummary,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSummaryRow(context, context.l10n.commonSubtotal, netPrice),
            _buildSummaryRow(context, context.l10n.commonShipping, shippingTotal),
            _buildSummaryRow(
              context,
              context.l10n.orderDetailNetTotal,
              netPrice + shippingTotal,
            ),
            if (taxRate != null)
              _buildSummaryRow(
                context,
                context.l10n.orderDetailVatPlus(taxRate.toStringAsFixed(0)),
                totalTax,
              )
            else
              _buildSummaryRow(context, context.l10n.orderDetailVat, totalTax),
            const Divider(height: 24),
            _buildSummaryRow(
              context,
              context.l10n.commonTotal,
              totalPrice,
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    num amount, {
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '${NumberFormat.currency(symbol: '€', decimalDigits: 2).format(amount)}',
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? _primaryColor : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final documents = _order!['documents'] as List? ?? [];

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _openOrderList,
            icon: const Icon(Icons.list),
            label: Text(context.l10n.orderViewList),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: ColorUtils.foregroundOn(_primaryColor),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        if (documents.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...documents.map((doc) {
            final docId = doc['id']?.toString() ?? '';
            final deepLinkCode = doc['deepLinkCode']?.toString() ?? '';
            final docType =
                doc['documentType']?['name']?.toString() ??
                    context.l10n.commonUnknown;

            return SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _downloadDocument(docId, deepLinkCode, docType),
                icon: const Icon(Icons.download),
                label: Text(context.l10n.orderDetailDownload(docType)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            );
          }).toList(),
        ],
      ],
    );
  }

  Future<void> _downloadDocument(
    String documentId,
    String deepLinkCode,
    String docType,
  ) async {
    await StorefrontNavigation.open(
      context,
      StorefrontUrl.documentDownload(documentId, deepLinkCode),
      title: docType,
    );
  }
}
