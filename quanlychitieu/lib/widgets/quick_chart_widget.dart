/// Biểu đồ nhanh hiển thị chi tiêu 7 ngày gần nhất
/// Giúp người dùng nhanh chóng nắm bắt xu hướng chi tiêu

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';

class QuickChartWidget extends StatelessWidget {
  final List<Expense> expenses;
  
  const QuickChartWidget({
    super.key,
    required this.expenses,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final sevenDaysData = List.generate(7, (index) {
      final date = now.subtract(Duration(days: 6 - index));
      final dayExpenses = expenses.where((e) => 
        e.date.year == date.year &&
        e.date.month == date.month &&
        e.date.day == date.day &&
        !e.isIncome
      ).toList();
      return dayExpenses.fold<double>(0, (sum, e) => sum + e.amount);
    });
    
    final maxExpense = sevenDaysData.isEmpty 
      ? 1.0 
      : sevenDaysData.reduce((a, b) => a > b ? a : b);
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chi tiêu 7 ngày qua',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (index) {
                final height = maxExpense > 0 
                  ? (sevenDaysData[index] / maxExpense * 100)
                  : 0.0;
                final date = now.subtract(Duration(days: 6 - index));
                final colorScheme = Theme.of(context).colorScheme;
                
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.6),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(8),
                              ),
                            ),
                            height: height,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat('E', 'vi').format(date).substring(0, 1),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

