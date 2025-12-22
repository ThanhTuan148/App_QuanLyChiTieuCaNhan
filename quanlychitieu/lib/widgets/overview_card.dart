/// Card tổng quan hiển thị số dư, thu nhập và chi tiêu
/// Sử dụng gradient và animation để tạo trải nghiệm đẹp mắt

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OverviewCard extends StatelessWidget {
  final double balance;
  final double totalIncome;
  final double totalExpense;
  final String currencySymbol;
  
  const OverviewCard({
    super.key,
    required this.balance,
    required this.totalIncome,
    required this.totalExpense,
    this.currencySymbol = 'VND',
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  colorScheme.primary.withOpacity(0.3),
                  colorScheme.primary.withOpacity(0.1),
                ]
              : [
                  colorScheme.primary.withOpacity(0.2),
                  colorScheme.primary.withOpacity(0.05),
                ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Số dư hiện tại',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatCurrency(balance),
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  context,
                  Icons.arrow_downward_rounded,
                  'Thu nhập',
                  totalIncome,
                  Colors.green,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: colorScheme.onSurface.withOpacity(0.2),
                ),
                _buildStatItem(
                  context,
                  Icons.arrow_upward_rounded,
                  'Chi tiêu',
                  totalExpense,
                  Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String label,
    double amount,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(
          _formatCurrency(amount),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
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

