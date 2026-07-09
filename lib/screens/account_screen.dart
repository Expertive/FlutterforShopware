import 'package:flutter/material.dart';
import '../core/utils/color_utils.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

import '../core/storage.dart';
import '../data/repositories/auth_repository.dart';
import '../core/config/app_config.dart';
import '../core/utils/storefront_url.dart';
import '../core/utils/storefront_navigation.dart';
import '../core/services/shopware_api.dart';
import '../core/utils/l10n_extension.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final ShopwareApi _api = ShopwareApi();
  Map<String, dynamic>? _profile;
  bool _loading = true;
  String? _error;
  bool _actionLoading = false;
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
      final token = await TokenStorage.instance.loadContextToken();
      if (!mounted) return;
      if (token == null || token.isEmpty) {
        setState(() {
          _profile = null;
        });
      } else {
        try {
          final me = await AuthRepository().me();
          if (!mounted) return;
          setState(() {
            _profile = me;
          });
        } on DioException catch (e) {
          if (!mounted) return;
          if (e.response?.statusCode == 403 || e.response?.statusCode == 401) {
            setState(() {
              _profile = null;
              _error = null;
            });
          } else {
            setState(() {
              _error = e.toString();
            });
          }
        } catch (e) {
          if (!mounted) return;
          setState(() {
            _profile = null;
            _error = null;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = null;
        _profile = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
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
        title: Text(context.l10n.accountTitle),
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
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Text(context.l10n.commonError(_error!)));
    }

    if (_profile == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.l10n.accountPleaseLogin),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => context.go('/login'),
              child: Text(context.l10n.commonLogin),
            ),
          ],
        ),
      );
    }

    final customer = _profile!['customer'] ?? _profile!['data'];
    final email = customer?['email']?.toString() ?? '-';
    final firstName = customer?['firstName']?.toString() ?? '';
    final lastName = customer?['lastName']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.accountHello(firstName, lastName),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(email),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              OutlinedButton(
                onPressed: () => context.go('/orders'),
                child: Text(context.l10n.accountMyOrders),
              ),
              OutlinedButton(
                onPressed: () => context.go('/addresses'),
                child: Text(context.l10n.accountMyAddresses),
              ),
              OutlinedButton(
                onPressed: () => context.go('/wishlist'),
                child: Text(context.l10n.accountWishlist),
              ),
              OutlinedButton(
                onPressed: _actionLoading
                    ? null
                    : () {
                        StorefrontNavigation.open(
                          context,
                          StorefrontUrl.accountProfile(),
                          title: context.l10n.accountProfile,
                        );
                      },
                child: Text(context.l10n.accountUpdateProfile),
              ),
              OutlinedButton(
                onPressed: _actionLoading
                    ? null
                    : () async {
                        await _openChangeEmailDialog();
                      },
                child: Text(context.l10n.accountChangeEmail),
              ),
              OutlinedButton(
                onPressed: _actionLoading
                    ? null
                    : () {
                        StorefrontNavigation.open(
                          context,
                          StorefrontUrl.accountPassword(),
                          title: context.l10n.accountChangePassword,
                        );
                      },
                child: Text(context.l10n.accountChangePassword),
              ),
              OutlinedButton(
                onPressed: () => context.push('/settings'),
                child: Text(context.l10n.accountLanguageCurrency),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              await AuthRepository().logout();
              if (mounted) setState(() => _profile = null);
            },
            child: Text(context.l10n.accountLogOut),
          ),
        ],
      ),
    );
  }

  Future<void> _openChangeProfileDialog() async {
    final firstNameCtrl = TextEditingController();
    final lastNameCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(context.l10n.accountUpdateProfile),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: firstNameCtrl,
                decoration:
                    InputDecoration(labelText: context.l10n.accountFirstName),
              ),
              TextField(
                controller: lastNameCtrl,
                decoration:
                    InputDecoration(labelText: context.l10n.accountLastName),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.l10n.commonCancel),
            ),
            ElevatedButton(
              onPressed: () async {
                setState(() => _actionLoading = true);
                try {
                  await AuthRepository().changeProfile(
                    firstName: firstNameCtrl.text.trim().isEmpty
                        ? null
                        : firstNameCtrl.text.trim(),
                    lastName: lastNameCtrl.text.trim().isEmpty
                        ? null
                        : lastNameCtrl.text.trim(),
                  );
                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.l10n.accountProfileUpdated)),
                    );
                    await _load();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.l10n.commonError(e.toString())),
                      ),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _actionLoading = false);
                }
              },
              child: Text(context.l10n.commonSave),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openChangeEmailDialog() async {
    final emailCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(context.l10n.accountChangeEmail),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailCtrl,
                decoration:
                    InputDecoration(labelText: context.l10n.accountNewEmail),
              ),
              TextField(
                controller: confirmCtrl,
                decoration: InputDecoration(
                  labelText: context.l10n.accountConfirmEmail,
                ),
              ),
              TextField(
                controller: passwordCtrl,
                decoration: InputDecoration(
                  labelText: context.l10n.accountCurrentPassword,
                ),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.l10n.commonCancel),
            ),
            ElevatedButton(
              onPressed: () async {
                setState(() => _actionLoading = true);
                try {
                  await AuthRepository().changeEmail(
                    email: emailCtrl.text.trim(),
                    emailConfirmation: confirmCtrl.text.trim(),
                    password: passwordCtrl.text,
                  );
                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.l10n.accountEmailUpdated)),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.l10n.commonError(e.toString())),
                      ),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _actionLoading = false);
                }
              },
              child: Text(context.l10n.commonSave),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openChangePasswordDialog() async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(context.l10n.accountChangePassword),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentCtrl,
                decoration: InputDecoration(
                  labelText: context.l10n.accountCurrentPassword,
                ),
                obscureText: true,
              ),
              TextField(
                controller: newCtrl,
                decoration:
                    InputDecoration(labelText: context.l10n.accountNewPassword),
                obscureText: true,
              ),
              TextField(
                controller: confirmCtrl,
                decoration: InputDecoration(
                  labelText: context.l10n.accountConfirmNewPassword,
                ),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.l10n.commonCancel),
            ),
            ElevatedButton(
              onPressed: () async {
                setState(() => _actionLoading = true);
                try {
                  await AuthRepository().changePassword(
                    password: currentCtrl.text,
                    newPassword: newCtrl.text,
                    newPasswordConfirm: confirmCtrl.text,
                  );
                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.l10n.accountPasswordUpdated),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.l10n.commonError(e.toString())),
                      ),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _actionLoading = false);
                }
              },
              child: Text(context.l10n.commonSave),
            ),
          ],
        );
      },
    );
  }
}
