/// Màn hình Dòng Tiền cho Doanh nghiệp
/// Hiển thị dự báo dòng tiền, cảnh báo, và phân tích
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../providers/group_provider.dart';
import '../services/cash_flow_service.dart';
import '../models/group.dart';

class CashFlowScreen extends StatefulWidget {
  final Group group;

  const CashFlowScreen({super.key, required this.group});

  @override
  State<CashFlowScreen> createState() => _CashFlowScreenState();
}

class _CashFlowScreenState extends State<CashFlowScreen> {
  final CashFlowService _cashFlowService = CashFlowService();
  CashFlowForecast? _forecast;
  double _currentBalance = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadForecast();
  }

  Future<void> _loadForecast() async {
    setState(() => _isLoading = true);

    final expenseProvider = context.read<ExpenseProvider>();
    final groupExpenses = expenseProvider.expenses
        .where((e) => e.groupId == widget.group.id && e.isApproved != false)
        .toList();

    // Tính số dư hiện tại (tạm thời, nên lưu trong group)
    final totalIncome = groupExpenses
        .where((e) => e.isIncome)
        .fold(0.0, (sum, e) => sum + e.amount);
    final totalExpense = groupExpenses
        .where((e) => !e.isIncome)
        .fold(0.0, (sum, e) => sum + e.amount);
    _currentBalance = totalIncome - totalExpense;

    final forecast = _cashFlowService.forecastCashFlow(
      groupExpenses: groupExpenses,
      currentBalance: _currentBalance,
      months: 3,
    );

    setState(() {
      _forecast = forecast;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dòng Tiền'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadForecast,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _forecast == null
              ? const Center(child: Text('Không có dữ liệu'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Current balance
                      _buildBalanceCard(_currentBalance),
                      const SizedBox(height: 16),

                      // Warnings
                      if (_forecast!.warnings.isNotEmpty) ...[
                        _buildWarningsCard(_forecast!.warnings),
                        const SizedBox(height: 16),
                      ],

                      // Forecast chart
                      _buildForecastChart(_forecast!),
                      const SizedBox(height: 16),

                      // Monthly forecasts
                      _buildMonthlyForecasts(_forecast!.monthlyForecasts),
                    ],
                  ),
                ),
    );
  }

  Widget _buildBalanceCard(double balance) {
    final color = balance >= 0 ? Colors.green : Colors.red;
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Số dư hiện tại',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              _formatCurrency(balance),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (balance < 0)
              const Text(
                '⚠️ Số dư âm - Cần tăng thu nhập hoặc giảm chi tiêu',
                style: TextStyle(fontSize: 12, color: Colors.red),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningsCard(List<String> warnings) {
    return Card(
      color: Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.orange[700]),
                const SizedBox(width: 8),
                const Text(
                  'Cảnh báo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...warnings.map((warning) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('• $warning'),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastChart(CashFlowForecast forecast) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dự báo Dòng Tiền 3 Tháng',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < forecast.monthlyForecasts.length) {
                            final month = forecast.monthlyForecasts[value.toInt()].month;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                DateFormat('MM/yyyy').format(month),
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
                            '${(value / 1000000).toStringAsFixed(1)}M',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: forecast.monthlyForecasts.asMap().entries.map((entry) {
                        final index = entry.key;
                        final forecast = entry.value;
                        return FlSpot(
                          index.toDouble(),
                          forecast.predictedBalance / 1000000,
                        );
                      }).toList(),
                      isCurved: true,
                      color: Colors.blue,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(show: false),
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

  Widget _buildMonthlyForecasts(List<MonthlyForecast> forecasts) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chi tiết Dự báo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...forecasts.map((forecast) => _buildForecastItem(forecast)),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastItem(MonthlyForecast forecast) {
    final isNegative = forecast.predictedBalance < 0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isNegative ? Colors.red[50] : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  DateFormat('MM/yyyy').format(forecast.month),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getConfidenceColor(forecast.confidence),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(forecast.confidence * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildForecastMetric(
                    'Thu nhập',
                    forecast.predictedIncome,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildForecastMetric(
                    'Chi tiêu',
                    forecast.predictedExpense,
                    Colors.red,
                  ),
                ),
              ],
            ),
            const Divider(),
            Row(
              children: [
                const Text('Số dư dự báo: '),
                Text(
                  _formatCurrency(forecast.predictedBalance),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isNegative ? Colors.red : Colors.green,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastMetric(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        Text(
          _formatCurrency(value),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence > 0.7) return Colors.green;
    if (confidence > 0.4) return Colors.orange;
    return Colors.red;
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###');
    return '${formatter.format(amount)} VND';
  }
}

