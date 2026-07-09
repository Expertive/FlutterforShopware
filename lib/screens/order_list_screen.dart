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

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  final OrdersRepository _repo = OrdersRepository();
  final ShopwareApi _api = ShopwareApi();

  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  String? _error;
  late Color _primaryColor;
  Map<String, bool>? _paymentChangeable;
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    // Start default color
    _primaryColor = _hexToColor(AppConfig.primaryColorHex);
    _loadPrimaryColor();
    _loadOrders();
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

  Future<void> _loadOrders({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _hasMore = true;
        _orders = [];
      });
    }

    if (!_hasMore && !refresh) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _repo.listOrders(page: _currentPage, limit: 20);
      final ordersData = result['orders'] as Map<String, dynamic>?;
      final elements = ordersData?['elements'] as List? ?? [];

      // paymentChangeable can be an array or a Map
      final paymentChangeableData = result['paymentChangeable'];
      if (paymentChangeableData is Map) {
        _paymentChangeable = Map<String, bool>.from(
          paymentChangeableData.map((key, value) => MapEntry(
                key.toString(),
                value is bool ? value : false,
              )),
        );
      } else {
        // If array is or null, use empty Map
        _paymentChangeable = <String, bool>{};
      }

      if (mounted) {
        setState(() {
          if (refresh) {
            _orders = List<Map<String, dynamic>>.from(elements);
          } else {
            _orders.addAll(List<Map<String, dynamic>>.from(elements));
          }

          final total = ordersData?['total'] as int? ?? 0;
          _hasMore = _orders.length < total;
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

  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
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
        title: Text(context.l10n.orderListTitle),
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
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Future<void> _openOrderList() async {
    await StorefrontNavigation.open(
      context,
      StorefrontUrl.accountOrders(),
      title: context.l10n.commonOrders,
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SizedBox(
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
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading && _orders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(context.l10n.commonError(_error!)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadOrders(refresh: true),
              child: Text(context.l10n.commonRetry),
            ),
          ],
        ),
      );
    }

    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined,
                size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              context.l10n.orderListEmpty,
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: Text(context.l10n.orderListStartShopping),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadOrders(refresh: true),
      child: ListView.builder(
        itemCount: _orders.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _orders.length) {
            _loadOrders();
            return const Center(
                child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ));
          }

          final order = _orders[index];
          return _buildOrderCard(context, order);
        },
      ),
    );
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

    // If transaction state is not found, check order's own state
    final stateMachineState =
        order['stateMachineState'] as Map<String, dynamic>?;
    return stateMachineState?['name']?.toString() ??
        stateMachineState?['technicalName']?.toString();
  }

  Widget _buildOrderCard(BuildContext context, Map<String, dynamic> order) {
    final orderNumber = order['orderNumber']?.toString() ?? 'N/A';
    final orderDate = order['orderDateTime']?.toString();
    final price = order['price'] as Map<String, dynamic>?;
    final totalPrice = price?['totalPrice'] as num? ?? 0.0;

    // Get payment status from order
    final rawPaymentStatus = _getPaymentStatusFromOrder(order);
    final stateName = _getPaymentStatusText(context, rawPaymentStatus);

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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.orderNumber(orderNumber),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
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
                  Chip(
                    label: Text(stateName),
                    backgroundColor: _primaryColor.withOpacity(0.1),
                    labelStyle: TextStyle(color: _primaryColor),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.l10n.commonTotal,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${NumberFormat.currency(symbol: '€', decimalDigits: 2).format(totalPrice)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                ],
              ),
              if (_paymentChangeable?[orderId] == true) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => context.push('/order/$orderId'),
                  icon: const Icon(Icons.payment),
                  label: Text(context.l10n.orderChangePayment),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primaryColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
