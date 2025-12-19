/// Provider quản lý giao diện của ứng dụng
/// Cung cấp các chức năng:
/// - Quản lý chế độ sáng/tối
/// - Tùy chỉnh màu sắc chủ đạo
/// - Lưu trữ cài đặt giao diện
/// - Tạo theme dựa trên cài đặt
// [HOÀN CHỈNH] lib/providers/theme_provider.dart

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  /// Key lưu trữ chế độ theme trong SharedPreferences
  static const _themeModeKey = 'themeMode';

  /// Key lưu trữ màu sắc đã chọn trong SharedPreferences
  static const _selectedColorKey = 'selectedColor';

  /// Chế độ theme hiện tại (system/light/dark)
  ThemeMode _themeMode = ThemeMode.system;

  /// Màu sắc chủ đạo đã chọn
  Color _selectedColor = Colors.blue;

  ThemeProvider() {
    _loadThemeSettings();
  }

  /// Getter cho chế độ theme hiện tại
  ThemeMode get themeMode => _themeMode;

  /// Getter kiểm tra có đang ở chế độ tối không
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Getter cho màu sắc đã chọn
  Color get selectedColor => _selectedColor;

  /// Tạo MaterialColor từ một màu cơ bản
  /// @param color Màu cơ bản để tạo MaterialColor
  /// @return MaterialColor với các sắc thái khác nhau của màu gốc
  MaterialColor _createMaterialColor(Color color) {
    List strengths = <double>[.05];
    Map<int, Color> swatch = {};
    final int r = color.red, g = color.green, b = color.blue;

    // Tạo các sắc thái màu khác nhau
    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
  }

  /// Theme cho chế độ sáng
  ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primarySwatch: _createMaterialColor(_selectedColor),
      primaryColor: _selectedColor,
      indicatorColor: _selectedColor,
      appBarTheme: AppBarTheme(
        backgroundColor: _selectedColor,
        foregroundColor: Colors.white,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _selectedColor,
        foregroundColor: Colors.white,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  /// Theme cho chế độ tối
  ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: _createMaterialColor(_selectedColor),
      primaryColor: _selectedColor,
      indicatorColor: _selectedColor,
      appBarTheme: AppBarTheme(
        backgroundColor: _selectedColor,
        foregroundColor: Colors.white,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _selectedColor,
        foregroundColor: Colors.white,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  /// Tải cài đặt theme từ SharedPreferences
  void _loadThemeSettings() async {
    final prefs = await SharedPreferences.getInstance();
    // Tải chế độ theme
    final themeIndex = prefs.getInt(_themeModeKey) ?? 0;
    _themeMode = ThemeMode.values[themeIndex];

    // Tải màu sắc đã chọn
    final colorValue = prefs.getInt(_selectedColorKey);
    if (colorValue != null) {
      _selectedColor = Color(colorValue);
    } else {
      _selectedColor = Colors.blue;
    }
    notifyListeners();
  }

  /// Chuyển đổi giữa chế độ sáng và tối
  /// @param isDark true nếu muốn chuyển sang chế độ tối
  void toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, _themeMode.index);
    notifyListeners();
  }

  /// Thay đổi màu sắc chủ đạo
  /// @param color Màu sắc mới
  void setSelectedColor(Color color) async {
    debugPrint("Debug: Đặt màu chủ đề mới: $color");
    _selectedColor = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_selectedColorKey, color.value);
    notifyListeners();
  }

  /// Chuyển đổi giữa chế độ sáng và tối (toggle)
  void toggleDarkMode() {
    toggleTheme(!isDarkMode);
  }
}
