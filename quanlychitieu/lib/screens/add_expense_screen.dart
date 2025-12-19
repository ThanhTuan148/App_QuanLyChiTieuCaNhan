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
import '../models/expense.dart';
import '../models/category.dart' as app_category;
import '../providers/expense_provider.dart';
import '../providers/category_provider.dart';
import '../providers/auth_provider.dart';

class AddExpenseScreen extends StatefulWidget {
  /// Chi tiêu cần chỉnh sửa (null nếu là thêm mới)
  final Expense? expense;

  const AddExpenseScreen({super.key, this.expense});

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
    } else {
      // Khởi tạo giá trị mặc định cho chi tiêu mới
      _amountController = TextEditingController();
      _descriptionController = TextEditingController();
      _selectedDate = DateTime.now();
      _selectedCategoryId = null;
      _isIncome = false;
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
    final List<app_category.Category> categories = categoryProvider.categories;

    // Tự động chọn danh mục đầu tiên nếu chưa có danh mục nào được chọn
    if (_selectedCategoryId == null && categories.isNotEmpty) {
      _selectedCategoryId = categories.first.id;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Sửa Ghi Chép' : 'Thêm Ghi Chép'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveExpense),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Switch chuyển đổi giữa chi tiêu và thu nhập
                SwitchListTile(
                  title: Text(_isIncome ? 'Thu nhập' : 'Chi tiêu'),
                  value: _isIncome,
                  onChanged: (value) => setState(() => _isIncome = value),
                  secondary: Icon(
                    _isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                  ),
                ),
                const SizedBox(height: 16),

                // Trường nhập số tiền
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Số tiền',
                    prefixIcon: Icon(Icons.monetization_on_outlined),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
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
                const SizedBox(height: 16),

                // Trường nhập mô tả
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? 'Vui lòng nhập mô tả'
                              : null,
                ),
                const SizedBox(height: 24),

                // Dropdown chọn danh mục
                if (categories.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: _selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Danh mục',
                      prefixIcon: Icon(Icons.category_outlined),
                      border: OutlineInputBorder(),
                    ),
                    items:
                        categories.map((category) {
                          return DropdownMenuItem<String>(
                            value: category.id,
                            child: Row(
                              children: [
                                Icon(category.icon, color: category.color),
                                const SizedBox(width: 8),
                                Text(category.name),
                              ],
                            ),
                          );
                        }).toList(),
                    onChanged:
                        (value) => setState(() => _selectedCategoryId = value),
                    validator:
                        (value) =>
                            value == null ? 'Vui lòng chọn danh mục' : null,
                  )
                else
                  const Center(
                    child: Text(
                      'Vui lòng tạo danh mục trong phần Cài đặt trước.',
                    ),
                  ),
                const SizedBox(height: 24),

                // Hiển thị và chọn ngày
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Ngày: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: const Text('Chọn ngày'),
                      onPressed: _presentDatePicker,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
