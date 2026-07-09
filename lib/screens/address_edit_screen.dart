import 'package:flutter/material.dart';
import '../core/utils/color_utils.dart';
import 'package:go_router/go_router.dart';

import '../data/repositories/address_repository.dart';
import '../core/services/shopware_api.dart';
import '../core/config/app_config.dart';
import '../core/utils/l10n_extension.dart';

class AddressEditScreen extends StatefulWidget {
  final Map<String, dynamic>? initial;
  const AddressEditScreen({super.key, this.initial});

  @override
  State<AddressEditScreen> createState() => _AddressEditScreenState();
}

class _AddressEditScreenState extends State<AddressEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _street = TextEditingController();
  final _zipcode = TextEditingController();
  final _city = TextEditingController();
  final _salutationId = TextEditingController();
  final _countryId = TextEditingController();
  final _countryStateId = TextEditingController();
  final _phone = TextEditingController();
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _salutations = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _countries = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _states = <Map<String, dynamic>>[];
  final _api = ShopwareApi();
  Color _primaryColor = Colors.blue;

  @override
  void initState() {
    super.initState();
    final v = widget.initial;
    if (v != null) {
      _firstName.text = v['firstName']?.toString() ?? '';
      _lastName.text = v['lastName']?.toString() ?? '';
      _street.text = v['street']?.toString() ?? '';
      _zipcode.text = v['zipcode']?.toString() ?? '';
      _city.text = v['city']?.toString() ?? '';
      _salutationId.text = v['salutationId']?.toString() ?? '';
      _countryId.text = v['countryId']?.toString() ?? '';
      _countryStateId.text = v['countryStateId']?.toString() ?? '';
      _phone.text = v['phoneNumber']?.toString() ?? '';
    }
    _primaryColor = _hexToColor(AppConfig.primaryColorHex);
    _loadLookups();
  }

  Color _hexToColor(String hex) {
    try {
      hex = hex.replaceAll('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return Colors.blue;
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
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _street.dispose();
    _zipcode.dispose();
    _city.dispose();
    _salutationId.dispose();
    _countryId.dispose();
    _countryStateId.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final payload = {
        'firstName': _firstName.text.trim(),
        'lastName': _lastName.text.trim(),
        'street': _street.text.trim(),
        'zipcode': _zipcode.text.trim(),
        'city': _city.text.trim(),
        'salutationId': _salutationId.text.trim(),
        'countryId': _countryId.text.trim(),
        if (_countryStateId.text.trim().isNotEmpty)
          'countryStateId': _countryStateId.text.trim(),
        if (_phone.text.trim().isNotEmpty) 'phoneNumber': _phone.text.trim(),
      };
      final repo = AddressRepository();
      if (widget.initial != null && widget.initial!['id'] != null) {
        await repo.updateAddress(widget.initial!['id'].toString(), payload);
      } else {
        await repo.createAddress(payload);
      }
      if (mounted) context.pop(payload);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadLookups() async {
    try {
      final results = await Future.wait([
        _api.getSalutations(),
        _api.getCountries(),
      ]);
      if (!mounted) return;
      setState(() {
        _salutations = results[0];
        _countries = results[1];
      });
      if (_countryId.text.isNotEmpty) {
        final st = await _api.getCountryStates(_countryId.text);
        if (mounted) setState(() => _states = st);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final editing = widget.initial != null && widget.initial!['id'] != null;

    // Ensure dropdown values exist in items; otherwise null to avoid assertion
    final currentSalutationId = _salutationId.text;
    final salutationValue = currentSalutationId.isNotEmpty &&
            _salutations.any(
              (e) => (e['id']?.toString() ?? '') == currentSalutationId,
            )
        ? currentSalutationId
        : null;

    final currentCountryId = _countryId.text;
    final countryValue = currentCountryId.isNotEmpty &&
            _countries.any(
              (e) => (e['id']?.toString() ?? '') == currentCountryId,
            )
        ? currentCountryId
        : null;

    final currentStateId = _countryStateId.text;
    final stateValue = currentStateId.isNotEmpty &&
            _states.any((e) => (e['id']?.toString() ?? '') == currentStateId)
        ? currentStateId
        : null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _handleBack(context),
        ),
        title: Text(editing ? l10n.addressEditTitle : l10n.addressNewTitle),
        centerTitle: true,
        backgroundColor: _primaryColor,
        foregroundColor: ColorUtils.foregroundOn(_primaryColor),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _field(context, _firstName, l10n.accountFirstName),
              _field(context, _lastName, l10n.accountLastName),
              _field(context, _street, l10n.addressStreet),
              _field(context, _zipcode, l10n.addressPostalCode),
              _field(context, _city, l10n.addressCity),
              DropdownButtonFormField<String>(
                value: salutationValue,
                isExpanded: true,
                decoration: InputDecoration(labelText: l10n.addressSalutation),
                items: _salutations
                    .map((e) => DropdownMenuItem(
                          value: e['id']?.toString(),
                          child: Text(
                            e['displayName']?.toString() ??
                                e['salutationKey']?.toString() ??
                                l10n.addressSalutationSelect,
                          ),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _salutationId.text = v ?? ''),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: countryValue,
                isExpanded: true,
                decoration: InputDecoration(labelText: l10n.addressCountry),
                items: _countries
                    .map((e) => DropdownMenuItem(
                          value: e['id']?.toString(),
                          child: Text(
                            e['name']?.toString() ?? l10n.addressCountry,
                          ),
                        ))
                    .toList(),
                onChanged: (v) async {
                  setState(() {
                    _countryId.text = v ?? '';
                    _countryStateId.clear();
                    _states = <Map<String, dynamic>>[];
                  });
                  if (v != null && v.isNotEmpty) {
                    final st = await _api.getCountryStates(v);
                    if (mounted) setState(() => _states = st);
                  }
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: stateValue,
                isExpanded: true,
                decoration: InputDecoration(labelText: l10n.addressStateOptional),
                items: _states
                    .map((e) => DropdownMenuItem(
                          value: e['id']?.toString(),
                          child: Text(
                            e['name']?.toString() ?? l10n.addressState,
                          ),
                        ))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _countryStateId.text = v ?? ''),
              ),
              _field(
                context,
                _phone,
                l10n.addressPhoneOptional,
                required: false,
              ),
              const SizedBox(height: 12),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    context.l10n.commonError(_error!),
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
                  child: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.commonSave),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    BuildContext context,
    TextEditingController c,
    String label, {
    bool required = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: c,
        decoration: InputDecoration(labelText: label),
        validator: required
            ? (v) => (v == null || v.isEmpty)
                ? context.l10n.addressFieldRequired(label)
                : null
            : null,
      ),
    );
  }
}
