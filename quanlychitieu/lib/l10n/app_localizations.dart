/// Localization cho ứng dụng
import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'vi': {
      // Common
      'app_name': 'Quản lý Chi tiêu',
      'welcome_back': 'Welcome back,',
      'user': 'User',
      'search': 'Tìm kiếm',
      'details': 'Chi tiết',
      'calendar': 'Lịch',
      
      // Home Screen
      'total_balance': 'Tổng số dư',
      'income': 'Thu nhập',
      'expense': 'Chi tiêu',
      'statistics': 'Thống kê',
      'see_all': 'Xem tất cả',
      'recent_transactions': 'Recent Transactions',
      'today': 'Today',
      'no_data': 'Chưa có dữ liệu',
      'last_7_days': '7 ngày gần nhất',
      
      // Settings
      'settings': 'Cài đặt',
      'general': 'GENERAL',
      'dark_mode': 'Dark Mode',
      'currency': 'Currency',
      'language': 'Language',
      'theme_color': 'Theme Color',
      'notifications': 'Notifications',
      'management': 'QUẢN LÝ',
      'category_management': 'Quản lý danh mục',
      'view_more_categories': 'Xem thêm {count} danh mục',
      'account_security': 'ACCOUNT & SECURITY',
      'sync_data': 'Sync Data',
      'last_synced': 'Last synced: {time}',
      'face_id_login': 'Face ID Login',
      'export_csv': 'Export CSV',
      'log_out': 'Log Out',
      'app_version': 'App Version {version} (Build {build})',
      'made_with': 'Made with 💚 by ThanhTuan148',
      'premium_member': 'Premium Member',
      
      // Language
      'vietnamese': 'Tiếng Việt',
      'english': 'English',
      'select_language': 'Chọn ngôn ngữ',
      'language_changed': 'Đã chọn {language}',
      'close': 'Đóng',
      
      // Currency
      'select_currency': 'Chọn tiền tệ',
      'currency_changed': 'Đã chọn {currency}',
      
      // Category
      'category_list': 'Danh sách danh mục',
      'add_category': 'Thêm Danh mục',
      'edit_category': 'Sửa Danh mục',
      'delete_category': 'Xóa danh mục',
      'category_name': 'Tên danh mục',
      'select_color': 'Chọn màu',
      'select_icon': 'Chọn biểu tượng',
      'save': 'Lưu',
      'cancel': 'Hủy',
      'delete': 'Xóa',
      'confirm_delete_category': 'Bạn có chắc muốn xóa danh mục "{name}"? Thao tác này không thể hoàn tác.',
      'add_new': 'Thêm mới',
      
      // Team Info
      'team_members': 'Thông tin thành viên nhóm:',
      
      // Import Export
      'export_data': 'Xuất dữ liệu',
      'export_to_excel': 'Xuất ra Excel',
    },
    'en': {
      // Common
      'app_name': 'Expense Manager',
      'welcome_back': 'Welcome back,',
      'user': 'User',
      'search': 'Search',
      'details': 'Details',
      'calendar': 'Calendar',
      
      // Home Screen
      'total_balance': 'Total Balance',
      'income': 'Income',
      'expense': 'Expense',
      'statistics': 'Statistics',
      'see_all': 'See All',
      'recent_transactions': 'Recent Transactions',
      'today': 'Today',
      'no_data': 'No data yet',
      'last_7_days': 'Last 7 days',
      
      // Settings
      'settings': 'Settings',
      'general': 'GENERAL',
      'dark_mode': 'Dark Mode',
      'currency': 'Currency',
      'language': 'Language',
      'theme_color': 'Theme Color',
      'notifications': 'Notifications',
      'management': 'MANAGEMENT',
      'category_management': 'Category Management',
      'view_more_categories': 'View {count} more categories',
      'account_security': 'ACCOUNT & SECURITY',
      'sync_data': 'Sync Data',
      'last_synced': 'Last synced: {time}',
      'face_id_login': 'Face ID Login',
      'export_csv': 'Export CSV',
      'log_out': 'Log Out',
      'app_version': 'App Version {version} (Build {build})',
      'made_with': 'Made with 💚 by ThanhTuan148',
      'premium_member': 'Premium Member',
      
      // Language
      'vietnamese': 'Tiếng Việt',
      'english': 'English',
      'select_language': 'Select Language',
      'language_changed': 'Selected {language}',
      'close': 'Close',
      
      // Currency
      'select_currency': 'Select Currency',
      'currency_changed': 'Selected {currency}',
      
      // Category
      'category_list': 'Category List',
      'add_category': 'Add Category',
      'edit_category': 'Edit Category',
      'delete_category': 'Delete Category',
      'category_name': 'Category Name',
      'select_color': 'Select Color',
      'select_icon': 'Select Icon',
      'save': 'Save',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'confirm_delete_category': 'Are you sure you want to delete category "{name}"? This action cannot be undone.',
      'add_new': 'Add New',
      
      // Team Info
      'team_members': 'Team Members Information:',
      
      // Import Export
      'export_data': 'Export Data',
      'export_to_excel': 'Export to Excel',
    },
  };

  String translate(String key, {Map<String, String>? params}) {
    String value = _localizedValues[locale.languageCode]?[key] ?? key;
    
    // Replace parameters
    if (params != null) {
      params.forEach((paramKey, paramValue) {
        value = value.replaceAll('{$paramKey}', paramValue);
      });
    }
    
    return value;
  }

  // Helper methods for common translations
  String get appName => translate('app_name');
  String get welcomeBack => translate('welcome_back');
  String get user => translate('user');
  String get search => translate('search');
  String get details => translate('details');
  String get calendar => translate('calendar');
  String get totalBalance => translate('total_balance');
  String get income => translate('income');
  String get expense => translate('expense');
  String get statistics => translate('statistics');
  String get seeAll => translate('see_all');
  String get recentTransactions => translate('recent_transactions');
  String get today => translate('today');
  String get noData => translate('no_data');
  String get last7Days => translate('last_7_days');
  String get settings => translate('settings');
  String get general => translate('general');
  String get darkMode => translate('dark_mode');
  String get currency => translate('currency');
  String get language => translate('language');
  String get themeColor => translate('theme_color');
  String get notifications => translate('notifications');
  String get management => translate('management');
  String get categoryManagement => translate('category_management');
  String viewMoreCategories(int count) => translate('view_more_categories', params: {'count': count.toString()});
  String get accountSecurity => translate('account_security');
  String get syncData => translate('sync_data');
  String lastSynced(String time) => translate('last_synced', params: {'time': time});
  String get faceIdLogin => translate('face_id_login');
  String get exportCsv => translate('export_csv');
  String get logOut => translate('log_out');
  String appVersion(String version, String build) => translate('app_version', params: {'version': version, 'build': build});
  String get madeWith => translate('made_with');
  String get premiumMember => translate('premium_member');
  String get vietnamese => translate('vietnamese');
  String get english => translate('english');
  String get selectLanguage => translate('select_language');
  String languageChanged(String language) => translate('language_changed', params: {'language': language});
  String get close => translate('close');
  String get selectCurrency => translate('select_currency');
  String currencyChanged(String currency) => translate('currency_changed', params: {'currency': currency});
  String get categoryList => translate('category_list');
  String get addCategory => translate('add_category');
  String get editCategory => translate('edit_category');
  String get deleteCategory => translate('delete_category');
  String get categoryName => translate('category_name');
  String get selectColor => translate('select_color');
  String get selectIcon => translate('select_icon');
  String get save => translate('save');
  String get cancel => translate('cancel');
  String get delete => translate('delete');
  String confirmDeleteCategory(String name) => translate('confirm_delete_category', params: {'name': name});
  String get addNew => translate('add_new');
  String get teamMembers => translate('team_members');
  String get exportData => translate('export_data');
  String get exportToExcel => translate('export_to_excel');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['vi', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}


