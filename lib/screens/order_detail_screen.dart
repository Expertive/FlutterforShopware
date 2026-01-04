import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/repositories/orders_repository.dart';
import '../core/config.dart';
import '../core/services/shopware_api.dart';

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
    // Başlangıçta AppConfig'den primary color'ı al (main()'de yüklenmiş olacak)
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
      // Hata durumunda AppConfig'deki değeri kullan
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

  String _getPaymentStatusText(String? stateName) {
    if (stateName == null || stateName.isEmpty) {
      return 'Bilinmiyor';
    }

    // Shopware payment/transaction durumlarını Türkçe'ye çevir
    switch (stateName.toLowerCase()) {
      case 'open':
        return 'Açık';
      case 'paid':
        return 'Ödendi';
      case 'paid_partially':
        return 'Kısmen Ödendi';
      case 'in_progress':
        return 'In Progress';
      case 'authorized':
        return 'Authorized';
      case 'cancelled':
        return 'Cancelled';
      case 'refunded':
        return 'Refunded';
      case 'refunded_partially':
        return 'Partially Refunded';
      case 'reminded':
        return 'Reminded';
      case 'failed':
        return 'Failed';
      case 'reopen':
        return 'Reopened';
      default:
        // If unknown state, capitalize first letter of each word
        return stateName.split('_').map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        }).join(' ');
    }
  }

  String? _getPaymentStatusFromOrder(Map<String, dynamic> order) {
    // Önce transactions array'inden payment status'u kontrol et
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

    // Eğer transaction state yoksa, order'ın kendi state'ini kontrol et
    final stateMachineState =
        order['stateMachineState'] as Map<String, dynamic>?;
    return stateMachineState?['name']?.toString() ??
        stateMachineState?['technicalName']?.toString();
  }

  String _getShippingStatusText(String? stateName) {
    if (stateName == null || stateName.isEmpty) {
      return 'Unknown';
    }

    // Translate Shopware shipping/delivery states to English
    switch (stateName.toLowerCase()) {
      case 'open':
        return 'Open';
      case 'shipped':
        return 'Shipped';
      case 'shipped_partially':
        return 'Partially Shipped';
      case 'cancelled':
        return 'Cancelled';
      case 'returned':
        return 'Returned';
      case 'returned_partially':
        return 'Partially Returned';
      case 'reopen':
        return 'Reopened';
      default:
        // If unknown state, capitalize first letter of each word
        return stateName.split('_').map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        }).join(' ');
    }
  }

  String? _getShippingStatusFromOrder(Map<String, dynamic> order) {
    // Deliveries array'inden shipping status'u kontrol et
    final deliveries = order['deliveries'] as List?;
    if (deliveries != null && deliveries.isNotEmpty) {
      // En son delivery'yi al (genellikle en güncel durum)
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

  String _storefrontBaseUrl() {
    var base = AppConfig.baseUrl.trim();
    if (base.endsWith('/store-api')) {
      base = base.substring(0, base.length - '/store-api'.length);
    }
    base = base.replaceAll(RegExp(r'/+$'), '');
    return '$base/';
  }

  Future<void> _openOrderList() async {
    try {
      final baseUrl = _storefrontBaseUrl();
      final orderListUrl = '${baseUrl}account/order';
      final uri = Uri.parse(orderListUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open order list')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Order Details'),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.go('/search'),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadOrder,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_order == null) {
      return const Center(child: Text('Order not found'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOrderHeader(),
          const SizedBox(height: 24),
          _buildOrderItems(),
          const SizedBox(height: 24),
          _buildAddresses(),
          const SizedBox(height: 24),
          _buildOrderSummary(),
          const SizedBox(height: 24),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildOrderHeader() {
    final orderNumber = _order!['orderNumber']?.toString() ?? 'N/A';
    final orderDate = _order!['orderDateTime']?.toString();

    // Payment status'u al
    final rawPaymentStatus = _getPaymentStatusFromOrder(_order!);
    final paymentStatus = _getPaymentStatusText(rawPaymentStatus);

    // Shipping status'u al
    final rawShippingStatus = _getShippingStatusFromOrder(_order!);
    final shippingStatus = _getShippingStatusText(rawShippingStatus);

    DateTime? parsedDate;
    if (orderDate != null) {
      try {
        parsedDate = DateTime.parse(orderDate);
      } catch (e) {
        // Ignore
      }
    }

    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    final formattedDate =
        parsedDate != null ? dateFormat.format(parsedDate) : 'Tarih bilinmiyor';

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
                  'Order #$orderNumber',
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
                  label: Text('Shipping: $shippingStatus'),
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

  Widget _buildOrderItems() {
    final lineItems = _order!['lineItems'] as List? ?? [];

    if (lineItems.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Order Items',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No order items found',
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
            const Text(
              'Sipariş Öğeleri',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...lineItems
                .map((item) => _buildLineItem(item as Map<String, dynamic>)),
          ],
        ),
      ),
    );
  }

  Widget _buildLineItem(Map<String, dynamic> item) {
    final label = item['label']?.toString() ?? 'Product';
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
                  'Quantity: $quantity',
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

  Widget _buildAddresses() {
    final billingAddress = _order!['billingAddress'] as Map<String, dynamic>?;
    final shippingAddress = _order!['deliveries']?[0]?['shippingOrderAddress']
        as Map<String, dynamic>?;

    // Her iki adres de yoksa hiçbir şey gösterme
    if (billingAddress == null && shippingAddress == null) {
      return const SizedBox.shrink();
    }

    // Tek bir adres varsa tam genişlikte göster
    if (billingAddress == null || shippingAddress == null) {
      return billingAddress != null
          ? _buildAddressCard('Billing Address', billingAddress)
          : _buildAddressCard('Shipping Address', shippingAddress!);
    }

    // Her iki adres de varsa yan yana göster
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildAddressCard('Billing Address', billingAddress),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildAddressCard('Shipping Address', shippingAddress),
        ),
      ],
    );
  }

  Widget _buildAddressCard(String title, Map<String, dynamic> address) {
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

  Widget _buildOrderSummary() {
    final price = _order!['price'] as Map<String, dynamic>?;
    final netPrice = price?['netPrice'] as num? ?? 0.0;
    final totalPrice = price?['totalPrice'] as num? ?? 0.0;
    final shippingCosts = _order!['shippingCosts'] as Map<String, dynamic>?;
    final shippingTotal = shippingCosts?['totalPrice'] as num? ?? 0.0;

    // KDV bilgisini hesapla
    final calculatedTaxes = price?['calculatedTaxes'] as List?;
    num totalTax = 0.0;
    num? taxRate;

    if (calculatedTaxes != null && calculatedTaxes.isNotEmpty) {
      // Tüm KDV'leri topla
      for (var tax in calculatedTaxes) {
        if (tax is Map<String, dynamic>) {
          final taxAmount = tax['tax'] as num? ?? 0.0;
          totalTax += taxAmount;
          // İlk KDV oranını al (genellikle hepsi aynı)
          if (taxRate == null) {
            taxRate = tax['taxRate'] as num?;
          }
        }
      }
    } else {
      // Eğer calculatedTaxes yoksa, totalPrice - netPrice'dan hesapla
      totalTax = totalPrice - netPrice;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSummaryRow('Subtotal', netPrice),
            _buildSummaryRow('Shipping', shippingTotal),
            _buildSummaryRow('Net Total', netPrice + shippingTotal),
            if (taxRate != null)
              _buildSummaryRow(
                  'Plus ${taxRate.toStringAsFixed(0)}% VAT', totalTax)
            else
              _buildSummaryRow('VAT', totalTax),
            const Divider(height: 24),
            _buildSummaryRow('Total', totalPrice, isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, num amount, {bool isTotal = false}) {
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

  Widget _buildActions() {
    final documents = _order!['documents'] as List? ?? [];

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _openOrderList,
            icon: const Icon(Icons.list),
            label: const Text('View Order List'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        if (documents.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...documents.map((doc) {
            final docId = doc['id']?.toString() ?? '';
            final deepLinkCode = doc['deepLinkCode']?.toString() ?? '';
            final docType = doc['documentType']?['name']?.toString() ?? 'Document';

            return SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _downloadDocument(docId, deepLinkCode),
                icon: const Icon(Icons.download),
                label: Text('Download $docType'),
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

  Future<void> _downloadDocument(String documentId, String deepLinkCode) async {
    try {
      // Store API document download endpoint'ini kullan
      final baseUrl = 'http://localhost/shopware67/public';
      final url =
          '$baseUrl/store-api/document/download/$documentId/$deepLinkCode';

      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open document')),
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
}
