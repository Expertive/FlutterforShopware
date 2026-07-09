import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage.dart';
import '../utils/locale_utils.dart';

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(LocaleUtils.defaultLocale) {
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final tag = await TokenStorage.instance.loadLocaleTag();
    if (tag != null && tag.isNotEmpty) {
      state = LocaleUtils.fromTag(tag);
    }
  }

  Future<void> setLocale(Locale locale) async {
    final matched = LocaleUtils.matchSupported(locale);
    state = matched;
    await TokenStorage.instance.saveLocaleTag(matched.languageCode);
  }

  Future<void> setFromShopwareLanguage(Map<String, dynamic> language) async {
    final locale = LocaleUtils.fromShopwareLanguage(language);
    if (locale != null) {
      await setLocale(locale);
    }
  }

  Future<void> setFromLanguageId(
    String? languageId,
    List<Map<String, dynamic>> languages,
  ) async {
    final locale = LocaleUtils.fromLanguageId(languageId, languages);
    if (locale != null) {
      await setLocale(locale);
    }
  }
}

final localeProvider =
    StateNotifierProvider<LocaleNotifier, Locale>((ref) => LocaleNotifier());
