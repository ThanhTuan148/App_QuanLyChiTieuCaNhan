/// Card so sánh chi tiêu tháng này với tháng trước
/// Hiển thị phần trăm tăng/giảm với icon và màu sắc tương ứng

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MonthComparisonCard extends StatelessWidget {
  final double currentMonthExpense;
  final double lastMonthExpense;
  final String currencySymbol;
  
  const MonthComparisonCard({
    super.key,
    required this.currentMonthExpense,
    required this.lastMonthExpense,
    this.currencySymbol = 'VND',
  });

  @override
  Widget build(BuildContext context) {
    final change = currentMonthExpense - lastMonthExpense;
    final changePercent = lastMonthExpense > 0 
      ? (change / lastMonthExpense * 100).abs()
      : 0.0;
    final isIncrease = change > 0;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tháng này',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatCurrency(currentMonthExpense),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isIncrease 
                  ? Colors.red.withOpacity(0.1)
                  : Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isIncrease ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                    color: isIncrease ? Colors.red : Colors.green,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${changePercent.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: isIncrease ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      symbol: currencySymbol == 'VND' ? '' : currencySymbol,
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }
}

