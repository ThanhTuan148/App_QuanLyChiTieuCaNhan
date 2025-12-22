/// Bàn phím số tùy chỉnh cho nhập số tiền
/// Giúp người dùng nhập số nhanh hơn và có trải nghiệm tốt hơn

import 'package:flutter/material.dart';

class CustomNumericKeypad extends StatelessWidget {
  final Function(String) onKeyPressed;
  final VoidCallback? onDelete;
  final VoidCallback? onSubmit;
  
  const CustomNumericKeypad({
    super.key,
    required this.onKeyPressed,
    this.onDelete,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark 
          ? colorScheme.surface 
          : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _buildRow(['1', '2', '3'], context),
            const SizedBox(height: 12),
            _buildRow(['4', '5', '6'], context),
            const SizedBox(height: 12),
            _buildRow(['7', '8', '9'], context),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildKey('0', context),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildKey('.', context),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionKey(
                    Icons.backspace_outlined,
                    onDelete ?? () {},
                    context,
                  ),
                ),
              ],
            ),
            if (onSubmit != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onSubmit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Xác nhận'),
                ),
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(List<String> keys, BuildContext context) {
    return Row(
      children: keys.map((key) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: _buildKey(key, context),
        ),
      )).toList(),
    );
  }

  Widget _buildKey(String key, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onKeyPressed(key),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 60,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            key,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionKey(IconData icon, VoidCallback onTap, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 60,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            color: colorScheme.primary,
            size: 24,
          ),
        ),
      ),
    );
  }
}

