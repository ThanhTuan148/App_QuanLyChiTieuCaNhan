// [ĐÃ SỬA LỖI] lib/screens/budget_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/budget_provider.dart';
import '../providers/category_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/currency_provider.dart';
import '../models/budget.dart';
import '../models/category.dart' as app_category;
import '../providers/date_range_provider.dart'; // [SỬA LỖI 1] Thêm import
import '../models/date_range.dart'; // Thêm import này để truy cập thuộc tính của DateRange
import '../utils/category_emoji_mapper.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});
  @override
  // [SỬA LỖI 3] Đổi tên lớp State thành public
  BudgetScreenState createState() => BudgetScreenState();
}

// [SỬA LỖI 3] Đổi tên lớp State thành public
class BudgetScreenState extends State<BudgetScreen> {

  @override
  Widget build(BuildContext context) {
    final budgetProvider = context.watch<BudgetProvider>();
    final categoryProvider = context.watch<CategoryProvider>();
    final expenseProvider = context.watch<ExpenseProvider>();
    final currencyFormat = context.watch<CurrencyProvider>().currencyFormat;

    return Scaffold(
      // Bỏ AppBar ở đây vì nó đã có ở màn hình cha (HomeScreen)
      body:
          categoryProvider.categories.isEmpty
              ? const Center(
                child: Text('Vui lòng tạo danh mục trong phần Cài đặt trước.'),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: categoryProvider.categories.length,
                itemBuilder: (ctx, index) {
                  final category = categoryProvider.categories[index];
                  if (category.id == null) {
                    return const SizedBox.shrink(); // Bỏ qua category không hợp lệ
                  }

                  final budget = budgetProvider.getBudgetForCategory(
                    category.id!,
                  );
                  final totalSpent = expenseProvider.getTotalExpensesByCategory(
                    category.id!,
                  );

                  return _buildBudgetCard(
                    context,
                    category,
                    budget,
                    totalSpent,
                    currencyFormat,
                  );
                },
              ),
    );
  }

  Widget _buildBudgetCard(
    BuildContext context,
    app_category.Category category,
    Budget? budget,
    double totalSpent,
    NumberFormat currencyFormat,
  ) {
    final double budgetAmount = budget?.amount ?? 0;
    final double remaining = budgetAmount - totalSpent;
    final double progress =
        budgetAmount > 0 ? (totalSpent / budgetAmount).clamp(0, 1) : 0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: category.color,
                  child: Text(
                    CategoryEmojiMapper.getEmojiForIcon(category.icon),
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    category.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.grey),
                  onPressed: () => _showBudgetDialog(context, category, budget),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Đã chi: ${currencyFormat.format(totalSpent)}'),
                Text('Ngân sách: ${currencyFormat.format(budgetAmount)}'),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 1.0
                    ? Colors.red.shade700
                    : (progress > 0.8
                        ? Colors.orange.shade700
                        : Colors.green.shade600),
              ),
            ),
            const SizedBox(height: 4),
            // [SỬA LỖI 2] Sử dụng biến `remaining`
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Còn lại: ${currencyFormat.format(remaining)}',
                style: TextStyle(
                  color: remaining >= 0 ? Colors.blueGrey : Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBudgetDialog(
    BuildContext context,
    app_category.Category category,
    Budget? budget,
  ) {
    final amountController = TextEditingController(
      text: budget?.amount.toStringAsFixed(0) ?? '',
    );
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('Đặt ngân sách cho "${category.name}"'),
            content: TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Số tiền',
                prefixText: '₫ ',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () {
                  final amount = double.tryParse(amountController.text) ?? 0.0;
                  final authProvider = context.read<AuthProvider>();
                  final dateProvider = context.read<DateRangeProvider>();
                  if (authProvider.currentUser != null && category.id != null) {
                    final currentRange = dateProvider.currentRange;
                    final newBudget = Budget(
                      id: budget?.id,
                      amount: amount,
                      categoryId: category.id!,
                      // Sửa lỗi truy cập thuộc tính của DateRange
                      month: currentRange.startDate.month,
                      year: currentRange.startDate.year,
                      userId: authProvider.currentUser!.id,
                    );
                    context.read<BudgetProvider>().saveBudget(newBudget);
                  }
                  Navigator.of(ctx).pop();
                },
                child: const Text('Lưu'),
              ),
            ],
          ),
    );
  }
}
