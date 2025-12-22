/// Grid hiển thị danh mục dưới dạng icon tròn màu sắc
/// Giúp người dùng chọn danh mục nhanh và trực quan hơn

import 'package:flutter/material.dart';
import '../models/category.dart' as app_category;
import '../utils/category_emoji_mapper.dart';

class CategoryIconGrid extends StatelessWidget {
  final List<app_category.Category> categories;
  final String? selectedCategoryId;
  final Function(String) onCategorySelected;
  final bool isIncome;
  
  const CategoryIconGrid({
    super.key,
    required this.categories,
    this.selectedCategoryId,
    required this.onCategorySelected,
    this.isIncome = false,
  });

  @override
  Widget build(BuildContext context) {
    // Categories được sử dụng cho cả income và expense, không cần filter
    if (categories.isEmpty) {
      return const Center(
        child: Text('Chưa có danh mục nào'),
      );
    }
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final isSelected = category.id == selectedCategoryId;
        
        return _buildCategoryItem(context, category, isSelected);
      },
    );
  }

  Widget _buildCategoryItem(
    BuildContext context,
    app_category.Category category,
    bool isSelected,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final emoji = CategoryEmojiMapper.getEmojiForIcon(category.icon);
    
    return GestureDetector(
      onTap: () {
        if (category.id != null) {
          onCategorySelected(category.id!);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isSelected
              ? category.color.withOpacity(0.2)
              : category.color.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? category.color : Colors.transparent,
            width: isSelected ? 3 : 0,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: category.color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 28),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category.name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: category.color,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

