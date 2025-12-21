/// Widget tái sử dụng cho glass effect card
import 'dart:ui';
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? borderRadius;
  final Color? backgroundColor;
  final bool isDark;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.backgroundColor,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = backgroundColor ??
        (isDarkMode
            ? const Color(0xFF1E2824).withOpacity(0.9)
            : Colors.white.withOpacity(0.8));

    return Container(
      margin: margin ?? const EdgeInsets.all(0),
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius ?? 24),
        border: Border.all(
          color: isDarkMode
              ? const Color(0xFF4CAF50).withOpacity(0.2)
              : Colors.white.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : const Color(0xFF4CAF50).withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius ?? 24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: child,
        ),
      ),
    );
  }
}

