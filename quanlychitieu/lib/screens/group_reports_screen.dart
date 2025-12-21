/// Màn hình báo cáo nhóm với biểu đồ và xuất PDF
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../providers/group_provider.dart';
import '../providers/category_provider.dart';
import '../models/group.dart';
import '../models/expense.dart';

class GroupReportsScreen extends StatelessWidget {
  final Group group;

  const GroupReportsScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo nhóm'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () {
              // TODO: Export PDF
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng xuất PDF đang phát triển')),
              );
            },
            tooltip: 'Xuất PDF',
          ),
        ],
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, expenseProvider, child) {
          final groupExpenses = expenseProvider.expenses
              .where((e) => e.groupId == group.id && e.isApproved != false)
              .toList();

          if (groupExpenses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart_outlined,
                      size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có giao dịch nào',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          final totalExpense = groupExpenses
              .where((e) => !e.isIncome)
              .fold(0.0, (sum, e) => sum + e.amount);
          final totalIncome = groupExpenses
              .where((e) => e.isIncome)
              .fold(0.0, (sum, e) => sum + e.amount);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tổng quan
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildSummaryRow(
                          'Tổng thu nhập',
                          totalIncome,
                          Colors.green,
                          Icons.arrow_downward,
                        ),
                        const Divider(),
                        _buildSummaryRow(
                          'Tổng chi tiêu',
                          totalExpense,
                          Colors.red,
                          Icons.arrow_upward,
                        ),
                        const Divider(),
                        _buildSummaryRow(
                          'Số dư',
                          totalIncome - totalExpense,
                          totalIncome - totalExpense >= 0
                              ? Colors.blue
                              : Colors.orange,
                          Icons.account_balance,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Biểu đồ cột
                const Text(
                  'Chi tiêu theo tháng',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      height: 200,
                      child: _buildMonthlyChart(groupExpenses),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Biểu đồ tròn theo danh mục
                const Text(
                  'Chi tiêu theo danh mục',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      height: 200,
                      child: _buildCategoryChart(context, groupExpenses),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, Color color, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 12),
        Expanded(child: Text(label)),
        Text(
          _formatCurrency(amount),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyChart(List<Expense> expenses) {
    // Nhóm theo tháng
    final monthlyData = <String, double>{};
    for (final expense in expenses.where((e) => !e.isIncome)) {
      final monthKey = DateFormat('MM/yyyy').format(expense.date);
      monthlyData[monthKey] = (monthlyData[monthKey] ?? 0) + expense.amount;
    }

    if (monthlyData.isEmpty) {
      return const Center(child: Text('Không có dữ liệu'));
    }

    final sortedMonths = monthlyData.keys.toList()..sort();
    final maxAmount = monthlyData.values.reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxAmount * 1.2,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < sortedMonths.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      sortedMonths[value.toInt()],
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  _formatCurrency(value),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(show: true),
        borderData: FlBorderData(show: true),
        barGroups: sortedMonths.asMap().entries.map((entry) {
          final index = entry.key;
          final month = entry.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: monthlyData[month]!,
                color: Colors.blue,
                width: 16,
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryChart(BuildContext context, List<Expense> expenses) {
    final categoryProvider = context.read<CategoryProvider>();
    final categoryData = <String, double>{};

    for (final expense in expenses.where((e) => !e.isIncome)) {
      final category = categoryProvider.findById(expense.categoryId);
      final categoryName = category != null ? category.name : 'Khác';
      categoryData[categoryName] =
          (categoryData[categoryName] ?? 0) + expense.amount;
    }

    if (categoryData.isEmpty) {
      return const Center(child: Text('Không có dữ liệu'));
    }

    final total = categoryData.values.fold(0.0, (a, b) => a + b);
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];

    return PieChart(
      PieChartData(
        sections: categoryData.entries.toList().asMap().entries.map((entry) {
          final index = entry.key;
          final category = entry.value;
          return PieChartSectionData(
            value: category.value,
            title: '${(category.value / total * 100).toStringAsFixed(1)}%',
            color: colors[index % colors.length],
            radius: 80,
          );
        }).toList(),
        sectionsSpace: 2,
      ),
    );
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###');
    return formatter.format(amount);
  }
}

