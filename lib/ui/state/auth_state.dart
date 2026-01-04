import 'package:flutter/foundation.dart';

import '../../data/repositories/auth_repository.dart';

class AuthState extends ChangeNotifier {
  AuthState({AuthRepository? repository}) : _repository = repository ?? AuthRepository();

  final AuthRepository _repository;

  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _profile;

  bool get loading => _loading;
  String? get error => _error;
  Map<String, dynamic>? get profile => _profile;

  Future<void> login(String email, String password) async {
    _setLoading(true);
    try {
      await _repository.login(email: email, password: password);
      await fetchMe();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String salutationId,
    required String firstName,
    required String lastName,
  }) async {
    _setLoading(true);
    try {
      await _repository.register(
        email: email,
        password: password,
        salutationId: salutationId,
        firstName: firstName,
        lastName: lastName,
      );
      await fetchMe();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> requestPasswordRecovery(String email) async {
    _setLoading(true);
    try {
      await _repository.requestPasswordRecovery(email: email);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> confirmPasswordRecovery(String hash, String newPassword) async {
    _setLoading(true);
    try {
      await _repository.confirmPasswordRecovery(hash: hash, newPassword: newPassword);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      await _repository.logout();
      _profile = null;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchMe() async {
    _setLoading(true);
    try {
      _profile = await _repository.me();
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


