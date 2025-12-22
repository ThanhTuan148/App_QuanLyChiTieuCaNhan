/// Provider quản lý ngôn ngữ ứng dụng
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  String _currentLanguage = 'vi'; // 'vi' hoặc 'en'
  
  static const String _languageKey = 'app_language';

  // Getters
  String get currentLanguage => _currentLanguage;
  String get localeCode => _currentLanguage == 'vi' ? 'vi' : 'en';
  String get localeCountryCode => _currentLanguage == 'vi' ? 'VN' : 'US';
  
  /// Khởi tạo và load ngôn ngữ từ SharedPreferences
  Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString(_languageKey) ?? 'vi';
    notifyListeners();
  }

  /// Lưu ngôn ngữ vào SharedPreferences
  Future<void> saveLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, _currentLanguage);
  }

  /// Đổi ngôn ngữ
  Future<void> changeLanguage(String languageCode) async {
    if (languageCode != 'vi' && languageCode != 'en') {
      return;
    }
    _currentLanguage = languageCode;
    await saveLanguage();
    notifyListeners();
  }

  /// Lấy tên ngôn ngữ hiển thị
  String getLanguageName(String code) {
    switch (code) {
      case 'vi':
        return 'Tiếng Việt';
      case 'en':
        return 'English';
      default:
        return 'Tiếng Việt';
    }
  }

  /// Danh sách ngôn ngữ hỗ trợ
  static List<Map<String, String>> getSupportedLanguages() {
    return [
      {'code': 'vi', 'name': 'Tiếng Việt', 'nativeName': 'Tiếng Việt'},
      {'code': 'en', 'name': 'English', 'nativeName': 'English'},
    ];
  }
}

