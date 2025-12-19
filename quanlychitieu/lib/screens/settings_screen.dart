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
import 'reminder_screen.dart';
import '../providers/date_range_provider.dart';

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

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildSectionTitle('Giao diện'),
            _buildThemeCard(themeProvider),
            const SizedBox(height: 16),
            _buildSectionTitle('Quản lý'),
            _buildReminderCard(),
            _buildCategoryCard(categoryProvider),
            const SizedBox(height: 16),
            _buildSectionTitle('Dữ liệu'),
            _buildImportExportCard(),
            const SizedBox(height: 16),
            _buildSectionTitle('Thông tin'),
            _buildAppInfoCard(),
          ],
        ),
      ),
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
                  child: Icon(category.icon, color: Colors.white, size: 20),
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
                                child: Icon(
                                  icon,
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : Colors.grey.shade600,
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
      // Pastel colors
      const Color.fromARGB(255, 134, 243, 135), // Soft Green
      const Color.fromARGB(255, 248, 111, 182), // Light Pink
      const Color.fromARGB(255, 123, 204, 232), // Sky Blue
      const Color.fromARGB(255, 243, 239, 117), // Light Yellow
      const Color.fromARGB(255, 179, 2, 255), // Lavender
      const Color.fromARGB(255, 255, 182, 46), // Peach
      const Color.fromARGB(255, 155, 255, 88), // Mint Green
      const Color.fromARGB(255, 255, 28, 232), // Orchid
      const Color.fromARGB(255, 52, 140, 255), // Powder Blue
      const Color.fromARGB(255, 244, 226, 64), // Khaki (lighter)
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
