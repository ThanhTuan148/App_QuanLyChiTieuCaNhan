/// Widget tái sử dụng cho transaction card
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../utils/category_emoji_mapper.dart';
import '../providers/currency_provider.dart';

class TransactionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double amount;
  final bool isIncome;
  final IconData? icon;
  final String? emoji;
  final Color iconColor;
  final Color iconBackgroundColor;
  final VoidCallback? onTap;

  const TransactionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isIncome,
    this.icon,
    this.emoji,
    required this.iconColor,
    required this.iconBackgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormat = context.watch<CurrencyProvider>().currencyFormat;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF25332E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[100]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: emoji != null
                        ? Text(
                            emoji!,
                            style: const TextStyle(fontSize: 24),
                          )
                        : icon != null
                            ? Icon(icon, color: iconColor, size: 24)
                            : Text(
                                CategoryEmojiMapper.getEmojiForIcon(icon ?? Icons.receipt),
                                style: const TextStyle(fontSize: 24),
                              ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.grey[900],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${isIncome ? '+' : '-'}${currencyFormat.format(amount)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isIncome
                        ? Theme.of(context).primaryColor
                        : (isDark ? Colors.white : Colors.grey[900]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

