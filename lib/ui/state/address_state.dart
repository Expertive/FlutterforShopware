import 'package:flutter/foundation.dart';

import '../../data/repositories/address_repository.dart';

class AddressState extends ChangeNotifier {
  AddressState({AddressRepository? repository}) : _repository = repository ?? AddressRepository();

  final AddressRepository _repository;

  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> addresses = <Map<String, dynamic>>[];

  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    _setLoading(true);
    try {
      addresses = await _repository.listAddresses();
      _error = null;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> create(Map<String, dynamic> address) async {
    _setLoading(true);
    try {
      await _repository.createAddress(address);
      await load();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> update(String id, Map<String, dynamic> address) async {
    _setLoading(true);
    try {
      await _repository.updateAddress(id, address);
      await load();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> remove(String id) async {
    _setLoading(true);
    try {
      await _repository.deleteAddress(id);
      await load();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> setDefaultBilling(String id) async {
    _setLoading(true);
    try {
      await _repository.setDefaultBilling(id);
      await load();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> setDefaultShipping(String id) async {
    _setLoading(true);
    try {
      await _repository.setDefaultShipping(id);
      await load();
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


