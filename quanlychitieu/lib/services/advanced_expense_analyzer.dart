/// Service phân tích chi tiêu nâng cao
/// Dựa trên kinh nghiệm từ các doanh nghiệp lớn VN (Vingroup, Viettel, FPT)
/// Tập trung vào dự đoán, tối ưu dòng tiền, và gợi ý tiết kiệm
import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../models/date_range.dart';
import 'expense_predictor_service.dart';

/// Kết quả phân tích chi tiêu
class ExpenseAnalysis {
  final double predictedMonthlyExpense;
  final double averageMonthlyExpense;
  final double savingsPotential; // Tiềm năng tiết kiệm
  final List<SavingsSuggestion> suggestions;
  final Map<String, double> categoryTrends; // Xu hướng theo danh mục
  final double riskLevel; // Mức độ rủi ro (0-1)
  final String summary;

  ExpenseAnalysis({
    required this.predictedMonthlyExpense,
    required this.averageMonthlyExpense,
    required this.savingsPotential,
    required this.suggestions,
    required this.categoryTrends,
    required this.riskLevel,
    required this.summary,
  });
}

/// Gợi ý tiết kiệm
class SavingsSuggestion {
  final String category;
  final double currentSpending;
  final double suggestedSpending;
  final double potentialSavings;
  final String reason;
  final String action;

  SavingsSuggestion({
    required this.category,
    required this.currentSpending,
    required this.suggestedSpending,
    required this.potentialSavings,
    required this.reason,
    required this.action,
  });
}

/// Service phân tích chi tiêu nâng cao
class AdvancedExpenseAnalyzer {
  final ExpensePredictorService _predictor = ExpensePredictorService();

  /// Phân tích chi tiêu và đưa ra dự đoán, gợi ý
  /// 
  /// Parameters:
  /// - expenses: Danh sách chi tiêu lịch sử
  /// - monthlyIncome: Thu nhập hàng tháng (để tính tỷ lệ)
  /// 
  /// Returns:
  /// - ExpenseAnalysis với dự đoán và gợi ý
  Future<ExpenseAnalysis> analyzeExpenses({
    required List<Expense> expenses,
    double? monthlyIncome,
  }) async {
    // Lọc chỉ chi tiêu (không phải thu nhập)
    final expenseList = expenses.where((e) => !e.isIncome).toList();
    
    if (expenseList.isEmpty) {
      return ExpenseAnalysis(
        predictedMonthlyExpense: 0,
        averageMonthlyExpense: 0,
        savingsPotential: 0,
        suggestions: [],
        categoryTrends: {},
        riskLevel: 0,
        summary: 'Chưa có dữ liệu chi tiêu để phân tích',
      );
    }

    // Tính toán cơ bản
    final monthlyExpenses = _groupByMonth(expenseList);
    final averageMonthly = _calculateAverage(monthlyExpenses);
    
    // Dự đoán tháng tiếp theo
    final monthlyList = monthlyExpenses.entries.toList();
    final last3Months = monthlyList.length >= 3
        ? monthlyList.sublist(monthlyList.length - 3)
        : monthlyList;
    final predicted = await _predictNextMonth(
      last3Months.map((e) => MapEntry(e.key, e.value)).toList(),
    );

    // Phân tích theo danh mục
    final categoryTrends = _analyzeCategoryTrends(expenseList);

    // Tính mức độ rủi ro (dựa trên tỷ lệ chi tiêu/thu nhập)
    double riskLevel = 0.0;
    if (monthlyIncome != null && monthlyIncome > 0) {
      final expenseRatio = predicted / monthlyIncome;
      if (expenseRatio > 0.9) {
        riskLevel = 1.0; // Rất cao
      } else if (expenseRatio > 0.7) {
        riskLevel = 0.7; // Cao
      } else if (expenseRatio > 0.5) {
        riskLevel = 0.4; // Trung bình
      } else {
        riskLevel = 0.1; // Thấp
      }
    }

    // Tạo gợi ý tiết kiệm
    final suggestions = _generateSavingsSuggestions(
      categoryTrends,
      monthlyIncome ?? predicted * 1.5,
    );

    // Tính tiềm năng tiết kiệm
    final savingsPotential = suggestions.fold(
      0.0,
      (sum, s) => sum + s.potentialSavings,
    );

    // Tạo summary
    final summary = _generateSummary(
      predicted,
      averageMonthly,
      riskLevel,
      monthlyIncome,
    );

    return ExpenseAnalysis(
      predictedMonthlyExpense: predicted,
      averageMonthlyExpense: averageMonthly,
      savingsPotential: savingsPotential,
      suggestions: suggestions,
      categoryTrends: categoryTrends,
      riskLevel: riskLevel,
      summary: summary,
    );
  }

  /// Nhóm chi tiêu theo tháng
  Map<DateTime, double> _groupByMonth(List<Expense> expenses) {
    final monthly = <DateTime, double>{};
    for (final expense in expenses) {
      final monthKey = DateTime(expense.date.year, expense.date.month, 1);
      monthly[monthKey] = (monthly[monthKey] ?? 0) + expense.amount;
    }
    return monthly;
  }

  /// Tính trung bình chi tiêu hàng tháng
  double _calculateAverage(Map<DateTime, double> monthlyExpenses) {
    if (monthlyExpenses.isEmpty) return 0.0;
    final total = monthlyExpenses.values.fold(0.0, (a, b) => a + b);
    return total / monthlyExpenses.length;
  }

  /// Dự đoán chi tiêu tháng tiếp theo
  Future<double> _predictNextMonth(List<MapEntry<DateTime, double>> lastMonths) async {
    if (lastMonths.isEmpty) return 0.0;
    
    // Sử dụng predictor nếu có model (chỉ trên mobile, không hoạt động trên web)
    final amounts = lastMonths.map((e) => e.value).toList();
    final prediction = await _predictor.predictNextExpense(
      pastExpenses: amounts,
      sequenceLength: amounts.length,
    );

    if (prediction != null && prediction > 0) {
      return prediction;
    }

    // Fallback: Tính trung bình có trọng số (tháng gần nhất quan trọng hơn)
    if (amounts.length == 1) return amounts[0];
    if (amounts.length == 2) return (amounts[0] + amounts[1] * 1.2) / 2.2;
    
    // Trung bình có trọng số cho 3 tháng
    return (amounts[0] * 0.2 + amounts[1] * 0.3 + amounts[2] * 0.5);
  }

  /// Phân tích xu hướng theo danh mục
  Map<String, double> _analyzeCategoryTrends(List<Expense> expenses) {
    final categoryTotals = <String, double>{};
    for (final expense in expenses) {
      categoryTotals[expense.categoryId] =
          (categoryTotals[expense.categoryId] ?? 0) + expense.amount;
    }
    return categoryTotals;
  }

  /// Tạo gợi ý tiết kiệm
  List<SavingsSuggestion> _generateSavingsSuggestions(
    Map<String, double> categoryTrends,
    double monthlyIncome,
  ) {
    final suggestions = <SavingsSuggestion>[];
    final totalExpense = categoryTrends.values.fold(0.0, (a, b) => a + b);
    
    // Tìm các danh mục chi tiêu nhiều nhất
    final sortedCategories = categoryTrends.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in sortedCategories.take(3)) {
      final categorySpending = entry.value;
      final percentage = (categorySpending / totalExpense * 100);
      
      // Nếu chi tiêu > 30% tổng chi tiêu, đề xuất giảm 20%
      if (percentage > 30) {
        final suggestedReduction = categorySpending * 0.2;
        suggestions.add(
          SavingsSuggestion(
            category: entry.key,
            currentSpending: categorySpending,
            suggestedSpending: categorySpending - suggestedReduction,
            potentialSavings: suggestedReduction,
            reason: 'Chi tiêu cho danh mục này chiếm ${percentage.toStringAsFixed(1)}% tổng chi tiêu',
            action: 'Giảm 20% chi tiêu cho danh mục này để tối ưu dòng tiền',
          ),
        );
      }
    }

    // Gợi ý tổng thể nếu chi tiêu > 80% thu nhập
    if (totalExpense > monthlyIncome * 0.8) {
      final targetSavings = monthlyIncome * 0.2; // Mục tiêu tiết kiệm 20%
      final currentSavings = monthlyIncome - totalExpense;
      final neededReduction = targetSavings - currentSavings;
      
      if (neededReduction > 0) {
        suggestions.add(
          SavingsSuggestion(
            category: 'Tổng thể',
            currentSpending: totalExpense,
            suggestedSpending: totalExpense - neededReduction,
            potentialSavings: neededReduction,
            reason: 'Chi tiêu hiện tại chiếm ${(totalExpense / monthlyIncome * 100).toStringAsFixed(1)}% thu nhập. Nên tiết kiệm ít nhất 20%',
            action: 'Giảm chi tiêu ${(neededReduction / monthlyIncome * 100).toStringAsFixed(1)}% để đạt mục tiêu tiết kiệm',
          ),
        );
      }
    }

    return suggestions;
  }

  /// Tạo summary text
  String _generateSummary(
    double predicted,
    double average,
    double riskLevel,
    double? monthlyIncome,
  ) {
    final buffer = StringBuffer();
    
    buffer.writeln('Dự đoán chi tiêu tháng tới: ${_formatCurrency(predicted)} VND');
    buffer.writeln('Trung bình chi tiêu: ${_formatCurrency(average)} VND');
    
    if (monthlyIncome != null) {
      final ratio = (predicted / monthlyIncome * 100);
      buffer.writeln('Tỷ lệ chi tiêu/thu nhập: ${ratio.toStringAsFixed(1)}%');
      
      if (ratio > 90) {
        buffer.writeln('⚠️ Cảnh báo: Chi tiêu quá cao, có nguy cơ thiếu tiền mặt');
      } else if (ratio > 70) {
        buffer.writeln('⚠️ Lưu ý: Nên giảm chi tiêu để tăng tiết kiệm');
      } else if (ratio < 50) {
        buffer.writeln('✅ Tốt: Tỷ lệ chi tiêu hợp lý, có thể tăng tiết kiệm');
      }
    }

    if (riskLevel > 0.7) {
      buffer.writeln('🔴 Mức độ rủi ro: CAO - Cần giảm chi tiêu ngay');
    } else if (riskLevel > 0.4) {
      buffer.writeln('🟡 Mức độ rủi ro: TRUNG BÌNH - Nên theo dõi chặt chẽ');
    } else {
      buffer.writeln('🟢 Mức độ rủi ro: THẤP - Dòng tiền ổn định');
    }

    return buffer.toString();
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }

  /// Phân tích so sánh giữa các kỳ (học từ báo cáo doanh nghiệp)
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
    };
  }
}

