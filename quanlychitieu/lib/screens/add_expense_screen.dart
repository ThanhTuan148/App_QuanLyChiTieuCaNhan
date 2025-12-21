/// Màn hình thêm/sửa chi tiêu
/// Cho phép người dùng:
/// - Thêm mới hoặc chỉnh sửa chi tiêu/thu nhập
/// - Nhập số tiền và mô tả
/// - Chọn danh mục chi tiêu
/// - Chọn ngày giao dịch
/// - Chuyển đổi giữa chi tiêu và thu nhập
// [GỠ LỖI] lib/screens/add_expense_screen.dart

// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense.dart';
import '../models/category.dart' as app_category;
import '../providers/expense_provider.dart';
import '../providers/category_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/group_provider.dart';
import '../providers/currency_provider.dart';
import '../services/momo_service.dart';
import '../services/zalopay_service.dart';
import '../utils/category_emoji_mapper.dart';
import '../widgets/category_icon_button.dart';

class AddExpenseScreen extends StatefulWidget {
  /// Chi tiêu cần chỉnh sửa (null nếu là thêm mới)
  final Expense? expense;
  
  /// ID nhóm được chọn trước (tùy chọn)
  final String? preSelectedGroupId;
  
  /// ID dự án được chọn trước (tùy chọn)
  final String? preSelectedProjectId;

  const AddExpenseScreen({
    super.key, 
    this.expense,
    this.preSelectedGroupId,
    this.preSelectedProjectId,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  /// Key để quản lý form
  final _formKey = GlobalKey<FormState>();

  /// Controller cho các trường nhập liệu
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;

  /// Ngày được chọn cho giao dịch
  late DateTime _selectedDate;

  /// ID của danh mục được chọn
  String? _selectedCategoryId;

  /// Trạng thái là thu nhập hay chi tiêu
  late bool _isIncome;

  /// ID nhóm được chọn (null nếu là giao dịch cá nhân)
  String? _selectedGroupId;

  /// ID dự án được chọn (null nếu không thuộc dự án)
  String? _selectedProjectId;

  /// Yêu cầu phê duyệt (chỉ áp dụng cho giao dịch nhóm)
  bool _requiresApproval = false;

  /// Kiểm tra xem có đang ở chế độ chỉnh sửa không
  bool get _isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();

    if (_isEditing) {
      // Khởi tạo dữ liệu từ chi tiêu cần chỉnh sửa
      final expense = widget.expense!;
      _amountController = TextEditingController(
        text: expense.amount.toString(),
      );
      _descriptionController = TextEditingController(text: expense.description);
      _selectedDate = expense.date;
      _selectedCategoryId = expense.categoryId;
      _isIncome = expense.isIncome;
      _selectedGroupId = expense.groupId;
      _selectedProjectId = expense.projectId;
      _requiresApproval = expense.groupId != null && expense.isApproved == null;
    } else {
      // Khởi tạo giá trị mặc định cho chi tiêu mới
      _amountController = TextEditingController();
      _descriptionController = TextEditingController();
      _selectedDate = DateTime.now();
      _selectedCategoryId = null;
      _isIncome = false;
      // Nếu có preSelectedGroupId, sử dụng nó
      _selectedGroupId = widget.preSelectedGroupId;
      _selectedProjectId = widget.preSelectedProjectId;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Hiển thị dialog chọn ngày
  Future<void> _presentDatePicker() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  /// Lưu chi tiêu vào cơ sở dữ liệu
  Future<void> _saveExpense() async {
    // Kiểm tra tính hợp lệ của form
    if (!_formKey.currentState!.validate()) {
      print("GỠ LỖI: Form không hợp lệ.");
      return;
    }
    // Kiểm tra đã chọn danh mục chưa
    if (_selectedCategoryId == null) {
      print("GỠ LỖI: Chưa chọn category.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn một danh mục')),
      );
      return;
    }
    _formKey.currentState!.save();

    // Kiểm tra đăng nhập
    final authProvider = context.read<AuthProvider>();
    if (authProvider.currentUser == null) {
      print("GỠ LỖI: Lỗi nghiêm trọng - currentUser là null khi lưu!");
      return;
    }

    // Lấy dữ liệu từ form
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final description = _descriptionController.text;
    final currentUserId = authProvider.currentUser!.id;

    // Log thông tin để debug
    print("GỠ LỖI: Chuẩn bị lưu chi tiêu:");
    print("  - User ID: $currentUserId");
    print("  - Amount: $amount");
    print("  - Description: $description");
    print("  - Category ID: $_selectedCategoryId");

    // Tạo đối tượng chi tiêu mới
    final newExpense = Expense(
      id: widget.expense?.id,
      amount: amount,
      description: description,
      date: _selectedDate,
      categoryId: _selectedCategoryId!,
      isIncome: _isIncome,
      userId: currentUserId,
      groupId: _selectedGroupId,
      projectId: _selectedProjectId,
      isApproved: _selectedGroupId != null && !_requiresApproval ? true : null,
    );

    final expenseProvider = context.read<ExpenseProvider>();

    try {
      // Lưu chi tiêu
      print("GỠ LỖI: Đang gọi hàm của ExpenseProvider...");
      if (_isEditing) {
        await expenseProvider.updateExpense(newExpense);
      } else {
        await expenseProvider.addExpense(newExpense);
      }
      print("GỠ LỖI: Gọi hàm thành công!");

      // Nếu là giao dịch nhóm và cần phê duyệt, tạo approval request
      if (_selectedGroupId != null && _requiresApproval && newExpense.id != null) {
        try {
          await _createApprovalRequest(newExpense.id!);
        } catch (e) {
          print("Lỗi khi tạo approval request: $e");
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      print("GỠ LỖI: Có lỗi xảy ra khi lưu: ${e.toString()}");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lưu thất bại: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();
    final currencyProvider = context.watch<CurrencyProvider>();
    final List<app_category.Category> categories = categoryProvider.categories;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormat = currencyProvider.currencyFormat;

    // Tự động chọn danh mục đầu tiên nếu chưa có danh mục nào được chọn
    if (_selectedCategoryId == null && categories.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _selectedCategoryId = categories.first.id);
      });
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1B241D) : const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Form(
          key: _formKey,
            child: Column(
              children: [
              // Header
              _buildHeader(context),
              // Main content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      // Expense/Income Toggle
                      _buildTypeToggle(context),
                      const SizedBox(height: 32),
                      // Amount Input
                      _buildAmountInput(context, currencyFormat),
                      const SizedBox(height: 32),
                      // Category Selection
                      _buildCategorySection(context, categories),
                      const SizedBox(height: 24),
                      // Description
                      _buildDescriptionField(context),
                      const SizedBox(height: 16),
                      // Date and Time
                      _buildDateTimeFields(context),
                      const SizedBox(height: 16),
                      // Wallet (optional)
                      _buildWalletField(context),
                      const SizedBox(height: 16),
                      // Add Receipt
                      _buildReceiptField(context),
                      const SizedBox(height: 16),
                      // Section chọn nhóm/dự án (chỉ hiển thị khi có nhóm)
                      _buildGroupSection(context),
                      const SizedBox(height: 16),
                      // Section thanh toán qua ví điện tử (chỉ hiển thị khi là chi tiêu)
                      if (!_isIncome && !_isEditing) _buildPaymentSection(context),
                      const SizedBox(height: 100), // Space for bottom button
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // Bottom Save Button
      bottomNavigationBar: _buildBottomSaveButton(context),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B241D) : const Color(0xFFF9FAFB),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.grey[900]),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              _isEditing ? 'Sửa Giao dịch' : 'Giao dịch mới',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey[900],
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.more_horiz, color: isDark ? Colors.white : Colors.grey[900]),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildTypeToggle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF253028) : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isIncome = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !_isIncome
                      ? (isDark ? Theme.of(context).primaryColor : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: !_isIncome
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    'Chi tiêu',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: !_isIncome ? FontWeight.bold : FontWeight.w500,
                      color: !_isIncome
                          ? (isDark ? Colors.white : Theme.of(context).primaryColor)
                          : (isDark ? Colors.grey[400] : Colors.grey[600]),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isIncome = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _isIncome
                      ? (isDark ? Theme.of(context).primaryColor : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _isIncome
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    'Thu nhập',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: _isIncome ? FontWeight.bold : FontWeight.w500,
                      color: _isIncome
                          ? (isDark ? Colors.white : Theme.of(context).primaryColor)
                          : (isDark ? Colors.grey[400] : Colors.grey[600]),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInput(BuildContext context, NumberFormat currencyFormat) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(
          'Số tiền?',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '₫',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: TextFormField(
                controller: _amountController,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.grey[900],
                ),
                textAlign: TextAlign.center,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: '0.00',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.grey[600] : Colors.grey[300],
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập số tiền';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Vui lòng nhập một số hợp lệ';
                    }
                    if (double.parse(value) <= 0) {
                      return 'Số tiền phải lớn hơn 0';
                    }
                    return null;
                  },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategorySection(BuildContext context, List<app_category.Category> categories) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoryProvider = context.read<CategoryProvider>();
    
    // Hiển thị tất cả categories hoặc ít nhất 8 categories đầu tiên
    final displayCategories = categories.take(8).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Danh mục',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey[900],
              ),
            ),
            if (categories.length > 8)
              TextButton(
                onPressed: () => _showAllCategoriesDialog(context, categories, categoryProvider),
                child: Text(
                  'Xem tất cả',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: displayCategories.length + 1, // +1 for Add button
          itemBuilder: (context, index) {
            if (index == displayCategories.length) {
              // Add button
              return CategoryIconButton(
                emoji: '+',
                label: 'Thêm',
                isSelected: false,
                onTap: () => _showAddCategoryDialog(context, categoryProvider),
                backgroundColor: isDark ? Colors.grey[800] : Colors.grey[100],
              );
            }
            
            final category = displayCategories[index];
            final isSelected = _selectedCategoryId == category.id;
            final emoji = CategoryEmojiMapper.getEmojiForIcon(category.icon);
            
            return CategoryIconButton(
              emoji: emoji,
              label: category.name,
              isSelected: isSelected,
              onTap: () {
                setState(() => _selectedCategoryId = category.id);
              },
              backgroundColor: category.color.withOpacity(0.1),
            );
          },
        ),
      ],
    );
  }

  void _showAllCategoriesDialog(BuildContext context, List<app_category.Category> categories, CategoryProvider categoryProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chọn danh mục'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: categories.length + 1,
            itemBuilder: (context, index) {
              if (index == categories.length) {
                return CategoryIconButton(
                  emoji: '+',
                  label: 'Thêm',
                  isSelected: false,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _showAddCategoryDialog(context, categoryProvider);
                  },
                  backgroundColor: isDark ? Colors.grey[800] : Colors.grey[100],
                );
              }
              
              final category = categories[index];
              final isSelected = _selectedCategoryId == category.id;
              final emoji = CategoryEmojiMapper.getEmojiForIcon(category.icon);
              
              return CategoryIconButton(
                emoji: emoji,
                label: category.name,
                isSelected: isSelected,
                onTap: () {
                  setState(() => _selectedCategoryId = category.id);
                  Navigator.of(ctx).pop();
                },
                backgroundColor: category.color.withOpacity(0.1),
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
    );
  }

  void _showAddCategoryDialog(BuildContext context, CategoryProvider categoryProvider) {
    final nameController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color selectedColor = Theme.of(context).primaryColor;
    IconData selectedIcon = Icons.category;
    
    final List<Color> colors = [
      Colors.red, Colors.pink, Colors.purple, Colors.deepPurple,
      Colors.indigo, Colors.blue, Colors.lightBlue, Colors.cyan,
      Colors.teal, Colors.green, Colors.lightGreen, Colors.lime,
      Colors.amber, Colors.orange, Colors.deepOrange, Colors.brown,
    ];
    
    final List<IconData> icons = [
      Icons.restaurant, Icons.shopping_cart, Icons.directions_car,
      Icons.movie, Icons.receipt, Icons.home, Icons.flight,
      Icons.school, Icons.medical_services, Icons.fitness_center,
      Icons.card_giftcard, Icons.attach_money, Icons.emoji_events,
      Icons.sports_esports, Icons.devices, Icons.pets,
    ];
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateInDialog) => AlertDialog(
          title: const Text('Thêm Danh mục'),
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
                  const Text('Chọn màu', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: colors.length,
                      itemBuilder: (context, index) {
                        final color = colors[index];
                        return GestureDetector(
                          onTap: () => setStateInDialog(() => selectedColor = color),
                          child: Container(
                            width: 40,
                            height: 40,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selectedColor == color ? Colors.black : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Chọn biểu tượng', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: icons.length,
                    itemBuilder: (context, index) {
                      final icon = icons[index];
                      return GestureDetector(
                        onTap: () => setStateInDialog(() => selectedIcon = icon),
                        child: Container(
                          decoration: BoxDecoration(
                            color: selectedIcon == icon
                                ? selectedColor.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selectedIcon == icon ? selectedColor : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              CategoryEmojiMapper.getEmojiForIcon(icon),
                              style: TextStyle(
                                fontSize: 20,
                                color: selectedIcon == icon ? selectedColor : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  final authProvider = context.read<AuthProvider>();
                  if (authProvider.currentUser != null) {
                    final newCategory = app_category.Category(
                      name: nameController.text.trim(),
                      icon: selectedIcon,
                      color: selectedColor,
                      userId: authProvider.currentUser!.id,
                    );
                    categoryProvider.addCategory(newCategory);
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã thêm danh mục')),
                    );
                  }
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionField(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF253028) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.description,
              color: Theme.of(context).primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextFormField(
                  controller: _descriptionController,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.grey[900],
              ),
              decoration: InputDecoration(
                hintText: 'Bạn đã mua gì?',
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Vui lòng nhập mô tả' : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeFields(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Expanded(
          child: _buildDateTimeField(
            context,
            Icons.calendar_today,
            'Ngày',
            DateFormat('dd/MM/yyyy').format(_selectedDate),
            _presentDatePicker,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildDateTimeField(
            context,
            Icons.schedule,
            'Giờ',
            DateFormat('HH:mm').format(_selectedDate),
            () async {
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(_selectedDate),
              );
              if (time != null) {
                setState(() {
                  _selectedDate = DateTime(
                    _selectedDate.year,
                    _selectedDate.month,
                    _selectedDate.day,
                    time.hour,
                    time.minute,
                  );
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeField(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    VoidCallback onTap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = icon == Icons.calendar_today
        ? Colors.blue
        : Colors.purple;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF253028) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
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
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.grey[900],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletField(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF253028) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.yellow.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_balance_wallet,
              color: Colors.yellow[700],
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ví',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ví chính',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.grey[900],
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.expand_more,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptField(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        // TODO: Implement receipt picker
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF253028) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
            width: 2,
            style: BorderStyle.solid,
          ),
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
            Icon(
              Icons.add_a_photo,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'Thêm hóa đơn',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSaveButton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF253028).withOpacity(0.9) : Colors.white.withOpacity(0.9),
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[100]!,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _saveExpense,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check, size: 20),
              const SizedBox(width: 8),
              Text(
                'Lưu giao dịch',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupSection(BuildContext context) {
    return Consumer<GroupProvider>(
      builder: (context, groupProvider, child) {
        if (groupProvider.groups.isEmpty) return const SizedBox.shrink();

        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Giao dịch nhóm (tùy chọn)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey[900],
              ),
            ),
            const SizedBox(height: 12),
            // Dropdown chọn nhóm
            DropdownButtonFormField<String>(
              value: _selectedGroupId,
              decoration: InputDecoration(
                labelText: 'Chọn nhóm',
                prefixIcon: const Icon(Icons.group),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF253028) : Colors.grey[50],
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Giao dịch cá nhân'),
                ),
                ...groupProvider.groups.map((group) {
                  return DropdownMenuItem<String>(
                    value: group.id,
                    child: Text(group.name),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedGroupId = value;
                  _selectedProjectId = null; // Reset project khi đổi group
                });
              },
            ),
            const SizedBox(height: 12),
            // Dropdown chọn dự án (nếu đã chọn nhóm)
            if (_selectedGroupId != null)
              DropdownButtonFormField<String>(
                value: _selectedProjectId,
                decoration: InputDecoration(
                  labelText: 'Chọn dự án (tùy chọn)',
                  prefixIcon: const Icon(Icons.folder),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF253028) : Colors.grey[50],
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Không thuộc dự án'),
                  ),
                  ...groupProvider.projects
                      .where((p) => p.groupId == _selectedGroupId)
                      .map((project) {
                    return DropdownMenuItem<String>(
                      value: project.id,
                      child: Text(project.name),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() => _selectedProjectId = value);
                },
              ),
            const SizedBox(height: 12),
            // Checkbox yêu cầu phê duyệt
            if (_selectedGroupId != null && !_isIncome)
              CheckboxListTile(
                title: const Text('Yêu cầu phê duyệt'),
                subtitle: const Text(
                  'Giao dịch sẽ cần được admin phê duyệt trước khi được ghi nhận',
                  style: TextStyle(fontSize: 12),
                ),
                value: _requiresApproval,
                onChanged: (value) {
                  setState(() => _requiresApproval = value ?? false);
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildPaymentSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thanh toán qua ví điện tử',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.grey[900],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.account_balance_wallet),
                label: const Text('MoMo'),
                onPressed: _payWithMoMo,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.payment),
                label: const Text('ZaloPay'),
                onPressed: _payWithZaloPay,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Thanh toán qua ví điện tử sẽ tự động tạo giao dịch',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  /// Thanh toán qua MoMo
  Future<void> _payWithMoMo() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số tiền hợp lệ')),
      );
      return;
    }

    final momoService = MoMoService();
    final orderId = 'MOMO_${DateTime.now().millisecondsSinceEpoch}';
    final description = _descriptionController.text.isEmpty
        ? 'Thanh toán chi tiêu'
        : _descriptionController.text;

    final success = await momoService.initiatePayment(
      amount: amount,
      orderId: orderId,
      description: description,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đang mở ứng dụng MoMo...'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Thanh toán qua ZaloPay
  Future<void> _payWithZaloPay() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số tiền hợp lệ')),
      );
      return;
    }

    final zalopayService = ZaloPayService();
    final orderId = 'ZALOPAY_${DateTime.now().millisecondsSinceEpoch}';
    final description = _descriptionController.text.isEmpty
        ? 'Thanh toán chi tiêu'
        : _descriptionController.text;

    final zpToken = await zalopayService.initiatePayment(
      amount: amount,
      orderId: orderId,
      description: description,
    );

    if (zpToken != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đang mở ứng dụng ZaloPay...'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Tạo approval request cho giao dịch nhóm
  Future<void> _createApprovalRequest(String expenseId) async {
    if (_selectedGroupId == null) return;

    try {
      // Sử dụng Firestore trực tiếp để tạo approval request
      // (có thể thêm method vào GroupProvider sau)
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('approval_requests').add({
        'expenseId': expenseId,
        'groupId': _selectedGroupId,
        'requestedBy': context.read<AuthProvider>().currentUser?.id,
        'status': 'pending',
        'requestedAt': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('Lỗi khi tạo approval request: $e');
    }
  }
}
