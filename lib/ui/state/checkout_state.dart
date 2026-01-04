import 'package:flutter/foundation.dart';

import '../../data/repositories/checkout_repository.dart';

class CheckoutState extends ChangeNotifier {
  CheckoutState({CheckoutRepository? repository}) : _repository = repository ?? CheckoutRepository();

  final CheckoutRepository _repository;

  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> shippingMethods = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> paymentMethods = <Map<String, dynamic>>[];
  Map<String, dynamic>? orderResponse;

  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadMethods() async {
    _setLoading(true);
    try {
      final results = await Future.wait([
        _repository.getShippingMethods(),
        _repository.getPaymentMethods(),
      ]);
      shippingMethods = results[0];
      paymentMethods = results[1];
      _error = null;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> placeOrder({String? shippingMethodId, String? paymentMethodId}) async {
    _setLoading(true);
    try {
      orderResponse = await _repository.createOrder(
        shippingMethodId: shippingMethodId,
        paymentMethodId: paymentMethodId,
      );
      _error = null;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }
}


