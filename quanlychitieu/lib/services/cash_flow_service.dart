/// Service quản lý Dòng Tiền cho Doanh nghiệp
/// Học từ cách Vingroup, Viettel quản lý dòng tiền để ứng phó rủi ro
import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../models/group.dart';

/// Dự báo dòng tiền
class CashFlowForecast {
  final double currentBalance;
  final List<MonthlyForecast> monthlyForecasts;
  final double riskLevel; // 0-1
  final List<String> warnings;

  CashFlowForecast({
    required this.currentBalance,
    required this.monthlyForecasts,
    required this.riskLevel,
    required this.warnings,
  });
}

/// Dự báo hàng tháng
class MonthlyForecast {
  final DateTime month;
  final double predictedIncome;
  final double predictedExpense;
  final double predictedBalance;
  final double confidence; // Độ tin cậy (0-1)

  MonthlyForecast({
    required this.month,
    required this.predictedIncome,
    required this.predictedExpense,
    required this.predictedBalance,
    required this.confidence,
  });
}

/// Service quản lý dòng tiền doanh nghiệp
class CashFlowService {
  /// Tính toán dự báo dòng tiền cho nhóm
  /// 
  /// Parameters:
  /// - groupExpenses: Danh sách giao dịch của nhóm
  /// - currentBalance: Số dư hiện tại
  /// - months: Số tháng cần dự báo (mặc định 3)
  /// 
  /// Returns:
  /// - CashFlowForecast với dự báo và cảnh báo
  CashFlowForecast forecastCashFlow({
    required List<Expense> groupExpenses,
    required double currentBalance,
    int months = 3,
  }) {
    // Phân tích lịch sử
    final monthlyData = _groupByMonth(groupExpenses);
    final incomeTrend = _calculateIncomeTrend(monthlyData);
    final expenseTrend = _calculateExpenseTrend(monthlyData);

    // Dự báo cho các tháng tiếp theo
    final forecasts = <MonthlyForecast>[];
    var runningBalance = currentBalance;

    for (int i = 1; i <= months; i++) {
      final forecastMonth = DateTime.now().add(Duration(days: 30 * i));
      final predictedIncome = _predictValue(incomeTrend, i);
      final predictedExpense = _predictValue(expenseTrend, i);
      final predictedBalance = runningBalance + predictedIncome - predictedExpense;

      forecasts.add(
        MonthlyForecast(
          month: forecastMonth,
          predictedIncome: predictedIncome,
          predictedExpense: predictedExpense,
          predictedBalance: predictedBalance,
          confidence: _calculateConfidence(monthlyData.length, i),
        ),
      );

      runningBalance = predictedBalance;
    }

    // Tính mức độ rủi ro
    final riskLevel = _calculateRiskLevel(forecasts, currentBalance);

    // Tạo cảnh báo
    final warnings = _generateWarnings(forecasts, riskLevel);

    return CashFlowForecast(
      currentBalance: currentBalance,
      monthlyForecasts: forecasts,
      riskLevel: riskLevel,
      warnings: warnings,
    );
  }

  /// Nhóm giao dịch theo tháng
  Map<DateTime, Map<String, double>> _groupByMonth(List<Expense> expenses) {
    final monthly = <DateTime, Map<String, double>>{};
    
    for (final expense in expenses) {
      final monthKey = DateTime(expense.date.year, expense.date.month, 1);
      monthly.putIfAbsent(monthKey, () => {'income': 0.0, 'expense': 0.0});
      
      if (expense.isIncome) {
        monthly[monthKey]!['income'] = monthly[monthKey]!['income']! + expense.amount;
      } else {
        monthly[monthKey]!['expense'] = monthly[monthKey]!['expense']! + expense.amount;
      }
    }
    
    return monthly;
  }

  /// Tính xu hướng thu nhập
  List<double> _calculateIncomeTrend(Map<DateTime, Map<String, double>> monthlyData) {
    return monthlyData.values.map((v) => v['income'] ?? 0.0).toList();
  }

  /// Tính xu hướng chi tiêu
  List<double> _calculateExpenseTrend(Map<DateTime, Map<String, double>> monthlyData) {
    return monthlyData.values.map((v) => v['expense'] ?? 0.0).toList();
  }

  /// Dự đoán giá trị dựa trên xu hướng
  double _predictValue(List<double> trend, int monthsAhead) {
    if (trend.isEmpty) return 0.0;
    if (trend.length == 1) return trend[0];

    // Tính trung bình có trọng số (tháng gần nhất quan trọng hơn)
    final weights = List.generate(trend.length, (i) => (i + 1).toDouble());
    final totalWeight = weights.fold(0.0, (a, b) => a + b);
    
    var weightedSum = 0.0;
    for (int i = 0; i < trend.length; i++) {
      weightedSum += trend[i] * weights[i];
    }

    final baseValue = weightedSum / totalWeight;

    // Tính xu hướng tăng/giảm
    if (trend.length >= 2) {
      final recentChange = trend.last - trend[trend.length - 2];
      return baseValue + (recentChange * monthsAhead * 0.5); // Giảm ảnh hưởng theo thời gian
    }

    return baseValue;
  }

  /// Tính độ tin cậy của dự báo
  double _calculateConfidence(int dataPoints, int monthsAhead) {
    if (dataPoints == 0) return 0.0;
    
    // Càng nhiều dữ liệu và càng gần hiện tại thì càng tin cậy
    final dataConfidence = (dataPoints / 12).clamp(0.0, 1.0); // Tối đa 1 năm dữ liệu
    final timeConfidence = (1.0 - (monthsAhead / 12)).clamp(0.0, 1.0);
    
    return (dataConfidence + timeConfidence) / 2;
  }

  /// Tính mức độ rủi ro
  double _calculateRiskLevel(List<MonthlyForecast> forecasts, double currentBalance) {
    if (forecasts.isEmpty) return 0.0;

    // Kiểm tra số tháng có số dư âm
    final negativeMonths = forecasts.where((f) => f.predictedBalance < 0).length;
    final riskFromNegative = (negativeMonths / forecasts.length).clamp(0.0, 1.0);

    // Kiểm tra số dư giảm mạnh
    final minBalance = forecasts.map((f) => f.predictedBalance).reduce((a, b) => a < b ? a : b);
    final riskFromLowBalance = minBalance < currentBalance * 0.3 ? 0.8 : 0.0;

    return (riskFromNegative * 0.6 + riskFromLowBalance * 0.4).clamp(0.0, 1.0);
  }

  /// Tạo cảnh báo
  List<String> _generateWarnings(List<MonthlyForecast> forecasts, double riskLevel) {
    final warnings = <String>[];

    if (riskLevel > 0.7) {
      warnings.add('🔴 CẢNH BÁO: Dòng tiền có nguy cơ thiếu hụt nghiêm trọng');
    } else if (riskLevel > 0.4) {
      warnings.add('🟡 Lưu ý: Cần theo dõi chặt chẽ dòng tiền');
    }

    final negativeMonths = forecasts.where((f) => f.predictedBalance < 0).toList();
    if (negativeMonths.isNotEmpty) {
      warnings.add(
        '⚠️ Dự báo ${negativeMonths.length} tháng có số dư âm. Cần tăng thu nhập hoặc giảm chi tiêu',
      );
    }

    // Cảnh báo nếu chi tiêu tăng mạnh
    if (forecasts.length >= 2) {
      final expenseGrowth = forecasts.last.predictedExpense - forecasts.first.predictedExpense;
      if (expenseGrowth > forecasts.first.predictedExpense * 0.2) {
        warnings.add('📈 Chi tiêu dự báo tăng ${(expenseGrowth / forecasts.first.predictedExpense * 100).toStringAsFixed(1)}%. Nên kiểm soát chi phí');
      }
    }

    return warnings;
  }

  /// Phân tích chi phí theo bộ phận/dự án
  Map<String, double> analyzeByDepartment({
    required List<Expense> expenses,
    String? projectId,
  }) {
    final filtered = projectId != null
        ? expenses.where((e) => e.projectId == projectId)
        : expenses;

    // Nhóm theo category (có thể mở rộng để nhóm theo department)
    final byCategory = <String, double>{};
    for (final expense in filtered.where((e) => !e.isIncome)) {
      byCategory[expense.categoryId] =
          (byCategory[expense.categoryId] ?? 0) + expense.amount;
    }

    return byCategory;
  }

  /// So sánh chi phí giữa các kỳ (học từ báo cáo doanh nghiệp)
  Map<String, dynamic> comparePeriods({
    required List<Expense> currentPeriod,
    required List<Expense> previousPeriod,
  }) {
    final currentTotal = currentPeriod
        .where((e) => !e.isIncome)
        .fold(0.0, (sum, e) => sum + e.amount);
    final previousTotal = previousPeriod
        .where((e) => !e.isIncome)
        .fold(0.0, (sum, e) => sum + e.amount);

    final change = currentTotal - previousTotal;
    final changePercent = previousTotal > 0
        ? (change / previousTotal * 100)
        : 0.0;

    return {
      'currentTotal': currentTotal,
      'previousTotal': previousTotal,
      'change': change,
      'changePercent': changePercent,
      'trend': change > 0 ? 'tăng' : 'giảm',
      'isOverBudget': false, // Sẽ tính khi có budget
    };
  }
}

