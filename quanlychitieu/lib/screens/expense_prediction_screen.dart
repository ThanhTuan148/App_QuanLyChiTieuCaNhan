/// Màn hình Dự báo Chi tiêu nâng cao
/// Hiển thị dự đoán, gợi ý tiết kiệm, và phân tích xu hướng
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../providers/auth_provider.dart';
import '../services/advanced_expense_analyzer.dart';
import '../models/date_range.dart';

class ExpensePredictionScreen extends StatefulWidget {
  const ExpensePredictionScreen({super.key});

  @override
  State<ExpensePredictionScreen> createState() => _ExpensePredictionScreenState();
}

class _ExpensePredictionScreenState extends State<ExpensePredictionScreen> {
  final AdvancedExpenseAnalyzer _analyzer = AdvancedExpenseAnalyzer();
  ExpenseAnalysis? _analysis;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalysis();
  }

  Future<void> _loadAnalysis() async {
    setState(() => _isLoading = true);

    final expenseProvider = context.read<ExpenseProvider>();
    final expenses = expenseProvider.expenses;
    
    // Lấy thu nhập trung bình hàng tháng
    final monthlyIncome = _calculateAverageMonthlyIncome(expenses);

    final analysis = await _analyzer.analyzeExpenses(
      expenses: expenses,
      monthlyIncome: monthlyIncome,
    );

    setState(() {
      _analysis = analysis;
      _isLoading = false;
    });
  }

  double _calculateAverageMonthlyIncome(List expenses) {
    final incomeList = expenses.where((e) => e.isIncome).toList();
    if (incomeList.isEmpty) return 0.0;

    // Nhóm theo tháng
    final monthlyIncome = <DateTime, double>{};
    for (final income in incomeList) {
      final monthKey = DateTime(income.date.year, income.date.month, 1);
      monthlyIncome[monthKey] = (monthlyIncome[monthKey] ?? 0) + income.amount;
    }

    if (monthlyIncome.isEmpty) return 0.0;
    final total = monthlyIncome.values.fold(0.0, (a, b) => a + b);
    return total / monthlyIncome.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dự Báo Chi Tiêu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalysis,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _analysis == null
              ? const Center(child: Text('Không có dữ liệu để phân tích'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary card
                      _buildSummaryCard(_analysis!),
                      const SizedBox(height: 16),

                      // Prediction chart
                      _buildPredictionChart(_analysis!),
                      const SizedBox(height: 16),

                      // Savings suggestions
                      _buildSavingsSuggestions(_analysis!.suggestions),
                      const SizedBox(height: 16),

                      // Category trends
                      _buildCategoryTrends(_analysis!.categoryTrends),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSummaryCard(ExpenseAnalysis analysis) {
    final riskColor = analysis.riskLevel > 0.7
        ? Colors.red
        : analysis.riskLevel > 0.4
            ? Colors.orange
            : Colors.green;

    return Card(
      color: riskColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  analysis.riskLevel > 0.7
                      ? Icons.warning
                      : analysis.riskLevel > 0.4
                          ? Icons.info
                          : Icons.check_circle,
                  color: riskColor,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Tóm tắt Phân tích',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              analysis.summary,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Dự đoán tháng tới',
                    _formatCurrency(analysis.predictedMonthlyExpense),
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricCard(
                    'Tiềm năng tiết kiệm',
                    _formatCurrency(analysis.savingsPotential),
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionChart(ExpenseAnalysis analysis) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dự đoán Chi tiêu',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(show: true),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        FlSpot(0, analysis.averageMonthlyExpense / 1000000),
                        FlSpot(1, analysis.predictedMonthlyExpense / 1000000),
                      ],
                      isCurved: true,
                      color: Colors.blue,
                      dotData: FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLegendItem('Trung bình', Colors.grey),
                _buildLegendItem('Dự đoán', Colors.blue),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavingsSuggestions(List<SavingsSuggestion> suggestions) {
    if (suggestions.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 48),
              const SizedBox(height: 8),
              const Text(
                'Chi tiêu của bạn đã tối ưu!',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gợi ý Tiết Kiệm',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...suggestions.map((suggestion) => _buildSuggestionCard(suggestion)),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionCard(SavingsSuggestion suggestion) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.green[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    suggestion.category,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[900],
                    ),
                  ),
                ),
                Text(
                  'Tiết kiệm: ${_formatCurrency(suggestion.potentialSavings)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              suggestion.reason,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              '💡 ${suggestion.action}',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.green[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTrends(Map<String, double> trends) {
    if (trends.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Xu hướng theo Danh mục',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...trends.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(entry.key),
                    ),
                    Text(
                      _formatCurrency(entry.value),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: _getDarkerColor(color),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###');
    return '${formatter.format(amount)} VND';
  }

  /// Tạo màu tối hơn từ color hiện tại
  Color _getDarkerColor(Color color) {
    if (color is MaterialColor) {
      return color.shade700;
    }
    // Tạo màu tối hơn bằng cách giảm độ sáng
    return Color.fromRGBO(
      (color.red * 0.7).round().clamp(0, 255),
      (color.green * 0.7).round().clamp(0, 255),
      (color.blue * 0.7).round().clamp(0, 255),
      color.opacity,
    );
  }
}

