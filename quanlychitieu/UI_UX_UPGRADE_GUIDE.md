# 🎨 Hướng Dẫn Nâng Cấp UI/UX - Ứng Dụng Quản Lý Chi Tiêu

## 📋 Tổng Quan

Tài liệu này cung cấp hướng dẫn chi tiết để nâng cấp giao diện và trải nghiệm người dùng của ứng dụng Flutter lên tầm chuyên nghiệp và hiện đại hơn.

---

## 1. 🎯 Áp Dụng Material Design 3 (Material You)

### 1.1. Cài Đặt Material Design 3

Flutter đã hỗ trợ Material 3 từ version 3.7+. Bạn cần cập nhật theme provider:

**File: `lib/providers/theme_provider.dart`**

```dart
ThemeData get lightTheme {
  return ThemeData(
    useMaterial3: true, // ✅ Bật Material 3
    colorScheme: ColorScheme.fromSeed(
      seedColor: _selectedColor,
      brightness: Brightness.light,
    ),
    // Tăng độ bo góc cho các component
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24), // ✅ Tăng từ 16 lên 24
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), // ✅ Bo góc lớn hơn
        ),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
      ),
    ),
    // ... các theme khác
  );
}
```

### 1.2. Dynamic Color (Material You)

Để hỗ trợ Dynamic Color trên Android 12+, thêm package:

**File: `pubspec.yaml`**
```yaml
dependencies:
  dynamic_color: ^1.5.0
```

**File: `lib/providers/theme_provider.dart`**
```dart
import 'package:dynamic_color/dynamic_color.dart';

Future<void> _loadDynamicColor() async {
  if (Platform.isAndroid) {
    final dynamicColor = await DynamicColorPlugin.getAccentColor();
    if (dynamicColor != null) {
      _selectedColor = dynamicColor;
      notifyListeners();
    }
  }
}
```

### 1.3. Typography Hiện Đại

Đã có `google_fonts`, nên cập nhật để sử dụng font phù hợp tiếng Việt:

**File: `lib/providers/theme_provider.dart`**
```dart
import 'package:google_fonts/google_fonts.dart';

ThemeData get lightTheme {
  return ThemeData(
    textTheme: GoogleFonts.beVietnamProTextTheme(), // ✅ Font tiếng Việt
    // Hoặc: GoogleFonts.interTextTheme() - Font quốc tế hiện đại
    // Hoặc: GoogleFonts.montserratTextTheme() - Font chuyên nghiệp
  );
}
```

---

## 2. 🧭 Cải Thiện Luồng Điều Hướng

### 2.1. Bottom Navigation Bar Hiện Đại

Ứng dụng đã có Bottom Navigation, nhưng có thể cải thiện:

**File: `lib/screens/home_screen.dart`**

```dart
Widget _buildBottomNavBar(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  
  return Container(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 20,
          offset: const Offset(0, -5),
        ),
      ],
    ),
    child: SafeArea(
      child: Container(
        height: 70, // ✅ Tăng chiều cao
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(context, Icons.home_rounded, 'Trang chủ', 0),
            _buildNavItem(context, Icons.bar_chart_rounded, 'Thống kê', 1),
            const SizedBox(width: 60), // Space for FAB
            _buildNavItem(context, Icons.account_balance_wallet_rounded, 'Ngân sách', 2),
            _buildNavItem(context, Icons.settings_rounded, 'Cài đặt', 3),
          ],
        ),
      ),
    ),
  );
}

Widget _buildNavItem(BuildContext context, IconData icon, String label, int index) {
  final isSelected = _selectedIndex == index;
  final colorScheme = Theme.of(context).colorScheme;
  
  return Expanded(
    child: InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected 
                  ? colorScheme.primary.withOpacity(0.1)
                  : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected 
                  ? colorScheme.primary
                  : colorScheme.onSurface.withOpacity(0.6),
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected 
                  ? colorScheme.primary
                  : colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
```

### 2.2. Floating Action Button Nâng Cao

Cải thiện FAB với animation và menu mở rộng:

**File: `lib/screens/home_screen.dart`**

```dart
Widget _buildFloatingActionButton(BuildContext context) {
  return FloatingActionButton.extended(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) => const AddExpenseScreen(),
        ),
      );
    },
    icon: const Icon(Icons.add_rounded),
    label: const Text('Thêm giao dịch'),
    backgroundColor: Theme.of(context).colorScheme.primary,
    foregroundColor: Colors.white,
    elevation: 8,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
  );
}
```

Hoặc sử dụng **Speed Dial** cho nhiều tùy chọn:

**File: `pubspec.yaml`**
```yaml
dependencies:
  flutter_speed_dial: ^7.0.0
```

```dart
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

SpeedDial(
  animatedIcon: AnimatedIcons.menu_close,
  animatedIconTheme: const IconThemeData(size: 22),
  backgroundColor: Theme.of(context).colorScheme.primary,
  foregroundColor: Colors.white,
  children: [
    SpeedDialChild(
      child: const Icon(Icons.remove_circle_outline),
      label: 'Chi tiêu',
      onTap: () => _navigateToAddExpense(false),
    ),
    SpeedDialChild(
      child: const Icon(Icons.add_circle_outline),
      label: 'Thu nhập',
      onTap: () => _navigateToAddExpense(true),
    ),
  ],
)
```

---

## 3. 📊 Thiết Kế Lại Trang Chủ (Dashboard)

### 3.1. Overview Card với Gradient

**File: `lib/screens/home_screen.dart`**

```dart
Widget _buildBalanceCard(BuildContext context, double balance, double totalIncome, double totalExpense) {
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

Widget _buildStatItem(BuildContext context, IconData icon, String label, double amount, Color color) {
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
```

### 3.2. Biểu Đồ Nhanh 7 Ngày

**File: `lib/screens/home_screen.dart`**

```dart
Widget _buildQuickChart(BuildContext context, List<Expense> expenses) {
  // Tính toán chi tiêu 7 ngày gần nhất
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
  
  final maxExpense = sevenDaysData.reduce((a, b) => a > b ? a : b);
  
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
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
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
```

### 3.3. Giao Dịch Gần Đây với "Xem Tất Cả"

```dart
Widget _buildRecentTransactions(BuildContext context, List<Expense> expenses) {
  final recentExpenses = expenses.take(5).toList();
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Giao dịch gần đây',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (expenses.length > 5)
            TextButton(
              onPressed: () {
                // Navigate to full transaction list
                setState(() => _selectedIndex = 0); // Hoặc tạo màn hình riêng
              },
              child: const Text('Xem tất cả'),
            ),
        ],
      ),
      const SizedBox(height: 16),
      ...recentExpenses.map((expense) => TransactionCard(...)),
    ],
  );
}
```

---

## 4. ⌨️ Tối Ưu Hóa Nhập Liệu

### 4.1. Bàn Phím Số Tùy Chỉnh

Tạo widget bàn phím số riêng:

**File: `lib/widgets/custom_numeric_keypad.dart`**

```dart
import 'package:flutter/material.dart';

class CustomNumericKeypad extends StatelessWidget {
  final Function(String) onKeyPressed;
  final VoidCallback? onDelete;
  final VoidCallback? onSubmit;
  
  const CustomNumericKeypad({
    Key? key,
    required this.onKeyPressed,
    this.onDelete,
    this.onSubmit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRow(['1', '2', '3']),
          const SizedBox(height: 12),
          _buildRow(['4', '5', '6']),
          const SizedBox(height: 12),
          _buildRow(['7', '8', '9']),
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
        ],
      ),
    );
  }

  Widget _buildRow(List<String> keys) {
    return Row(
      children: keys.map((key) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: _buildKey(key, null),
        ),
      )).toList(),
    );
  }

  Widget _buildKey(String key, BuildContext? context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onKeyPressed(key),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 60,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Theme.of(context ?? _getContext()).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            key,
            style: Theme.of(context ?? _getContext()).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionKey(IconData icon, VoidCallback onTap, BuildContext? context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 60,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
      ),
    );
  }

  BuildContext _getContext() {
    // Fallback context - nên truyền context từ parent
    throw UnimplementedError();
  }
}
```

**Sử dụng trong `add_expense_screen.dart`:**

```dart
// Thay TextField bằng:
GestureDetector(
  onTap: () {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CustomNumericKeypad(
        onKeyPressed: (key) {
          // Xử lý nhập số
          _amountController.text += key;
        },
        onDelete: () {
          if (_amountController.text.isNotEmpty) {
            _amountController.text = _amountController.text
              .substring(0, _amountController.text.length - 1);
          }
        },
      ),
    );
  },
  child: AbsorbPointer(
    child: TextField(
      controller: _amountController,
      // ...
    ),
  ),
)
```

### 4.2. Chọn Danh Mục bằng Icon Grid

**File: `lib/widgets/category_icon_grid.dart`**

```dart
import 'package:flutter/material.dart';

class CategoryIconGrid extends StatelessWidget {
  final List<Category> categories;
  final String? selectedCategoryId;
  final Function(String) onCategorySelected;
  
  const CategoryIconGrid({
    Key? key,
    required this.categories,
    this.selectedCategoryId,
    required this.onCategorySelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
        
        return GestureDetector(
          onTap: () => onCategorySelected(category.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                ? category.color.withOpacity(0.2)
                : category.color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? category.color : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  IconData(category.icon, fontFamily: 'MaterialIcons'),
                  color: category.color,
                  size: 32,
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
      },
    );
  }
}
```

### 4.3. Gợi Ý Thông Minh

**File: `lib/services/smart_suggestions_service.dart`**

```dart
class SmartSuggestionsService {
  static List<Category> getSuggestedCategories(
    List<Expense> history,
    DateTime currentTime,
  ) {
    final hour = currentTime.hour;
    
    // Gợi ý dựa trên giờ
    Map<int, List<String>> timeBasedCategories = {
      6: ['Ăn sáng', 'Cà phê'],
      12: ['Ăn trưa', 'Đồ uống'],
      18: ['Ăn tối', 'Giải trí'],
      22: ['Mua sắm online', 'Giải trí'],
    };
    
    // Gợi ý dựa trên lịch sử
    final recentCategories = history
      .where((e) => e.date.isAfter(DateTime.now().subtract(const Duration(days: 7))))
      .map((e) => e.categoryId)
      .toSet();
    
    // Kết hợp và trả về
    // ...
  }
}
```

---

## 5. 📈 Nâng Cấp Đồ Thị & Thống Kê

### 5.1. Biểu Đồ Tròn (Pie Chart) với fl_chart

**File: `lib/widgets/category_pie_chart.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class CategoryPieChart extends StatelessWidget {
  final Map<String, double> categoryExpenses;
  
  const CategoryPieChart({
    Key? key,
    required this.categoryExpenses,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
    ];
    
    final total = categoryExpenses.values.fold<double>(0, (a, b) => a + b);
    
    int touchedIndex = -1;
    
    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {
            // Xử lý khi nhấn vào phần biểu đồ
          },
        ),
        sectionsSpace: 2,
        centerSpaceRadius: 60,
        sections: categoryExpenses.entries.toList().asMap().entries.map((entry) {
          final index = entry.key;
          final category = entry.value.key;
          final amount = entry.value.value;
          final percentage = (amount / total * 100);
          
          return PieChartSectionData(
            color: colors[index % colors.length],
            value: amount,
            title: '${percentage.toStringAsFixed(1)}%',
            radius: touchedIndex == index ? 60 : 50,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList(),
      ),
    );
  }
}
```

### 5.2. So Sánh Tháng

**File: `lib/widgets/month_comparison_card.dart`**

```dart
Widget _buildMonthComparison(BuildContext context) {
  final currentMonth = _getCurrentMonthExpense();
  final lastMonth = _getLastMonthExpense();
  final change = currentMonth - lastMonth;
  final changePercent = lastMonth > 0 
    ? (change / lastMonth * 100).abs()
    : 0.0;
  final isIncrease = change > 0;
  
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tháng này',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                _formatCurrency(currentMonth),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isIncrease 
                ? Colors.red.withOpacity(0.1)
                : Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
                  color: isIncrease ? Colors.red : Colors.green,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '${changePercent.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: isIncrease ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
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
```

---

## 6. 🌙 Cải Thiện Dark Mode

Dark mode đã có, nhưng có thể cải thiện:

**File: `lib/providers/theme_provider.dart`**

```dart
ThemeData get darkTheme {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _selectedColor,
      brightness: Brightness.dark,
    ),
    // Tăng contrast cho dark mode
    scaffoldBackgroundColor: const Color(0xFF0A0E0B), // Đen hơn
    cardColor: const Color(0xFF1A1F1C), // Sáng hơn một chút
    // ...
  );
}
```

---

## 7. ✨ Hiệu Ứng Chuyển Động

### 7.1. Lottie Animations

**File: `pubspec.yaml`**
```yaml
dependencies:
  lottie: ^3.0.0
```

**File: `lib/widgets/empty_state.dart`**

```dart
import 'package:lottie/lottie.dart';

class EmptyStateWidget extends StatelessWidget {
  final String message;
  final String? lottieAsset;
  
  const EmptyStateWidget({
    Key? key,
    required this.message,
    this.lottieAsset = 'assets/animations/empty.json',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (lottieAsset != null)
            Lottie.asset(
              lottieAsset!,
              width: 200,
              height: 200,
            ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
```

### 7.2. Shared Element Transition

**File: `lib/screens/home_screen.dart`**

```dart
// Khi navigate đến detail
Navigator.push(
  context,
  PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => 
      ExpenseDetailScreen(expense: expense),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
  ),
);
```

### 7.3. Hero Animation

```dart
// Trong transaction card
Hero(
  tag: 'expense_${expense.id}',
  child: TransactionCard(...),
)

// Trong detail screen
Hero(
  tag: 'expense_${expense.id}',
  child: Image(...),
)
```

---

## 8. 📚 Các Thư Viện Đề Xuất

### 8.1. Dependencies Cần Thêm

**File: `pubspec.yaml`**

```yaml
dependencies:
  # Material Design 3 & Dynamic Color
  dynamic_color: ^1.5.0
  
  # Animations
  lottie: ^3.0.0
  animations: ^2.0.8
  
  # UI Components
  flutter_speed_dial: ^7.0.0
  shimmer: ^3.0.0  # Loading skeleton
  cached_network_image: ^3.3.0  # Image caching
  
  # Charts (đã có fl_chart)
  # fl_chart: ^0.66.0  ✅ Đã có
  
  # State Management (đã có provider)
  # provider: ^6.1.1  ✅ Đã có
  
  # Fonts (đã có google_fonts)
  # google_fonts: ^6.1.0  ✅ Đã có
```

### 8.2. Các Package Hữu Ích Khác

```yaml
  # Pull to refresh
  pull_to_refresh: ^2.0.0
  
  # Skeleton loading
  shimmer: ^3.0.0
  
  # Image picker & caching
  cached_network_image: ^3.3.0
  
  # Smooth scroll
  scrollable_positioned_list: ^0.3.6
  
  # Bottom sheet
  modal_bottom_sheet: ^3.0.0
```

---

## 9. 🎯 Checklist Triển Khai

### Phase 1: Foundation (Tuần 1)
- [ ] Cập nhật Material Design 3
- [ ] Cải thiện Typography với Google Fonts
- [ ] Tối ưu Dark Mode
- [ ] Cải thiện Bottom Navigation

### Phase 2: Dashboard (Tuần 2)
- [ ] Thiết kế lại Overview Card
- [ ] Thêm biểu đồ 7 ngày
- [ ] Cải thiện Recent Transactions
- [ ] Thêm animations cơ bản

### Phase 3: Input Optimization (Tuần 3)
- [ ] Tạo Custom Numeric Keypad
- [ ] Cải thiện Category Selection Grid
- [ ] Thêm Smart Suggestions
- [ ] Tối ưu form validation

### Phase 4: Charts & Statistics (Tuần 4)
- [ ] Nâng cấp Pie Chart
- [ ] Thêm Month Comparison
- [ ] Cải thiện Statistics Screen
- [ ] Thêm interactive charts

### Phase 5: Polish (Tuần 5)
- [ ] Thêm Lottie animations
- [ ] Cải thiện transitions
- [ ] Thêm Hero animations
- [ ] Performance optimization
- [ ] Testing & bug fixes

---

## 10. 📖 Tài Liệu Tham Khảo

- [Material Design 3 Guidelines](https://m3.material.io/)
- [Flutter Material 3](https://docs.flutter.dev/ui/design/material)
- [fl_chart Documentation](https://pub.dev/packages/fl_chart)
- [Google Fonts](https://fonts.google.com/)
- [Lottie Files](https://lottiefiles.com/)

---

## 11. 💡 Tips & Best Practices

1. **Performance**: Sử dụng `const` constructors khi có thể
2. **Accessibility**: Thêm `Semantics` widgets cho screen readers
3. **Responsive**: Test trên nhiều kích thước màn hình
4. **Animations**: Giữ animations mượt mà, không quá 300ms
5. **Colors**: Sử dụng `ColorScheme` từ Material 3
6. **Typography**: Tuân thủ Material Design typography scale

---

**Chúc bạn thành công với việc nâng cấp UI/UX! 🚀**

