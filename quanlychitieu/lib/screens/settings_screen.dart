/// Màn hình cài đặt ứng dụng
/// Bao gồm các chức năng:
/// - Cài đặt giao diện (chế độ tối, màu sắc)
/// - Quản lý nhắc nhở
/// - Quản lý danh mục
/// - Xuất dữ liệu
/// - Thông tin ứng dụng
//lib/screens/settings_screen.dart

// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../helpers/import_export_helper.dart';
import '../models/category.dart' as app_models;
import '../providers/auth_provider.dart';
import '../providers/category_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/currency_provider.dart';
import '../providers/language_provider.dart';
import '../l10n/app_localizations.dart';
import 'reminder_screen.dart';
import '../providers/date_range_provider.dart';
import 'login_screen.dart';
import '../widgets/theme_switch.dart';
import '../utils/category_emoji_mapper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final categoryProvider = context.watch<CategoryProvider>();
    final authProvider = context.watch<AuthProvider>();
    final currencyProvider = context.watch<CurrencyProvider>();
    final user = authProvider.currentUser;
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1B2421) : const Color(0xFFF5F9F6),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),
            // Main content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
            const SizedBox(height: 16),
                    // Profile Section
                    _buildProfileSection(context, user),
                    const SizedBox(height: 32),
                    // General Section
                    _buildGeneralSection(context, themeProvider, currencyProvider, context.watch<LanguageProvider>()),
                    const SizedBox(height: 24),
                    // Category Management Section
                    _buildCategoryManagementSection(context, categoryProvider),
                    const SizedBox(height: 24),
                    // Account & Security Section
                    _buildAccountSecuritySection(context, categoryProvider),
                    const SizedBox(height: 24),
                    // Log Out Section
                    _buildLogOutSection(context, authProvider),
                    const SizedBox(height: 24),
                    // App Version
                    _buildAppVersion(context),
                    const SizedBox(height: 100), // Space for bottom nav
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2421) : const Color(0xFFF5F9F6),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.grey[900]),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              AppLocalizations.of(context)?.settings ?? 'Cài đặt',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey[900],
              ),
            ),
          ),
          const SizedBox(width: 48), // Balance space
        ],
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context, user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.7),
                  ],
                ),
                border: Border.all(
                  color: isDark ? const Color(0xFF25332E) : Colors.white,
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: user?.avatar != null
                    ? Image.network(
                        user!.avatar!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.person,
                            size: 48,
                            color: Colors.white,
                          );
                        },
                      )
                    : Container(
                        color: Theme.of(context).primaryColor,
                        child: Icon(
                          Icons.person,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? const Color(0xFF25332E) : Colors.white,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.edit,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
            const SizedBox(height: 16),
        Text(
          user?.username ?? 'User',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.grey[900],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Premium Member',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildGeneralSection(BuildContext context, ThemeProvider themeProvider, CurrencyProvider currencyProvider, LanguageProvider languageProvider) {
    final isDark = themeProvider.isDarkMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            AppLocalizations.of(context)?.general ?? 'GENERAL',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).primaryColor,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF25332E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildSettingsItem(
                context,
                icon: Icons.dark_mode,
                iconColor: Colors.blue,
                title: AppLocalizations.of(context)?.darkMode ?? 'Dark Mode',
                trailing: ThemeSwitch(
                  value: themeProvider.isDarkMode,
                  onChanged: (value) {
                    themeProvider.toggleDarkMode();
                  },
                ),
              ),
              _buildDivider(context),
              _buildSettingsItem(
                context,
                icon: Icons.attach_money,
                iconColor: Colors.green,
                title: AppLocalizations.of(context)?.currency ?? 'Currency',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${currencyProvider.currencyCode} (${currencyProvider.currencySymbol})',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      size: 20,
                    ),
                  ],
                ),
                onTap: () => _showCurrencyDialog(context, currencyProvider),
              ),
              _buildDivider(context),
              _buildSettingsItem(
                context,
                icon: Icons.language,
                iconColor: Colors.blue,
                title: AppLocalizations.of(context)?.language ?? 'Language',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      languageProvider.getLanguageName(languageProvider.currentLanguage),
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      size: 20,
                    ),
                  ],
                ),
                onTap: () => _showLanguageDialog(context, languageProvider),
              ),
              _buildDivider(context),
              _buildSettingsItem(
                context,
                icon: Icons.palette,
                iconColor: themeProvider.selectedColor,
                title: AppLocalizations.of(context)?.themeColor ?? 'Theme Color',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: themeProvider.selectedColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                          width: 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      size: 20,
                    ),
                  ],
                ),
                onTap: () => _showThemeSelectionDialog(context, themeProvider),
              ),
              _buildDivider(context),
              _buildSettingsItem(
                context,
                icon: Icons.notifications,
                iconColor: Colors.orange,
                title: AppLocalizations.of(context)?.notifications ?? 'Notifications',
                trailing: Icon(
                  Icons.chevron_right,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  size: 20,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ReminderScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryManagementSection(BuildContext context, CategoryProvider categoryProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            AppLocalizations.of(context)?.management ?? 'QUẢN LÝ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).primaryColor,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF25332E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildSettingsItem(
                context,
                icon: Icons.category,
                iconColor: Colors.blue,
                title: AppLocalizations.of(context)?.categoryManagement ?? 'Quản lý danh mục',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.add_circle_outline,
                        color: Theme.of(context).primaryColor,
                        size: 24,
                      ),
                      onPressed: () => _showAddOrEditCategoryDialog(context),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      size: 20,
                    ),
                  ],
                ),
                onTap: () => _showCategoryListDialog(context, categoryProvider),
              ),
              if (categoryProvider.categories.isNotEmpty) ...[
                _buildDivider(context),
                ...categoryProvider.categories.take(3).map((category) {
                  return _buildCategoryListItem(context, category, categoryProvider);
                }).toList(),
                if (categoryProvider.categories.length > 3)
                  _buildSettingsItem(
                    context,
                    icon: Icons.more_horiz,
                    iconColor: Colors.grey,
                    title: 'Xem thêm ${categoryProvider.categories.length - 3} danh mục',
                    trailing: Icon(
                      Icons.chevron_right,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      size: 20,
                    ),
                    onTap: () => _showCategoryListDialog(context, categoryProvider),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryListItem(BuildContext context, app_models.Category category, CategoryProvider categoryProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showAddOrEditCategoryDialog(context, category: category),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: category.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    CategoryEmojiMapper.getEmojiForIcon(category.icon),
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  category.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.grey[900],
                  ),
                ),
              ),
              Icon(
                Icons.edit_outlined,
                size: 20,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCategoryListDialog(BuildContext context, CategoryProvider categoryProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Danh sách danh mục'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: categoryProvider.categories.length,
            itemBuilder: (context, index) {
              final category = categoryProvider.categories[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: category.color,
                  child: Text(
                    CategoryEmojiMapper.getEmojiForIcon(category.icon),
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                title: Text(category.name),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _showAddOrEditCategoryDialog(context, category: category);
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _showAddOrEditCategoryDialog(context);
            },
            child: const Text('Thêm mới'),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, LanguageProvider languageProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final languages = LanguageProvider.getSupportedLanguages();
    
    String selectedLanguage = languageProvider.currentLanguage;
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(AppLocalizations.of(context)?.selectLanguage ?? 'Chọn ngôn ngữ'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: languages.length,
              itemBuilder: (context, index) {
                final language = languages[index];
                final isSelected = selectedLanguage == language['code'];
                return RadioListTile<String>(
                  title: Text(language['nativeName']!),
                  subtitle: Text(language['name']!),
                  value: language['code']!,
                  groupValue: selectedLanguage,
                  activeColor: Theme.of(context).primaryColor,
                  onChanged: (value) async {
                    setState(() {
                      selectedLanguage = value!;
                    });
                    
                    // Save to provider
                    await languageProvider.changeLanguage(selectedLanguage);
                    
                    if (context.mounted) {
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppLocalizations.of(context)?.languageChanged(language['nativeName']!) ?? 'Đã chọn ${language['nativeName']}')),
                      );
                    }
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(AppLocalizations.of(context)?.close ?? 'Đóng'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCurrencyDialog(BuildContext context, CurrencyProvider currencyProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencies = CurrencyProvider.getSupportedCurrencies();
    
    String selectedCurrency = currencyProvider.currencyCode;
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Chọn tiền tệ'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: currencies.length,
              itemBuilder: (context, index) {
                final currency = currencies[index];
                final isSelected = selectedCurrency == currency['code'];
                return RadioListTile<String>(
                  title: Text('${currency['symbol']} ${currency['name']}'),
                  subtitle: Text(currency['code'] as String),
                  value: currency['code'] as String,
                  groupValue: selectedCurrency,
                  activeColor: Theme.of(context).primaryColor,
                  onChanged: (value) async {
                    setState(() {
                      selectedCurrency = value!;
                    });
                    
                    // Save to provider
                    await currencyProvider.changeCurrency(
                      code: currency['code']!,
                      symbol: currency['symbol']!,
                      name: currency['name']!,
                      locale: currency['locale']!,
                    );
                    
                    if (context.mounted) {
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Đã chọn ${currency['name']}')),
                      );
                    }
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Đóng'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSecuritySection(BuildContext context, CategoryProvider categoryProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'ACCOUNT & SECURITY',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).primaryColor,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF25332E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildSettingsItem(
                context,
                icon: Icons.cloud_sync,
                iconColor: Colors.purple,
                title: 'Sync Data',
                subtitle: 'Last synced: 2 mins ago',
                trailing: Icon(
                  Icons.chevron_right,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  size: 20,
                ),
                onTap: () {},
              ),
              _buildDivider(context),
              _buildSettingsItem(
                context,
                icon: Icons.face,
                iconColor: Colors.indigo,
                title: 'Face ID Login',
                trailing: _buildToggle(context, true, (value) {}),
              ),
              _buildDivider(context),
              _buildSettingsItem(
                context,
                icon: Icons.file_download,
                iconColor: Colors.teal,
                title: 'Export CSV',
                trailing: Icon(
                  Icons.chevron_right,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  size: 20,
                ),
                onTap: () => _showImportExportDialog(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogOutSection(BuildContext context, AuthProvider authProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF25332E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            await authProvider.logout();
            if (context.mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (ctx) => const LoginScreen()),
              );
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.logout,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Log Out',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppVersion(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(
          'App Version 2.4.1 (Build 204)',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Made with 💚 by ThanhTuan148',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : Colors.grey[900],
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null)
                Center(
                  child: trailing,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggle(BuildContext context, bool value, ValueChanged<bool> onChanged) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 28,
        decoration: BoxDecoration(
          color: value ? Theme.of(context).primaryColor : (isDark ? Colors.grey[600] : Colors.grey[200]),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              left: value ? 20 : 2,
              top: 2,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(
      height: 1,
      thickness: 1,
      indent: 72,
      color: isDark ? Colors.grey[800] : Colors.grey[100],
    );
  }

  /// Xây dựng tiêu đề cho mỗi phần
  ///
  /// Parameters:
  /// - title: Tiêu đề của phần
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 8.0, left: 4.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  /// Xây dựng card cài đặt giao diện
  ///
  /// Parameters:
  /// - themeProvider: Provider quản lý theme
  Card _buildThemeCard(ThemeProvider themeProvider) {
    return Card(
      elevation: 2,
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Chế độ tối'),
            value: themeProvider.isDarkMode,
            onChanged: (value) => themeProvider.toggleDarkMode(),
            secondary: const Icon(Icons.dark_mode_outlined),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.color_lens_outlined),
            title: const Text('Chủ đề'),
            trailing: CircleAvatar(
              radius: 12,
              backgroundColor: themeProvider.selectedColor,
            ),
            onTap: () => _showThemeSelectionDialog(context, themeProvider),
          ),
        ],
      ),
    );
  }

  /// Xây dựng card quản lý nhắc nhở
  Card _buildReminderCard() {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: const Icon(Icons.notifications_outlined),
        title: const Text('Quản lý nhắc nhở'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ReminderScreen()),
          );
        },
      ),
    );
  }

  /// Xây dựng card quản lý danh mục
  ///
  /// Parameters:
  /// - categoryProvider: Provider quản lý danh mục
  Card _buildCategoryCard(CategoryProvider categoryProvider) {
    return Card(
      elevation: 2,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: const Text('Quản lý danh mục'),
            trailing: IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => _showAddOrEditCategoryDialog(context),
            ),
          ),
          if (categoryProvider.categories.isNotEmpty)
            const Divider(height: 1, indent: 16, endIndent: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categoryProvider.categories.length,
            itemBuilder: (context, index) {
              final category = categoryProvider.categories[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: category.color,
                  child: Text(
                    CategoryEmojiMapper.getEmojiForIcon(category.icon),
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                title: Text(category.name),
                trailing: const Icon(
                  Icons.edit_outlined,
                  size: 20,
                  color: Colors.grey,
                ),
                onTap:
                    () => _showAddOrEditCategoryDialog(
                      context,
                      category: category,
                    ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Xây dựng card xuất dữ liệu
  Card _buildImportExportCard() {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: const Icon(Icons.import_export_outlined),
        title: const Text('Xuất dữ liệu'),
        subtitle: const Text('Sao lưu qua Excel'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _showImportExportDialog(context),
      ),
    );
  }

  /// Xây dựng card thông tin ứng dụng
  Card _buildAppInfoCard() {
    return Card(
      elevation: 2,
      child: Column(
        children: [
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('App Quản Lý Chi Tiêu'),
            subtitle: Text('Phiên bản 7.0.0 (Firebase)'),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.group_outlined),
            title: const Text('Thành viên nhóm'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showTeamInfoDialog(context),
          ),
        ],
      ),
    );
  }

  /// Hiển thị dialog xuất dữ liệu
  void _showImportExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Xuất dữ liệu'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.file_download),
                  title: const Text('Xuất ra Excel'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    final expenses = context.read<ExpenseProvider>().expenses;
                    final categories =
                        context.read<CategoryProvider>().categories;
                    final dateRange =
                        context.read<DateRangeProvider>().currentRange;
                    ImportExportHelper.exportToExcel(
                      context,
                      expenses,
                      categories,
                      dateRange,
                      'ChiTieu_${DateFormat('yyyyMMdd').format(DateTime.now())}',
                    );
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Đóng'),
              ),
            ],
          ),
    );
  }

  /// Hiển thị dialog thêm/sửa danh mục
  ///
  /// Parameters:
  /// - context: BuildContext
  /// - category: Danh mục cần sửa (nếu là sửa)
  void _showAddOrEditCategoryDialog(
    BuildContext context, {
    app_models.Category? category,
  }) {
    final bool isEditing = category != null;
    final nameController = TextEditingController(text: category?.name ?? '');
    Color selectedColor = category?.color ?? Colors.blue;
    IconData selectedIcon = category?.icon ?? Icons.shopping_cart;

    // Danh sách màu sắc có sẵn
    final List<Color> colors = [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
    ];

    // Danh sách icon có sẵn
    final List<IconData> icons = [
      Icons.restaurant,
      Icons.shopping_cart,
      Icons.directions_car,
      Icons.movie,
      Icons.receipt,
      Icons.home,
      Icons.flight,
      Icons.school,
      Icons.medical_services,
      Icons.fitness_center,
      Icons.card_giftcard,
      Icons.attach_money,
      Icons.emoji_events,
      Icons.sports_esports,
      Icons.devices,
      Icons.pets,
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateInDialog) {
            return AlertDialog(
              title: Text(isEditing ? 'Sửa Danh mục' : 'Thêm Danh mục'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Tên danh mục',
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Chọn màu',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 40,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: colors.length,
                          itemBuilder: (context, index) {
                            final color = colors[index];
                            final isSelected = color == selectedColor;
                            return GestureDetector(
                              onTap:
                                  () => setStateInDialog(
                                    () => selectedColor = color,
                                  ),
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? Theme.of(context).indicatorColor
                                            : Colors.transparent,
                                    width: 3,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Chọn biểu tượng',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: GridView.builder(
                          padding: const EdgeInsets.all(8),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 5,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                          itemCount: icons.length,
                          itemBuilder: (context, index) {
                            final icon = icons[index];
                            final isSelected =
                                icon.codePoint == selectedIcon.codePoint;
                            return InkWell(
                              onTap:
                                  () => setStateInDialog(
                                    () => selectedIcon = icon,
                                  ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? selectedColor
                                          : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    CategoryEmojiMapper.getEmojiForIcon(icon),
                                    style: TextStyle(
                                      fontSize: 20,
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actionsAlignment: MainAxisAlignment.spaceBetween,
              actions: [
                if (isEditing)
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _confirmDeleteCategory(context, category);
                    },
                    child: const Text('Xóa'),
                  )
                else
                  const SizedBox.shrink(),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Hủy'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final authProvider = context.read<AuthProvider>();
                        if (authProvider.currentUser == null ||
                            nameController.text.trim().isEmpty) {
                          return;
                        }

                        final newCategory = app_models.Category(
                          id: category?.id,
                          name: nameController.text.trim(),
                          icon: selectedIcon,
                          color: selectedColor,
                          userId: authProvider.currentUser!.id,
                        );
                        final categoryProvider =
                            context.read<CategoryProvider>();
                        if (isEditing) {
                          categoryProvider.updateCategory(newCategory);
                        } else {
                          categoryProvider.addCategory(newCategory);
                        }
                        Navigator.of(ctx).pop();
                      },
                      child: const Text('Lưu'),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Hiển thị dialog xác nhận xóa danh mục
  ///
  /// Parameters:
  /// - context: BuildContext
  /// - category: Danh mục cần xóa
  Future<bool?> _confirmDeleteCategory(
    BuildContext context,
    app_models.Category category,
  ) {
    return showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Xóa danh mục'),
            content: Text(
              'Bạn có chắc muốn xóa danh mục "${category.name}"? Thao tác này không thể hoàn tác.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Hủy'),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Xóa'),
              ),
            ],
          ),
    );
  }

  /// Hiển thị dialog thông tin thành viên nhóm
  void _showTeamInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Thông tin thành viên nhóm:'),
            content: const SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tên: Trương Thanh Tuấn\nMSSV: 2001224546'),
                  SizedBox(height: 12),
                  Text('Tên: Phạm Hồ Thúy Vy\nMSSV: 2001225958'),
                  SizedBox(height: 12),
                  Text('Tên: Lê Trần Ngọc Yến\nMSSV: 2001226134'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
            ],
          ),
    );
  }

  /// Hiển thị dialog chọn màu chủ đề
  ///
  /// Parameters:
  /// - context: BuildContext
  /// - themeProvider: Provider quản lý theme
  void _showThemeSelectionDialog(
    BuildContext context,
    ThemeProvider themeProvider,
  ) {
    final List<Color> themeColors = [
      // Popular theme colors
      const Color(0xFF4CAF50), // Green (default)
      const Color(0xFF2196F3), // Blue
      const Color(0xFF9C27B0), // Purple
      const Color(0xFFF44336), // Red
      const Color(0xFFFF9800), // Orange
      const Color(0xFF00BCD4), // Cyan
      const Color(0xFFE91E63), // Pink
      const Color(0xFF795548), // Brown
      const Color(0xFF607D8B), // Blue Grey
      const Color(0xFF3F51B5), // Indigo
      const Color(0xFF009688), // Teal
      const Color(0xFFFFC107), // Amber
      const Color(0xFF8BC34A), // Light Green
      const Color(0xFFFF5722), // Deep Orange
      const Color(0xFF673AB7), // Deep Purple
      const Color(0xFF00E676), // Green Accent
    ];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Chọn Chủ đề'),
          content: SingleChildScrollView(
            child: Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children:
                  themeColors.map((color) {
                    return GestureDetector(
                      onTap: () {
                        themeProvider.setSelectedColor(color);
                        Navigator.of(dialogContext).pop();
                      },
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: color,
                        child:
                            themeProvider.selectedColor == color
                                ? const Icon(Icons.check, color: Colors.white)
                                : null,
                      ),
                    );
                  }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Hủy'),
            ),
          ],
        );
      },
    );
  }
}
