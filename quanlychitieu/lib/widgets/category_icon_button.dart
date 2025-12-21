/// Widget tái sử dụng cho category icon button
import 'package:flutter/material.dart';

class CategoryIconButton extends StatelessWidget {
  final String emoji;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? backgroundColor;

  const CategoryIconButton({
    super.key,
    required this.emoji,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = backgroundColor ?? 
        (isDark ? Colors.grey[800] : Colors.grey[100]);
    final selectedBgColor = backgroundColor ?? 
        (isDark ? Colors.grey[700] : Colors.grey[200]);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isSelected ? selectedBgColor : bgColor,
              borderRadius: BorderRadius.circular(16),
              border: isSelected
                  ? Border.all(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    )
                  : Border.all(
                      color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                      width: 2,
                    ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }
}

