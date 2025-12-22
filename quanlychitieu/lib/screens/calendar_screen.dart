/// Màn hình lịch hiển thị calendar view với thông tin tài chính
/// Cho phép người dùng xem giao dịch theo ngày và tháng

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../providers/currency_provider.dart';
import '../models/expense.dart';
import 'add_expense_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _currentMonth = DateTime.now();
  String _selectedFilter = 'Chi phí'; // Chi phí, Thu nhập, Toàn bộ
  String _viewMode = 'Month'; // Month hoặc Week

  @override
  Widget build(BuildContext context) {
    final expenseProvider = context.watch<ExpenseProvider>();
    final currencyProvider = context.watch<CurrencyProvider>();
    final currencyFormat = currencyProvider.currencyFormat;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Lấy tất cả expenses trong tháng hiện tại
    final monthExpenses = expenseProvider.expenses.where((e) =>
      e.date.year == _currentMonth.year &&
      e.date.month == _currentMonth.month
    ).toList();

    // Tính toán theo filter
    double totalAll = 0;
    double totalIncome = 0;
    double totalExpense = 0;

    for (var expense in monthExpenses) {
      if (expense.isIncome) {
        totalIncome += expense.amount;
      } else {
        totalExpense += expense.amount;
      }
    }
    totalAll = totalIncome - totalExpense;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B140E) : const Color(0xFFF4F9F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),
            // Calendar Card
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Calendar Card
                      _buildCalendarCard(
                        context,
                        _currentMonth,
                        _selectedDate,
                        monthExpenses,
                        (date) {
                          setState(() => _selectedDate = date);
                        },
                        (month) {
                          setState(() => _currentMonth = month);
                        },
                      ),
                      const SizedBox(height: 16),
                      // Filter Buttons
                      _buildFilterButtons(context),
                      const SizedBox(height: 16),
                      // Financial Summary
                      _buildFinancialSummary(
                        context,
                        currencyFormat,
                        totalAll,
                        totalIncome,
                        totalExpense,
                      ),
                    ],
                  ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16261B) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
            color: isDark ? Colors.white : Colors.grey[900],
          ),
          Expanded(
            child: Text(
              'Lịch',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey[900],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48), // Balance space
        ],
      ),
    );
  }

  Widget _buildCalendarCard(
    BuildContext context,
    DateTime currentMonth,
    DateTime selectedDate,
    List<Expense> monthExpenses,
    Function(DateTime) onDateSelected,
    Function(DateTime) onMonthChanged,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    
    // Tính số ngày trong tháng
    final firstDay = DateTime(currentMonth.year, currentMonth.month, 1);
    final lastDay = DateTime(currentMonth.year, currentMonth.month + 1, 0);
    final daysInMonth = lastDay.day;
    final firstWeekday = firstDay.weekday % 7; // 0 = Sunday, 6 = Saturday

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16261B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Month Navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    onMonthChanged(DateTime(currentMonth.year, currentMonth.month - 1));
                  },
                  color: colorScheme.primary,
                ),
                Row(
                  children: [
                    Text(
                      'tháng ${currentMonth.month} năm ${currentMonth.year}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.grey[900],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _viewMode = _viewMode == 'Month' ? 'Week' : 'Month';
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _viewMode,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    onMonthChanged(DateTime(currentMonth.year, currentMonth.month + 1));
                  },
                  color: colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Days of week
            Row(
              children: ['CN', 'Th 2', 'Th 3', 'Th 4', 'Th 5', 'Th 6', 'Th 7']
                .map((day) => Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: (day == 'CN' || day == 'Th 7')
                          ? Colors.red
                          : (isDark ? Colors.grey[400] : Colors.grey[600]),
                      ),
                    ),
                  ),
                ))
                .toList(),
            ),
            const SizedBox(height: 8),
            // Calendar Grid - Scrollable to show all days
            LayoutBuilder(
              builder: (context, constraints) {
                // Tính số hàng cần thiết (tối đa 6 hàng cho 42 ô)
                final rowsNeeded = ((daysInMonth + firstWeekday) / 7).ceil();
                // Chiều rộng mỗi ô
                final cellWidth = (constraints.maxWidth - 14) / 7; // Trừ padding và spacing
                // Chiều cao mỗi ô với tỷ lệ nhỏ gọn
                final cellHeight = cellWidth * 0.8;
                // Tổng chiều cao cần thiết
                final totalHeight = (rowsNeeded * cellHeight) + ((rowsNeeded - 1) * 2);
                
                return SizedBox(
                  height: 220, // ✅ Chiều cao cố định, phần còn lại sẽ scroll
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(), // ✅ Cho phép scroll mượt mà
                    child: SizedBox(
                      height: totalHeight, // ✅ Chiều cao thực tế của lịch
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(), // Không scroll trong GridView
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          childAspectRatio: 0.8, // ✅ Tỷ lệ nhỏ gọn
                          crossAxisSpacing: 2,
                          mainAxisSpacing: 2,
                        ),
                        itemCount: 42, // 6 weeks * 7 days = 42 cells (đủ cho 31 ngày + ngày đầu tháng)
                itemBuilder: (context, index) {
                  final dayIndex = index - firstWeekday;
                  if (dayIndex < 1 || dayIndex > daysInMonth) {
                    return const SizedBox(); // Empty cell
                  }

                  final date = DateTime(currentMonth.year, currentMonth.month, dayIndex);
                  final isSelected = date.year == selectedDate.year &&
                      date.month == selectedDate.month &&
                      date.day == selectedDate.day;
                  final isToday = date.year == DateTime.now().year &&
                      date.month == DateTime.now().month &&
                      date.day == DateTime.now().day;

                  // Lấy expenses của ngày này
                  final dayExpenses = monthExpenses.where((e) =>
                    e.date.year == date.year &&
                    e.date.month == date.month &&
                    e.date.day == date.day
                  ).toList();

                  // Tính toán theo filter
                  double dayAmount = 0;
                  Color amountColor = Colors.transparent;
                  
                  if (dayExpenses.isNotEmpty) {
                    if (_selectedFilter == 'Chi phí') {
                      dayAmount = dayExpenses
                          .where((e) => !e.isIncome)
                          .fold(0.0, (sum, e) => sum + e.amount);
                      amountColor = Colors.red;
                    } else if (_selectedFilter == 'Thu nhập') {
                      dayAmount = dayExpenses
                          .where((e) => e.isIncome)
                          .fold(0.0, (sum, e) => sum + e.amount);
                      amountColor = Colors.green;
                    } else { // Toàn bộ
                      final income = dayExpenses
                          .where((e) => e.isIncome)
                          .fold(0.0, (sum, e) => sum + e.amount);
                      final expense = dayExpenses
                          .where((e) => !e.isIncome)
                          .fold(0.0, (sum, e) => sum + e.amount);
                      dayAmount = income - expense;
                      amountColor = dayAmount >= 0 ? Colors.green : Colors.red;
                    }
                  }

                  return GestureDetector(
                    onTap: () {
                      onDateSelected(date);
                      if (dayExpenses.isNotEmpty) {
                        _showDateDetails(context, date, dayExpenses);
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.all(0.5), // ✅ Giảm margin
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primary
                            : (isToday
                                ? colorScheme.primary.withOpacity(0.1)
                                : Colors.transparent),
                        shape: BoxShape.circle,
                        border: isToday && !isSelected
                            ? Border.all(color: colorScheme.primary, width: 1)
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$dayIndex',
                            style: TextStyle(
                              fontSize: 11, // ✅ Giảm font size
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected
                                  ? Colors.white
                                  : ((date.weekday == 7 || date.weekday == 6)
                                      ? Colors.red
                                      : (isDark ? Colors.white : Colors.grey[900])),
                            ),
                          ),
                          if (dayAmount > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 1),
                              child: Text(
                                '${dayAmount >= 0 ? '+' : ''}${_formatAmount(dayAmount)}',
                                style: TextStyle(
                                  fontSize: 7, // ✅ Giảm font size cho số tiền
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : amountColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
                        ),
                      ),
                    ),
                  );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButtons(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: _buildFilterButton(
            context,
            'Chi phí',
            _selectedFilter == 'Chi phí',
            colorScheme.primary.withOpacity(0.1),
            () => setState(() => _selectedFilter = 'Chi phí'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildFilterButton(
            context,
            'Thu nhập',
            _selectedFilter == 'Thu nhập',
            Colors.grey.withOpacity(0.1),
            () => setState(() => _selectedFilter = 'Thu nhập'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildFilterButton(
            context,
            'Toàn bộ',
            _selectedFilter == 'Toàn bộ',
            Colors.grey.withOpacity(0.1),
            () => setState(() => _selectedFilter = 'Toàn bộ'),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterButton(
    BuildContext context,
    String label,
    bool isSelected,
    Color backgroundColor,
    VoidCallback onTap,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary.withOpacity(0.2) : backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: colorScheme.primary, width: 2)
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? colorScheme.primary
                  : (isDark ? Colors.white : Colors.grey[900]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFinancialSummary(
    BuildContext context,
    NumberFormat currencyFormat,
    double totalAll,
    double totalIncome,
    double totalExpense,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16261B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            context,
            'Toàn bộ',
            totalAll,
            totalAll >= 0 ? Colors.green : Colors.red,
            currencyFormat,
          ),
          _buildSummaryItem(
            context,
            'Thu nhập',
            totalIncome,
            Colors.green,
            currencyFormat,
          ),
          _buildSummaryItem(
            context,
            'Chi tiêu',
            totalExpense,
            Colors.red,
            currencyFormat,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    double amount,
    Color color,
    NumberFormat currencyFormat,
  ) {
    return Column(
      children: [
        Text(
          currencyFormat.format(amount),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[400]
                : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }

  void _showDateDetails(BuildContext context, DateTime date, List<Expense> expenses) {
    final currencyProvider = Provider.of<CurrencyProvider>(context, listen: false);
    final currencyFormat = currencyProvider.currencyFormat;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF16261B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('dd/MM/yyyy').format(date),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.grey[900],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Flexible(
              child: expenses.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'Không có giao dịch trong ngày này',
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: expenses.length,
                      itemBuilder: (context, index) {
                        final expense = expenses[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: expense.isIncome
                                ? Colors.green.withOpacity(0.2)
                                : Colors.red.withOpacity(0.2),
                            child: Icon(
                              expense.isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                              color: expense.isIncome ? Colors.green : Colors.red,
                            ),
                          ),
                          title: Text(expense.description),
                          subtitle: Text(DateFormat('HH:mm').format(expense.date)),
                          trailing: Text(
                            '${expense.isIncome ? '+' : '-'}${currencyFormat.format(expense.amount)}',
                            style: TextStyle(
                              color: expense.isIncome ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (ctx) => AddExpenseScreen(expense: expense),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

