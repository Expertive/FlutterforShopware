import 'package:intl/intl.dart';

/// Formats monetary amounts according to the active sales-channel currency.
class CurrencyFormatter {
  CurrencyFormatter._();

  static NumberFormat forIsoCode(String? isoCode) {
    switch (isoCode?.toUpperCase()) {
      case 'EUR':
        return NumberFormat.currency(
          locale: 'de_DE',
          symbol: '€',
          decimalDigits: 2,
        );
      case 'USD':
        return NumberFormat.currency(
          locale: 'en_US',
          symbol: r'$',
          decimalDigits: 2,
        );
      case 'GBP':
        return NumberFormat.currency(
          locale: 'en_GB',
          symbol: '£',
          decimalDigits: 2,
        );
      case 'TRY':
        return NumberFormat.currency(
          locale: 'tr_TR',
          symbol: '₺',
          decimalDigits: 2,
        );
      case 'CHF':
        return NumberFormat.currency(
          locale: 'de_CH',
          symbol: 'CHF',
          decimalDigits: 2,
        );
      case 'JPY':
        return NumberFormat.currency(
          locale: 'ja_JP',
          symbol: '¥',
          decimalDigits: 0,
        );
      case 'PLN':
        return NumberFormat.currency(
          locale: 'pl_PL',
          symbol: 'zł',
          decimalDigits: 2,
        );
      case 'CZK':
        return NumberFormat.currency(
          locale: 'cs_CZ',
          symbol: 'Kč',
          decimalDigits: 2,
        );
      default:
        return NumberFormat.currency(
          locale: 'de_DE',
          symbol: '€',
          decimalDigits: 2,
        );
    }
  }

  static String format(dynamic amount, String? isoCode) {
    if (amount == null) return '-';
    final num value;
    if (amount is num) {
      value = amount;
    } else {
      value = num.tryParse(amount.toString()) ?? 0;
    }
    return forIsoCode(isoCode).format(value);
  }
}
