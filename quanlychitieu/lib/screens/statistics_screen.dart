/// Màn hình hiển thị thống kê chi tiêu
/// Bao gồm:
/// - Tổng quan thu chi
/// - Biểu đồ phân bổ chi tiêu theo danh mục
/// - Chi tiết chi tiêu theo từng danh mục
/// - Nút chuyển đến màn hình thống kê chi tiết
// screens/statistics_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/expense_provider.dart';
import '../providers/category_provider.dart';
import '../models/category.dart' as app_models;
import '../providers/date_range_provider.dart';
import '../models/date_range.dart';
import '../widgets/date_range_selector.dart';
import 'detailed_statistics_screen.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _StatisticsScreenState createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  /// Định dạng tiền tệ theo định dạng Việt Nam
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  @override
  Widget build(BuildContext context) {
    // Lấy các provider cần thiết
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final dateRangeProvider = Provider.of<DateRangeProvider>(context);
    final currentRange = dateRangeProvider.currentRange;

    // Tính tổng thu nhập và chi tiêu trong khoảng thời gian
    final totalIncome = expenseProvider.getTotalIncomeByDateRange(currentRange);
    final totalExpense = expenseProvider.getTotalExpensesByDateRange(
      currentRange,
    );

    // Lấy chi tiêu theo danh mục và khoảng thời gian
    final expensesByCategory = expenseProvider
        .getExpensesByCategoryAndDateRange(currentRange);

    // Tính tỉ lệ phần trăm cho biểu đồ tròn
    final List<PieChartSectionData> pieChartSections = [];
    double totalExpenseSum = 0;

    // Tính tổng chi tiêu
    expensesByCategory.forEach((categoryId, amount) {
      totalExpenseSum += amount;
    });

    // Tạo các phần cho biểu đồ tròn
    expensesByCategory.forEach((categoryId, amount) {
      try {
        final category = categoryProvider.findById(categoryId);
        final percentage =
            totalExpenseSum > 0 ? (amount / totalExpenseSum) * 100 : 0;

        pieChartSections.add(
          PieChartSectionData(
            color: category.color,
            value: amount,
            title: percentage >= 5 ? '${percentage.toStringAsFixed(1)}%' : '',
            radius: 100,
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
      } catch (e) {
        // Xử lý trường hợp không tìm thấy danh mục
      }
    });

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tiêu đề và bộ chọn khoảng thời gian
            const Text(
              'Thống kê chi tiêu',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Bộ chọn khoảng thời gian
            const DateRangeSelector(),
            const SizedBox(height: 16),

            // Tổng quan thu chi
            Row(
              children: [
                _buildStatCard(
                  'Thu nhập',
                  totalIncome,
                  Icons.trending_up,
                  Colors.green,
                ),
                const SizedBox(width: 8),
                _buildStatCard(
                  'Chi tiêu',
                  totalExpense,
                  Icons.trending_down,
                  Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Biểu đồ tròn phân bổ chi tiêu
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Phân bổ chi tiêu',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    pieChartSections.isEmpty
                        ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Text(
                              'Chưa có dữ liệu chi tiêu',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                        : SizedBox(
                          height: 300,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 40,
                              sections: pieChartSections,
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Chi tiết theo danh mục
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chi tiết theo danh mục',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    expensesByCategory.isEmpty
                        ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'Chưa có dữ liệu chi tiêu',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                        : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: expensesByCategory.length,
                          itemBuilder: (ctx, i) {
                            final categoryId = expensesByCategory.keys
                                .elementAt(i);
                            final amount = expensesByCategory[categoryId]!;

                            try {
                              final category = categoryProvider.findById(
                                categoryId,
                              );
                              final percentage =
                                  totalExpenseSum > 0
                                      ? (amount / totalExpenseSum) * 100
                                      : 0;

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: category.color,
                                  child: Icon(
                                    category.icon,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(category.name),
                                subtitle: LinearProgressIndicator(
                                  value: percentage / 100,
                                  // ignore: deprecated_member_use
                                  backgroundColor:
                                  // ignore: deprecated_member_use
                                  Colors.grey.withOpacity(0.2),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    category.color,
                                  ),
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      currencyFormat.format(amount),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${percentage.toStringAsFixed(1)}%',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            } catch (e) {
                              return const SizedBox();
                            }
                          },
                        ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Nút chuyển đến màn hình thống kê chi tiết
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => const DetailedStatisticsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.bar_chart),
                label: const Text('Xem thống kê chi tiết'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Xây dựng card hiển thị thống kê
  ///
  /// Parameters:
  /// - title: Tiêu đề của card
  /// - amount: Số tiền cần hiển thị
  /// - icon: Icon hiển thị
  /// - color: Màu sắc của card
  Widget _buildStatCard(
    String title,
    double amount,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color),
                  const SizedBox(width: 8),
                  Text(title, style: TextStyle(color: Colors.grey[600])),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                currencyFormat.format(amount),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
