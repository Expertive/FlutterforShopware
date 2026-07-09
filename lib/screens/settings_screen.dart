import 'package:flutter/material.dart';
import '../core/utils/color_utils.dart';
import 'package:go_router/go_router.dart';

import '../core/services/shopware_api.dart';
import '../core/config/app_config.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _api = ShopwareApi();
  Map<String, dynamic>? _context;
  List<Map<String, dynamic>> _availableLanguages = [];
  List<Map<String, dynamic>> _availableCurrencies = [];
  String? _selectedLanguageId;
  String? _selectedCurrencyId;
  bool _loading = false;
  late Color _primaryColor;

  @override
  void initState() {
    super.initState();
    // Start default color
    _primaryColor = _hexToColor(AppConfig.primaryColorHex);
    _loadPrimaryColor();
    _loadContext();
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

  Future<void> _loadContext() async {
    setState(() => _loading = true);
    try {
      final context = await _api.getSalesChannelContext();
      final salesChannel = context['salesChannel'] as Map<String, dynamic>?;
      final currentLanguage = context['language'] as Map<String, dynamic>?;
      final currentCurrency = context['currency'] as Map<String, dynamic>?;

      // Try to get languages and currencies from sales channel first
      var availableLanguages = salesChannel?['languages'] as List? ?? [];
      var availableCurrencies = salesChannel?['currencies'] as List? ?? [];

      // If not available in context, fetch from Store API endpoints
      if (availableLanguages.isEmpty) {
        try {
          availableLanguages = await _api.getAvailableLanguages();
        } catch (e) {
          // If API call fails, keep empty list
        }
      }

      if (availableCurrencies.isEmpty) {
        try {
          availableCurrencies = await _api.getAvailableCurrencies();
        } catch (e) {
          // If API call fails, keep empty list
        }
      }

      if (mounted) {
        setState(() {
          _context = context;
          _availableLanguages = List<Map<String, dynamic>>.from(
            availableLanguages.map((e) => Map<String, dynamic>.from(e as Map)),
          );
          _availableCurrencies = List<Map<String, dynamic>>.from(
            availableCurrencies.map((e) => Map<String, dynamic>.from(e as Map)),
          );
          _selectedLanguageId = currentLanguage?['id']?.toString();
          _selectedCurrencyId = currentCurrency?['id']?.toString();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _updateContext() async {
    if (_selectedLanguageId == null && _selectedCurrencyId == null) return;

    setState(() => _loading = true);
    try {
      await _api.updateContext(
        languageId: _selectedLanguageId,
        currencyId: _selectedCurrencyId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings updated successfully')),
        );
        await _loadContext();
        // Reload the app to reflect language/currency changes
        // Note: You might want to trigger a full app reload here
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
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
        title: const Text('Language & Currency'),
        centerTitle: true,
        backgroundColor: _primaryColor,
        foregroundColor: ColorUtils.foregroundOn(_primaryColor),
      ),
      body: _loading && _context == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_availableLanguages.isNotEmpty) ...[
                    const Text(
                      'Language',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._availableLanguages.map((lang) {
                      final langId = lang['id']?.toString() ?? '';
                      final langName = lang['name']?.toString() ?? langId;

                      return RadioListTile<String>(
                        title: Text(langName),
                        value: langId,
                        groupValue: _selectedLanguageId,
                        onChanged: (value) {
                          setState(() {
                            _selectedLanguageId = value;
                          });
                        },
                        activeColor: _primaryColor,
                      );
                    }),
                    const SizedBox(height: 24),
                  ],
                  if (_availableCurrencies.isNotEmpty) ...[
                    const Text(
                      'Currency',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._availableCurrencies.map((currency) {
                      final currencyId = currency['id']?.toString() ?? '';
                      final currencyName =
                          currency['name']?.toString() ?? currencyId;
                      final currencyIsoCode =
                          currency['isoCode']?.toString() ?? '';
                      final displayName = currencyIsoCode.isNotEmpty
                          ? '$currencyName ($currencyIsoCode)'
                          : currencyName;

                      return RadioListTile<String>(
                        title: Text(displayName),
                        value: currencyId,
                        groupValue: _selectedCurrencyId,
                        onChanged: (value) {
                          setState(() {
                            _selectedCurrencyId = value;
                          });
                        },
                        activeColor: _primaryColor,
                      );
                    }),
                    const SizedBox(height: 24),
                  ],
                  ElevatedButton(
                    onPressed: _loading ? null : _updateContext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: ColorUtils.foregroundOn(_primaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Save Settings'),
                  ),
                ],
              ),
            ),
    );
  }
}
