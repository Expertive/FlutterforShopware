import 'package:flutter/material.dart';
import '../core/utils/color_utils.dart';
import 'package:go_router/go_router.dart';

import '../data/repositories/address_repository.dart';
import '../core/config/app_config.dart';
import '../core/utils/l10n_extension.dart';

class AddressListScreen extends StatefulWidget {
  const AddressListScreen({super.key});

  @override
  State<AddressListScreen> createState() => _AddressListScreenState();
}

class _AddressListScreenState extends State<AddressListScreen> {
  final AddressRepository _repo = AddressRepository();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _addresses = <Map<String, dynamic>>[];
  Color _primaryColor = Colors.blue;

  @override
  void initState() {
    super.initState();
    _primaryColor = _hexToColor(AppConfig.primaryColorHex);
    _load();
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

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _repo.listAddresses();
      if (!mounted) return;
      setState(() => _addresses = list);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
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
        title: Text(context.l10n.addressListTitle),
        centerTitle: true,
        backgroundColor: _primaryColor,
        foregroundColor: ColorUtils.foregroundOn(_primaryColor),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created =
              await context.push<Map<String, dynamic>?>('/address/edit');
          if (created != null) {
            await _load();
          }
        },
        child: const Icon(Icons.add),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Text(context.l10n.commonError(_error!)));
    }
    if (_addresses.isEmpty) {
      return Center(child: Text(context.l10n.addressListEmpty));
    }
    return ListView.separated(
      itemCount: _addresses.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final addr = _addresses[index];
        final id = addr['id']?.toString() ?? '';
        final name =
            '${addr['firstName'] ?? ''} ${addr['lastName'] ?? ''}'.trim();
        final street = addr['street']?.toString() ?? '';
        final city = addr['city']?.toString() ?? '';
        final zipcode = addr['zipcode']?.toString() ?? '';
        return ListTile(
          title: Text(name.isEmpty ? context.l10n.addressFallback : name),
          subtitle: Text('$street, $zipcode $city'),
          trailing: PopupMenuButton<String>(
            onSelected: (value) async {
              try {
                if (value == 'edit') {
                  final updated = await context.push<Map<String, dynamic>?>(
                    '/address/edit',
                    extra: addr,
                  );
                  if (updated != null) await _load();
                } else if (value == 'del') {
                  await _repo.deleteAddress(id);
                  await _load();
                } else if (value == 'default_shipping') {
                  await _repo.setDefaultShipping(id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.l10n.addressDefaultShipping)),
                  );
                } else if (value == 'default_billing') {
                  await _repo.setDefaultBilling(id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.l10n.addressDefaultBilling)),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.l10n.commonError(e.toString()))),
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Text(context.l10n.addressEdit),
              ),
              PopupMenuItem(
                value: 'default_shipping',
                child: Text(context.l10n.addressSetDefaultShipping),
              ),
              PopupMenuItem(
                value: 'default_billing',
                child: Text(context.l10n.addressSetDefaultBilling),
              ),
              PopupMenuItem(
                value: 'del',
                child: Text(context.l10n.addressDelete),
              ),
            ],
          ),
        );
      },
    );
  }
}
