import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/storage.dart';
import '../data/repositories/auth_repository.dart';
import '../core/config.dart';
import '../core/services/shopware_api.dart';

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
    // Başlangıçta AppConfig'den primary color'ı al (main()'de yüklenmiş olacak)
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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await TokenStorage.instance.loadContextToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _profile = null;
        });
      } else {
        final me = await AuthRepository().me();
        setState(() {
          _profile = me;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
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
        title: const Text('My Account'),
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
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text('Error: $_error'));

    if (_profile == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please log in'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => context.go('/login'),
              child: const Text('Log In'),
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
          Text('Hello, $firstName $lastName',
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(email),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              OutlinedButton(
                  onPressed: () => context.go('/orders'),
                  child: const Text('My Orders')),
              OutlinedButton(
                  onPressed: () => context.go('/addresses'),
                  child: const Text('My Addresses')),
              OutlinedButton(
                  onPressed: () => context.go('/wishlist'),
                  child: const Text('Wishlist')),
              OutlinedButton(
                onPressed: _actionLoading
                    ? null
                    : () async {
                        // Shopware storefront profile update sayfasını browser'da aç
                        final baseUrl = AppConfig.baseUrl.endsWith('/')
                            ? AppConfig.baseUrl
                            : '${AppConfig.baseUrl}/';
                        final profileUrl = '${baseUrl}account/profile';
                        final uri = Uri.parse(profileUrl);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                        }
                      },
                child: const Text('Update Profile'),
              ),
              OutlinedButton(
                  onPressed: _actionLoading
                      ? null
                      : () async {
                          await _openChangeEmailDialog();
                        },
                  child: const Text('Change Email')),
              OutlinedButton(
                onPressed: _actionLoading
                    ? null
                    : () async {
                        // Open Shopware storefront password change page in browser
                        final baseUrl = AppConfig.baseUrl.endsWith('/')
                            ? AppConfig.baseUrl
                            : '${AppConfig.baseUrl}/';
                        final passwordChangeUrl =
                            '${baseUrl}account/profile/password';
                        final uri = Uri.parse(passwordChangeUrl);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                        }
                      },
                child: const Text('Change Password'),
              ),
              OutlinedButton(
                  onPressed: () => context.push('/settings'),
                  child: const Text('Language & Currency')),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              await AuthRepository().logout();
              if (mounted) setState(() => _profile = null);
            },
            child: const Text('Log Out'),
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
          title: const Text('Update Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: firstNameCtrl,
                  decoration: const InputDecoration(labelText: 'First Name')),
              TextField(
                  controller: lastNameCtrl,
                  decoration: const InputDecoration(labelText: 'Last Name')),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel')),
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
                        const SnackBar(content: Text('Profile updated')));
                    await _load();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                } finally {
                  if (mounted) setState(() => _actionLoading = false);
                }
              },
              child: const Text('Save'),
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
          title: const Text('Change Email'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'New Email')),
              TextField(
                  controller: confirmCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Confirm Email')),
              TextField(
                  controller: passwordCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Current Password'),
                  obscureText: true),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel')),
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
                        const SnackBar(content: Text('Email updated')));
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                } finally {
                  if (mounted) setState(() => _actionLoading = false);
                }
              },
              child: const Text('Save'),
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
          title: const Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: currentCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Current Password'),
                  obscureText: true),
              TextField(
                  controller: newCtrl,
                  decoration: const InputDecoration(labelText: 'New Password'),
                  obscureText: true),
              TextField(
                  controller: confirmCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Confirm New Password'),
                  obscureText: true),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel')),
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
                        const SnackBar(content: Text('Password updated')));
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                } finally {
                  if (mounted) setState(() => _actionLoading = false);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
