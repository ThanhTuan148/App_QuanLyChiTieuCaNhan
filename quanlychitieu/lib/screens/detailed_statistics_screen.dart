/// Màn hình thống kê chi tiết
/// Cho phép người dùng:
/// - Xem tổng quan thu chi trong khoảng thời gian
/// - Xem biểu đồ phân bổ chi tiêu theo danh mục
/// - Xem biểu đồ cột so sánh thu chi theo thời gian
/// - Xem chi tiết chi tiêu theo từng danh mục
/// - Xem danh sách các giao dịch thu/chi
// [ĐÃ SỬA LỖI CUỐI CÙNG] lib/screens/detailed_statistics_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/expense_provider.dart';
import '../providers/category_provider.dart';
import '../providers/currency_provider.dart';
import '../models/expense.dart';
import '../providers/date_range_provider.dart';
import '../models/date_range.dart';
import '../widgets/date_range_selector.dart';
import '../utils/category_emoji_mapper.dart';
import 'dart:math' as math;

class DetailedStatisticsScreen extends StatefulWidget {
  const DetailedStatisticsScreen({super.key});

  @override
  State<DetailedStatisticsScreen> createState() =>
      _DetailedStatisticsScreenState();
}

class _DetailedStatisticsScreenState extends State<DetailedStatisticsScreen>
    with SingleTickerProviderStateMixin {
  // Controller cho TabBar
  late TabController _tabController;
  // Loại nhóm dữ liệu cho biểu đồ cột (ngày/tháng)
  String _barChartGroupBy = 'day';

  @override
  void initState() {
    super.initState();
    // Khởi tạo TabController với 3 tab
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Lấy dữ liệu từ các provider
    final expenseProvider = context.watch<ExpenseProvider>();
    final categoryProvider = context.watch<CategoryProvider>();
    final dateRangeProvider = context.watch<DateRangeProvider>();
    final currencyFormat = context.watch<CurrencyProvider>().currencyFormat;
    final currentRange = dateRangeProvider.currentRange;

    // Tính toán các thông số
    final expenses = expenseProvider.getExpensesByDateRange(currentRange);
    final totalIncome = expenseProvider.getTotalIncomeByDateRange(currentRange);
    final totalExpense = expenseProvider.getTotalExpensesByDateRange(
      currentRange,
    );
    final balance = totalIncome - totalExpense;
    final expensesByCategory = expenseProvider
        .getExpensesByCategoryAndDateRange(currentRange);
    final incomeList = expenses.where((e) => e.isIncome).toList();
    final expenseList = expenses.where((e) => !e.isIncome).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê chi tiết'),
        // TabBar cho 3 tab: Tổng quan, Chi tiêu, Thu nhập
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tổng quan'),
            Tab(text: 'Chi tiêu'),
            Tab(text: 'Thu nhập'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Bộ chọn khoảng thời gian
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: DateRangeSelector(),
          ),
          // Card tổng quan thu chi
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      currentRange.displayText,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSummaryItem(
                          context,
                          'Thu nhập',
                          totalIncome,
                          Colors.green,
                        ),
                        _buildSummaryItem(context, 'Chi tiêu', totalExpense, Colors.red),
                        _buildSummaryItem(
                          context,
                          'Cân đối',
                          balance,
                          balance >= 0 ? Colors.blue : Colors.orange,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Nội dung các tab
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab Tổng quan
                SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildPieChart(expensesByCategory, categoryProvider),
                      _buildBarChart(expenses, currentRange),
                      _buildCategoryExpenseList(
                        context,
                        expensesByCategory,
                        categoryProvider,
                      ),
                    ],
                  ),
                ),
                // Tab Chi tiêu
                _buildTransactionList(context, expenseList, categoryProvider),
                // Tab Thu nhập
                _buildTransactionList(context, incomeList, categoryProvider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Xây dựng item hiển thị số tiền trong tổng quan
  Widget _buildSummaryItem(BuildContext context, String title, double amount, Color color) {
    final currencyFormat = context.read<CurrencyProvider>().currencyFormat;
    
    return Column(
      children: [
        Text(title, style: TextStyle(color: color)),
        const SizedBox(height: 4),
        Text(
          currencyFormat.format(amount),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  /// Xây dựng biểu đồ tròn phân bổ chi tiêu theo danh mục
  Widget _buildPieChart(
    Map<String, double> expensesByCategory,
    CategoryProvider categoryProvider,
  ) {
    double totalExpenseSum = expensesByCategory.values.fold(
      0,
      (sum, value) => sum + value,
    );
    if (totalExpenseSum == 0) return const SizedBox.shrink();

    List<PieChartSectionData> sections = [];
    expensesByCategory.forEach((categoryId, amount) {
      final category = categoryProvider.findById(categoryId);
      final percentage = (amount / totalExpenseSum) * 100;
      sections.add(
        PieChartSectionData(
          color: category.color,
          value: amount,
          title: percentage >= 5 ? '${percentage.toStringAsFixed(0)}%' : '',
          radius: 100,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    });

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text(
            'Phân bổ chi tiêu',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: sections,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Xây dựng biểu đồ cột so sánh thu chi theo thời gian
  Widget _buildBarChart(List<Expense> expenses, DateRange dateRange) {
    if (expenses.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Không có dữ liệu cho biểu đồ cột'),
        ),
      );
    }

    // Chuẩn bị dữ liệu cho biểu đồ
    final Map<String, double> incomeData = {};
    final Map<String, double> expenseData = {};
    final DateFormat dateFormat =
        _barChartGroupBy == 'day' ? DateFormat('dd/MM') : DateFormat('MM/yyyy');

    // Nhóm dữ liệu theo thời gian
    for (final expense in expenses) {
      String key = dateFormat.format(expense.date);
      if (expense.isIncome) {
        incomeData[key] = (incomeData[key] ?? 0) + expense.amount;
      } else {
        expenseData[key] = (expenseData[key] ?? 0) + expense.amount;
      }
    }

    // Chuẩn bị dữ liệu cho biểu đồ
    final Set<String> allKeys = {...incomeData.keys, ...expenseData.keys};
    final List<String> sortedKeys = allKeys.toList()..sort();

    double maxValue = 0;
    final List<BarChartGroupData> barGroups =
        sortedKeys.asMap().entries.map((entry) {
          int index = entry.key;
          String key = entry.value;
          final incomeValue = incomeData[key] ?? 0;
          final expenseValue = expenseData[key] ?? 0;
          maxValue = math.max(maxValue, math.max(incomeValue, expenseValue));
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: incomeValue,
                color: Colors.green,
                width: 12,
                borderRadius: BorderRadius.circular(4),
              ),
              BarChartRodData(
                toY: expenseValue,
                color: Colors.red,
                width: 12,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }).toList();

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tiêu đề và bộ chọn loại nhóm dữ liệu
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Thu nhập & Chi tiêu',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                DropdownButton<String>(
                  value: _barChartGroupBy,
                  items: const [
                    DropdownMenuItem(value: 'day', child: Text('Theo ngày')),
                    DropdownMenuItem(value: 'month', child: Text('Theo tháng')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _barChartGroupBy = value);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Biểu đồ cột
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  maxY: maxValue * 1.2,
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget:
                            (value, meta) => Text(
                              sortedKeys[value.toInt()],
                              style: const TextStyle(fontSize: 10),
                            ),
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: barGroups,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Xây dựng danh sách chi tiết chi tiêu theo danh mục
  Widget _buildCategoryExpenseList(
    BuildContext context,
    Map<String, double> expensesByCategory,
    CategoryProvider categoryProvider,
  ) {
    final currencyFormat = context.read<CurrencyProvider>().currencyFormat;
    final sortedEntries =
        expensesByCategory.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    double totalExpenseSum = expensesByCategory.values.fold(
      0,
      (sum, value) => sum + value,
    );
    if (totalExpenseSum == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chi tiết theo danh mục',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Danh sách các danh mục và số tiền tương ứng
          ...sortedEntries.map((entry) {
            final categoryId = entry.key;
            final amount = entry.value;
            final category = categoryProvider.findById(categoryId);
            final percentage = (amount / totalExpenseSum) * 100;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: category.color,
                    child: Text(
                      CategoryEmojiMapper.getEmojiForIcon(category.icon),
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: percentage / 100,
                          color: category.color,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currencyFormat.format(amount),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Xây dựng danh sách các giao dịch
  Widget _buildTransactionList(
    BuildContext context,
    List<Expense> transactions,
    CategoryProvider categoryProvider,
  ) {
    final currencyFormat = context.read<CurrencyProvider>().currencyFormat;
    return transactions.isEmpty
        ? const Center(child: Text('Không có giao dịch nào'))
        : ListView.builder(
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            final category = categoryProvider.findById(transaction.categoryId);
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: category.color,
                  child: Text(
                    CategoryEmojiMapper.getEmojiForIcon(category.icon),
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                title: Text(transaction.description),
                subtitle: Text(
                  DateFormat('dd/MM/yyyy').format(transaction.date),
                ),
                trailing: Text(
                  currencyFormat.format(transaction.amount),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: transaction.isIncome ? Colors.green : Colors.red,
                  ),
                ),
              ),
            );
          },
        );
  }
}
