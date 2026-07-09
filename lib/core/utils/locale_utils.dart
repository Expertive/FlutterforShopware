import 'package:flutter/material.dart';

class LocaleUtils {
  LocaleUtils._();

  static const Locale defaultLocale = Locale('en');

  static const List<Locale> supported = [
    Locale('en'),
    Locale('de'),
  ];

  static Locale? fromShopwareLanguage(Map<String, dynamic> language) {
    final localeMap = language['locale'] as Map<String, dynamic>?;
    final translationCode = language['translationCode'] as Map<String, dynamic>?;
    final code = localeMap?['code']?.toString() ??
        translationCode?['code']?.toString();
    if (code == null || code.isEmpty) return null;
    return matchSupported(parseLocaleCode(code));
  }

  static Locale parseLocaleCode(String code) {
    final normalized = code.replaceAll('_', '-');
    final parts = normalized.split('-');
    if (parts.length >= 2) {
      return Locale(parts[0].toLowerCase(), parts[1].toUpperCase());
    }
    return Locale(parts[0].toLowerCase());
  }

  static Locale fromTag(String? tag) {
    if (tag == null || tag.isEmpty) return defaultLocale;
    return matchSupported(Locale(tag.toLowerCase()));
  }

  static Locale matchSupported(Locale locale) {
    for (final supportedLocale in supported) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return supportedLocale;
      }
    }
    return defaultLocale;
  }

  static Locale? fromLanguageId(
    String? languageId,
    List<Map<String, dynamic>> languages,
  ) {
    if (languageId == null || languageId.isEmpty) return null;
    for (final language in languages) {
      if (language['id']?.toString() == languageId) {
        return fromShopwareLanguage(language);
      }
    }
    return null;
  }
}
