# 🚀 Hướng Dẫn Triển Khai Nhanh

## 📦 Cài Đặt Dependencies

Thêm vào `pubspec.yaml`:

```yaml
dependencies:
  dynamic_color: ^1.5.0
  lottie: ^3.0.0
  flutter_speed_dial: ^7.0.0
  shimmer: ^3.0.0
  cached_network_image: ^3.3.0
```

Sau đó chạy:
```bash
flutter pub get
```

---

## 🎨 1. Cập Nhật Material Design 3

**File: `lib/providers/theme_provider.dart`**

Thêm `useMaterial3: true` vào cả `lightTheme` và `darkTheme`:

```dart
ThemeData get lightTheme {
  return ThemeData(
    useMaterial3: true, // ✅ Thêm dòng này
    // ... rest of theme
  );
}
```

---

## 🏠 2. Sử Dụng Overview Card

**File: `lib/screens/home_screen.dart`**

Thay thế `_buildBalanceCard` bằng:

```dart
import '../widgets/overview_card.dart';

// Trong _buildMainPage:
OverviewCard(
  balance: balance,
  totalIncome: totalIncome,
  totalExpense: totalExpense,
  currencySymbol: 'VND',
)
```

---

## 📊 3. Thêm Biểu Đồ 7 Ngày

**File: `lib/screens/home_screen.dart`**

```dart
import '../widgets/quick_chart_widget.dart';

// Trong _buildMainPage, sau OverviewCard:
const SizedBox(height: 24),
QuickChartWidget(expenses: expenses),
```

---

## ⌨️ 4. Sử Dụng Bàn Phím Số Tùy Chỉnh

**File: `lib/screens/add_expense_screen.dart`**

```dart
import '../widgets/custom_numeric_keypad.dart';

// Thay TextField amount bằng:
GestureDetector(
  onTap: () {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CustomNumericKeypad(
        onKeyPressed: (key) {
          setState(() {
            if (key == '.' && _amountController.text.contains('.')) {
              return; // Không cho phép nhiều dấu chấm
            }
            _amountController.text += key;
          });
        },
        onDelete: () {
          setState(() {
            if (_amountController.text.isNotEmpty) {
              _amountController.text = _amountController.text
                .substring(0, _amountController.text.length - 1);
            }
          });
        },
        onSubmit: () {
          Navigator.pop(context);
        },
      ),
    );
  },
  child: AbsorbPointer(
    child: TextField(
      controller: _amountController,
      decoration: InputDecoration(
        labelText: 'Số tiền',
        suffixIcon: Icon(Icons.keyboard),
      ),
    ),
  ),
)
```

---

## 🎯 5. Sử Dụng Category Icon Grid

**File: `lib/screens/add_expense_screen.dart`**

```dart
import '../widgets/category_icon_grid.dart';

// Thay phần chọn category bằng:
CategoryIconGrid(
  categories: categories,
  selectedCategoryId: _selectedCategoryId,
  onCategorySelected: (categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
    });
  },
  isIncome: _isIncome,
)
```

---

## 📈 6. Thêm So Sánh Tháng

**File: `lib/screens/statistics_screen.dart`**

```dart
import '../widgets/month_comparison_card.dart';

// Thêm vào đầu màn hình:
MonthComparisonCard(
  currentMonthExpense: _getCurrentMonthExpense(),
  lastMonthExpense: _getLastMonthExpense(),
  currencySymbol: 'VND',
)
```

---

## 🎭 7. Sử Dụng Empty State

**File: `lib/screens/home_screen.dart`**

```dart
import '../widgets/empty_state_widget.dart';

// Khi expenses.isEmpty:
EmptyStateWidget(
  message: 'Chưa có giao dịch nào trong khoảng thời gian này',
  icon: '📭',
  action: ElevatedButton(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) => const AddExpenseScreen(),
        ),
      );
    },
    child: const Text('Thêm giao dịch đầu tiên'),
  ),
)
```

---

## 🧭 8. Cải Thiện Bottom Navigation

**File: `lib/screens/home_screen.dart`**

Cập nhật method `_buildBottomNavBar` với code từ `UI_UX_UPGRADE_GUIDE.md` phần 2.1.

---

## ✨ 9. Thêm Animations

### Lottie (nếu có file animation)

**File: `pubspec.yaml`**
```yaml
flutter:
  assets:
    - assets/animations/
```

**Sử dụng:**
```dart
import 'package:lottie/lottie.dart';

Lottie.asset(
  'assets/animations/success.json',
  width: 200,
  height: 200,
)
```

---

## 📝 Checklist Triển Khai

- [ ] Cài đặt dependencies
- [ ] Cập nhật Material Design 3
- [ ] Thay thế Overview Card
- [ ] Thêm Quick Chart
- [ ] Tích hợp Custom Numeric Keypad
- [ ] Sử dụng Category Icon Grid
- [ ] Thêm Month Comparison
- [ ] Cải thiện Bottom Navigation
- [ ] Thêm Empty States
- [ ] Test trên thiết bị thật

---

## 🐛 Xử Lý Lỗi Thường Gặp

### Lỗi import
- Đảm bảo đã chạy `flutter pub get`
- Kiểm tra đường dẫn import đúng

### Widget không hiển thị
- Kiểm tra `expenses` list không null
- Đảm bảo có dữ liệu để hiển thị

### Animation không chạy
- Kiểm tra file Lottie có trong `assets/`
- Đảm bảo đã khai báo trong `pubspec.yaml`

---

**Xem chi tiết trong `UI_UX_UPGRADE_GUIDE.md`** 📖

