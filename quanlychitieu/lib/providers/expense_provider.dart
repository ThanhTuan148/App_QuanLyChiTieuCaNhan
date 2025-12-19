/// Provider quản lý dữ liệu chi tiêu và thu nhập của người dùng.
/// Lắng nghe dữ liệu real-time từ Firebase, cung cấp các hàm CRUD,
/// và các hàm tính toán, lọc dữ liệu theo thời gian và danh mục.
// lib/providers/expense_provider.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../models/date_range.dart';
import '../services/firebase_service.dart';
import 'auth_provider.dart';

/// `ExpenseProvider` quản lý trạng thái và logic liên quan đến các khoản chi tiêu và thu nhập.
/// Nó tích hợp với `FirebaseService` để đồng bộ dữ liệu và `AuthProvider` để theo dõi trạng thái người dùng.
class ExpenseProvider with ChangeNotifier {
  /// Instance của `FirebaseService` để tương tác với Firebase Firestore.
  final FirebaseService _firebaseService = FirebaseService();

  /// Provider xác thực người dùng để lắng nghe trạng thái đăng nhập/đăng xuất.
  final AuthProvider authProvider;

  /// Danh sách các khoản chi tiêu/thu nhập hiện có của người dùng.
  List<Expense> _expenses = [];

  /// Subscription để lắng nghe các thay đổi từ luồng dữ liệu chi tiêu Firebase.
  StreamSubscription? _expenseSubscription;

  /// Getter trả về danh sách các khoản chi tiêu/thu nhập hiện tại.
  List<Expense> get expenses => _expenses;

  /// Constructor của `ExpenseProvider`.
  /// @param authProvider Provider xác thực người dùng.
  ExpenseProvider(this.authProvider) {
    // Lắng nghe thay đổi từ AuthProvider để biết khi nào cần tải/dọn dẹp dữ liệu.
    authProvider.addListener(_onAuthChanged);
    // Gọi lần đầu để kiểm tra trạng thái đăng nhập hiện tại.
    _onAuthChanged();
  }

  /// Xử lý khi trạng thái xác thực của người dùng thay đổi.
  /// Nếu người dùng đăng nhập, bắt đầu lắng nghe dữ liệu chi tiêu. Ngược lại, dọn dẹp dữ liệu.
  void _onAuthChanged() {
    if (authProvider.isLoggedIn) {
      // Nếu người dùng đã đăng nhập, bắt đầu lắng nghe stream dữ liệu chi tiêu.
      _listenToExpenses();
    } else {
      // Nếu người dùng đăng xuất, dọn dẹp dữ liệu cũ và hủy stream.
      _expenses = [];
      _expenseSubscription?.cancel();
      notifyListeners();
    }
  }

  /// Lắng nghe luồng dữ liệu chi tiêu từ Firebase.
  /// Hủy stream cũ (nếu có) và tạo một stream mới.
  void _listenToExpenses() {
    _expenseSubscription
        ?.cancel(); // Hủy stream cũ nếu có để tránh memory leak.
    _expenseSubscription = _firebaseService.getExpensesStream().listen((
      newExpenses,
    ) {
      _expenses = newExpenses;
      notifyListeners(); // Thông báo cho UI cập nhật mỗi khi có dữ liệu mới.
    });
  }

  // --- CÁC HÀM CRUD (CREATE, READ, UPDATE, DELETE) ---
  /// Thêm một khoản chi tiêu/thu nhập mới vào Firebase.
  /// @param expense Đối tượng chi tiêu/thu nhập cần thêm.
  Future<void> addExpense(Expense expense) async =>
      await _firebaseService.saveExpense(expense);

  /// Cập nhật một khoản chi tiêu/thu nhập hiện có trong Firebase.
  /// @param expense Đối tượng chi tiêu/thu nhập đã cập nhật.
  Future<void> updateExpense(Expense expense) async =>
      await _firebaseService.saveExpense(expense);

  /// Xóa một khoản chi tiêu/thu nhập khỏi Firebase.
  /// @param expenseId ID của khoản chi tiêu/thu nhập cần xóa.
  Future<void> deleteExpense(String expenseId) async =>
      await _firebaseService.deleteExpense(expenseId);

  /// Giải phóng tài nguyên khi provider không còn được sử dụng.
  /// Hủy bỏ lắng nghe `AuthProvider` và subscription dữ liệu chi tiêu.
  @override
  void dispose() {
    authProvider.removeListener(_onAuthChanged);
    _expenseSubscription?.cancel();
    super.dispose();
  }

  // --- CÁC HÀM TÍNH TOÁN VÀ LỌC DỮ LIỆU ---
  // Tất cả các hàm này hoạt động trên danh sách `_expenses` hiện tại,
  // mà danh sách này đã được cập nhật real-time từ Firebase.

  /// Lọc và trả về danh sách các khoản chi tiêu/thu nhập trong một khoảng thời gian cụ thể.
  /// @param dateRange Khoảng thời gian để lọc.
  /// @return Danh sách `Expense` nằm trong khoảng thời gian đã cho.
  List<Expense> getExpensesByDateRange(DateRange dateRange) {
    return _expenses
        .where((expense) => dateRange.contains(expense.date))
        .toList();
  }

  /// Tính tổng chi tiêu trong một khoảng thời gian cụ thể.
  /// @param dateRange Khoảng thời gian để tính tổng.
  /// @return Tổng số tiền chi tiêu.
  double getTotalExpensesByDateRange(DateRange dateRange) {
    return getExpensesByDateRange(dateRange)
        .where((expense) => !expense.isIncome)
        .fold(0.0, (sum, expense) => sum + expense.amount);
  }

  /// Tính tổng thu nhập trong một khoảng thời gian cụ thể.
  /// @param dateRange Khoảng thời gian để tính tổng.
  /// @return Tổng số tiền thu nhập.
  double getTotalIncomeByDateRange(DateRange dateRange) {
    return getExpensesByDateRange(dateRange)
        .where((expense) => expense.isIncome)
        .fold(0.0, (sum, expense) => sum + expense.amount);
  }

  /// Tính số dư (thu nhập - chi tiêu) trong một khoảng thời gian cụ thể.
  /// @param dateRange Khoảng thời gian để tính số dư.
  /// @return Số dư trong khoảng thời gian.
  double getBalanceByDateRange(DateRange dateRange) {
    return getTotalIncomeByDateRange(dateRange) -
        getTotalExpensesByDateRange(dateRange);
  }

  /// Lấy tổng chi tiêu theo từng danh mục trong một khoảng thời gian.
  /// @param dateRange Khoảng thời gian để lọc và tính toán.
  /// @return Map chứa tổng chi tiêu cho mỗi categoryId.
  Map<String, double> getExpensesByCategoryAndDateRange(DateRange dateRange) {
    final Map<String, double> expensesByCategory = {};

    for (var expense in getExpensesByDateRange(
      dateRange,
    ).where((e) => !e.isIncome)) {
      // categoryId giờ là String
      expensesByCategory[expense.categoryId] =
          (expensesByCategory[expense.categoryId] ?? 0.0) + expense.amount;
    }

    return expensesByCategory;
  }

  /// Tính tổng chi tiêu của tất cả các khoản chi tiêu.
  /// Những hàm này tính toán trên toàn bộ dữ liệu thay vì một khoảng thời gian cụ thể.
  double getTotalExpenses() {
    return _expenses
        .where((expense) => !expense.isIncome)
        .fold(0.0, (sum, expense) => sum + expense.amount);
  }

  /// Tính tổng thu nhập của tất cả các khoản thu nhập.
  double getTotalIncome() {
    return _expenses
        .where((expense) => expense.isIncome)
        .fold(0.0, (sum, expense) => sum + expense.amount);
  }

  /// Tính số dư (tổng thu nhập - tổng chi tiêu) của tất cả các khoản.
  double getBalance() {
    return getTotalIncome() - getTotalExpenses();
  }

  /// Tính tổng chi tiêu trong một tháng và năm cụ thể.
  /// @param month Tháng (1-12).
  /// @param year Năm.
  /// @return Tổng chi tiêu trong tháng đó.
  double getTotalExpensesByMonth(int month, int year) {
    return _expenses
        .where(
          (expense) =>
              !expense.isIncome &&
              expense.date.month == month &&
              expense.date.year == year,
        )
        .fold(0.0, (sum, expense) => sum + expense.amount);
  }

  /// Tính tổng thu nhập trong một tháng và năm cụ thể.
  /// @param month Tháng (1-12).
  /// @param year Năm.
  /// @return Tổng thu nhập trong tháng đó.
  double getTotalIncomeByMonth(int month, int year) {
    return _expenses
        .where(
          (expense) =>
              expense.isIncome &&
              expense.date.month == month &&
              expense.date.year == year,
        )
        .fold(0.0, (sum, expense) => sum + expense.amount);
  }

  /// Tính tổng chi tiêu cho một danh mục cụ thể trên toàn bộ dữ liệu.
  /// @param categoryId ID của danh mục.
  /// @return Tổng chi tiêu của danh mục đó.
  double getTotalExpensesByCategory(String categoryId) {
    return _expenses
        .where(
          (expense) => !expense.isIncome && expense.categoryId == categoryId,
        )
        .fold(0.0, (sum, expense) => sum + expense.amount);
  }

  /// Lấy tổng chi tiêu theo từng danh mục trong một tháng và năm cụ thể.
  /// @param month Tháng (1-12).
  /// @param year Năm.
  /// @return Map chứa tổng chi tiêu cho mỗi categoryId trong tháng đó.
  Map<String, double> getExpensesByCategory(int month, int year) {
    final Map<String, double> expensesByCategory = {};

    for (var expense in _expenses.where(
      (e) => !e.isIncome && e.date.month == month && e.date.year == year,
    )) {
      expensesByCategory[expense.categoryId] =
          (expensesByCategory[expense.categoryId] ?? 0.0) + expense.amount;
    }

    return expensesByCategory;
  }
}
