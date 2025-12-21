/// Provider quản lý tiền tệ
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class CurrencyProvider with ChangeNotifier {
  String _currencyCode = 'VND';
  String _currencySymbol = '₫';
  String _currencyName = 'Vietnamese Dong';
  String _locale = 'vi_VN';

  static const String _currencyCodeKey = 'currency_code';
  static const String _currencySymbolKey = 'currency_symbol';
  static const String _currencyNameKey = 'currency_name';
  static const String _localeKey = 'currency_locale';

  // Getters
  String get currencyCode => _currencyCode;
  String get currencySymbol => _currencySymbol;
  String get currencyName => _currencyName;
  String get locale => _locale;

  // Get currency formatter
  NumberFormat get currencyFormat {
    return NumberFormat.currency(
      locale: _locale,
      symbol: _currencySymbol,
      decimalDigits: _currencyCode == 'VND' || _currencyCode == 'JPY' ? 0 : 2,
    );
  }

  /// Khởi tạo và load currency từ SharedPreferences
  Future<void> loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    _currencyCode = prefs.getString(_currencyCodeKey) ?? 'VND';
    _currencySymbol = prefs.getString(_currencySymbolKey) ?? '₫';
    _currencyName = prefs.getString(_currencyNameKey) ?? 'Vietnamese Dong';
    _locale = prefs.getString(_localeKey) ?? 'vi_VN';
    notifyListeners();
  }

  /// Lưu currency vào SharedPreferences
  Future<void> saveCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyCodeKey, _currencyCode);
    await prefs.setString(_currencySymbolKey, _currencySymbol);
    await prefs.setString(_currencyNameKey, _currencyName);
    await prefs.setString(_localeKey, _locale);
  }

  /// Đổi currency
  Future<void> changeCurrency({
    required String code,
    required String symbol,
    required String name,
    required String locale,
  }) async {
    _currencyCode = code;
    _currencySymbol = symbol;
    _currencyName = name;
    _locale = locale;
    await saveCurrency();
    notifyListeners();
  }

  /// Danh sách currencies hỗ trợ
  static List<Map<String, String>> getSupportedCurrencies() {
    return [
      {'code': 'USD', 'symbol': '\$', 'name': 'US Dollar', 'locale': 'en_US'},
      {'code': 'VND', 'symbol': '₫', 'name': 'Vietnamese Dong', 'locale': 'vi_VN'},
      {'code': 'EUR', 'symbol': '€', 'name': 'Euro', 'locale': 'en_EU'},
      {'code': 'GBP', 'symbol': '£', 'name': 'British Pound', 'locale': 'en_GB'},
      {'code': 'JPY', 'symbol': '¥', 'name': 'Japanese Yen', 'locale': 'ja_JP'},
    ];
  }
}

