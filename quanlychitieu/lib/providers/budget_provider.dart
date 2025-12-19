/// Provider quản lý dữ liệu ngân sách của người dùng.
/// Lắng nghe dữ liệu real-time từ Firebase dựa trên tháng/năm hiện tại,
/// cung cấp các hàm CRUD cho ngân sách.
// lib/providers/budget_provider.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../models/budget.dart';
import '../services/firebase_service.dart';
import 'auth_provider.dart';
import 'date_range_provider.dart';
import '../models/date_range.dart'; // Import model DateRange để biết thuộc tính

/// `BudgetProvider` quản lý trạng thái và logic liên quan đến các ngân sách.
/// Nó tích hợp với `FirebaseService` để đồng bộ dữ liệu ngân sách và `AuthProvider` để theo dõi trạng thái người dùng,
/// cũng như `DateRangeProvider` để lọc ngân sách theo tháng/năm hiện tại.
class BudgetProvider with ChangeNotifier {
  /// Instance của `FirebaseService` để tương tác với Firebase Firestore.
  final FirebaseService _firebaseService = FirebaseService();

  /// Provider xác thực người dùng để lắng nghe trạng thái đăng nhập/đăng xuất.
  final AuthProvider authProvider;

  /// Provider khoảng thời gian để biết tháng/năm hiện tại mà người dùng đang xem.
  final DateRangeProvider dateRangeProvider;

  /// Danh sách các ngân sách hiện có của người dùng trong tháng/năm hiện tại.
  List<Budget> _budgets = [];

  /// Subscription để lắng nghe các thay đổi từ luồng dữ liệu ngân sách Firebase.
  StreamSubscription? _budgetSubscription;

  /// Getter trả về danh sách các ngân sách hiện tại.
  List<Budget> get budgets => _budgets;

  /// Constructor của `BudgetProvider`.
  /// @param authProvider Provider xác thực người dùng.
  /// @param dateRangeProvider Provider khoảng thời gian.
  BudgetProvider(this.authProvider, this.dateRangeProvider) {
    // Lắng nghe thay đổi từ AuthProvider để biết khi nào cần tải/dọn dẹp dữ liệu ngân sách.
    authProvider.addListener(_onAuthChanged);
    // Lắng nghe thay đổi từ DateRangeProvider để cập nhật ngân sách theo tháng/năm mới.
    dateRangeProvider.addListener(_onDateRangeChanged);
    // Gọi lần đầu để kiểm tra trạng thái đăng nhập và tải dữ liệu ban đầu.
    _onAuthChanged();
  }

  /// Xử lý khi trạng thái xác thực của người dùng thay đổi.
  /// Nếu người dùng đăng nhập, bắt đầu lắng nghe luồng dữ liệu ngân sách. Ngược lại, dọn dẹp dữ liệu.
  void _onAuthChanged() {
    if (authProvider.isLoggedIn) {
      _listenToBudgets();
    } else {
      _budgets = [];
      _budgetSubscription?.cancel();
      notifyListeners();
    }
  }

  /// Xử lý khi khoảng thời gian (tháng/năm) được chọn thay đổi.
  /// Nếu người dùng đang đăng nhập, cần lắng nghe lại luồng dữ liệu ngân sách theo tháng/năm mới.
  void _onDateRangeChanged() {
    // Khi người dùng đổi tháng/năm, ta cần lắng nghe lại stream budget
    if (authProvider.isLoggedIn) {
      _listenToBudgets();
    }
  }

  /// Lắng nghe luồng dữ liệu ngân sách từ Firebase.
  /// Hủy subscription cũ (nếu có) và tạo một subscription mới dựa trên tháng/năm hiện tại.
  void _listenToBudgets() {
    _budgetSubscription?.cancel();

    // [SỬA LỖI] Truy cập đúng thuộc tính của DateRange để lấy tháng và năm.
    final DateRange currentRange = dateRangeProvider.currentRange;
    final int currentMonth = currentRange.startDate.month;
    final int currentYear = currentRange.startDate.year;

    _budgetSubscription = _firebaseService
        .getBudgetsStream(
          currentMonth,
          currentYear,
        ) // Lọc ngân sách theo tháng và năm hiện tại.
        .listen((newBudgets) {
          _budgets = newBudgets;
          notifyListeners(); // Thông báo cho UI cập nhật mỗi khi có dữ liệu mới.
        });
  }

  /// Lưu một ngân sách vào Firebase.
  /// @param budget Đối tượng ngân sách cần lưu (có thể là mới hoặc cập nhật).
  Future<void> saveBudget(Budget budget) async =>
      await _firebaseService.saveBudget(budget);

  /// Xóa một ngân sách khỏi Firebase.
  /// @param budgetId ID của ngân sách cần xóa.
  Future<void> deleteBudget(String budgetId) async =>
      await _firebaseService.deleteBudget(budgetId);

  /// Lấy ngân sách cho một danh mục cụ thể trong danh sách ngân sách hiện tại.
  /// @param categoryId ID của danh mục cần tìm ngân sách.
  /// @return Đối tượng `Budget` nếu tìm thấy, ngược lại trả về `null`.
  Budget? getBudgetForCategory(String categoryId) {
    try {
      return _budgets.firstWhere((b) => b.categoryId == categoryId);
    } catch (e) {
      return null; // Không tìm thấy
    }
  }

  /// Giải phóng tài nguyên khi provider không còn được sử dụng.
  /// Hủy bỏ lắng nghe `AuthProvider`, `DateRangeProvider` và subscription dữ liệu ngân sách.
  @override
  void dispose() {
    authProvider.removeListener(_onAuthChanged);
    dateRangeProvider.removeListener(_onDateRangeChanged);
    _budgetSubscription?.cancel();
    super.dispose();
  }
}
