import 'package:flutter/foundation.dart';

import '../../data/repositories/cart_repository.dart';

class CartState extends ChangeNotifier {
  CartState({CartRepository? repository}) : _repository = repository ?? CartRepository();

  final CartRepository _repository;

  bool _loading = false;
  String? _error;
  Map<String, dynamic>? cart;

  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadCart() async {
    _setLoading(true);
    try {
      cart = await _repository.getCart();
      _error = null;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addProduct(String productId, {int quantity = 1}) async {
    _setLoading(true);
    try {
      cart = await _repository.addProduct(productId: productId, quantity: quantity);
      _error = null;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> removeLineItem(String lineItemId) async {
    _setLoading(true);
    try {
      cart = await _repository.removeLineItem(lineItemId: lineItemId);
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


