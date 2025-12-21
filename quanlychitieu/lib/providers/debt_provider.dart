/// Provider quản lý Nợ cá nhân
/// Học từ cách các doanh nghiệp giảm nợ vay để tối ưu dòng tiền
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/debt.dart';
import 'auth_provider.dart';

class DebtProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthProvider authProvider;

  List<Debt> _debts = [];
  StreamSubscription? _debtsSubscription;

  List<Debt> get debts => _debts;
  List<Debt> get activeDebts => _debts.where((d) => d.status == DebtStatus.active).toList();
  List<Debt> get overdueDebts => _debts.where((d) => d.isOverdue).toList();

  /// Tổng số dư nợ hiện tại
  double get totalDebtBalance {
    return activeDebts.fold(0.0, (sum, debt) => sum + debt.currentBalance);
  }

  /// Tổng lãi suất hàng tháng
  double get totalMonthlyInterest {
    return activeDebts.fold(0.0, (sum, debt) => sum + debt.monthlyInterest);
  }

  DebtProvider(this.authProvider) {
    debugPrint('DebtProvider: Constructor called');
    authProvider.addListener(_onAuthChanged);
    _onAuthChanged();
  }

  void _onAuthChanged() {
    debugPrint('DebtProvider: _onAuthChanged called, isLoggedIn: ${authProvider.isLoggedIn}');
    if (authProvider.isLoggedIn) {
      final userId = authProvider.currentUser?.id;
      debugPrint('DebtProvider: User logged in, userId: $userId');
      _listenToDebts();
    } else {
      debugPrint('DebtProvider: User not logged in, clearing debts');
      _debts = [];
      _debtsSubscription?.cancel();
      notifyListeners();
    }
  }
  
  /// Force refresh debts (public method)
  void refreshDebts() {
    debugPrint('DebtProvider: refreshDebts() called');
    _listenToDebts();
  }

  void _listenToDebts() {
    final userId = authProvider.currentUser?.id;
    if (userId == null) {
      debugPrint('DebtProvider: userId is null, cannot listen to debts');
      return;
    }

    debugPrint('DebtProvider: Starting to listen to debts for userId: $userId');
    _debtsSubscription?.cancel();
    _debtsSubscription = _firestore
        .collection('debts')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen(
      (snapshot) {
        debugPrint('DebtProvider: Received ${snapshot.docs.length} debts from Firestore');
        debugPrint('DebtProvider: Query userId: $userId');
        
        // Debug: In ra userId của từng document
        for (var doc in snapshot.docs) {
          debugPrint('DebtProvider: Document ${doc.id} has userId: ${doc.data()['userId']}');
        }
        
        _debts = snapshot.docs
            .map((doc) {
              try {
                final debt = Debt.fromFirestore(doc);
                debugPrint('DebtProvider: Successfully parsed debt: ${debt.name}');
                return debt;
              } catch (e) {
                debugPrint('DebtProvider: Error parsing debt ${doc.id}: $e');
                debugPrint('DebtProvider: Document data: ${doc.data()}');
                return null;
              }
            })
            .whereType<Debt>()
            .toList()
          ..sort((a, b) => b.startDate.compareTo(a.startDate)); // Sort by startDate descending
        debugPrint('DebtProvider: Total debts after processing: ${_debts.length}');
        debugPrint('DebtProvider: Calling notifyListeners()');
        notifyListeners();
      },
      onError: (error) {
        debugPrint('DebtProvider: Error listening to debts: $error');
        debugPrint('DebtProvider: Error stack trace: ${error.stackTrace}');
        // Nếu có lỗi, vẫn notify để UI có thể hiển thị thông báo
        notifyListeners();
      },
    );
    
    debugPrint('DebtProvider: Stream subscription created');
  }

  /// Thêm khoản nợ mới
  Future<void> addDebt(Debt debt) async {
    final userId = authProvider.currentUser?.id;
    if (userId == null) throw Exception('Người dùng chưa đăng nhập');

    debugPrint('DebtProvider: Adding debt: ${debt.name}, userId: $userId');
    final docRef = await _firestore.collection('debts').add(debt.toJson());
    debugPrint('DebtProvider: Debt added successfully with ID: ${docRef.id}');
    // Stream sẽ tự động cập nhật khi có thay đổi trong Firestore
    // Nhưng đảm bảo notify để UI refresh ngay lập tức
    notifyListeners();
  }

  /// Cập nhật khoản nợ
  Future<void> updateDebt(Debt debt) async {
    if (debt.id == null) throw Exception('Debt ID không hợp lệ');
    await _firestore.collection('debts').doc(debt.id).update(debt.toJson());
  }

  /// Ghi nhận thanh toán nợ
  Future<void> makePayment({
    required String debtId,
    required double amount,
  }) async {
    final debt = _debts.firstWhere((d) => d.id == debtId);
    final newBalance = debt.currentBalance - amount;
    
    final updatedDebt = debt.copyWith(
      currentBalance: newBalance > 0 ? newBalance : 0,
      status: newBalance <= 0 ? DebtStatus.paid : DebtStatus.active,
      paidDate: newBalance <= 0 ? DateTime.now() : null,
    );

    await updateDebt(updatedDebt);
  }

  /// Xóa khoản nợ
  Future<void> deleteDebt(String debtId) async {
    await _firestore.collection('debts').doc(debtId).delete();
  }

  /// Phân tích nợ và đưa ra gợi ý
  Map<String, dynamic> analyzeDebts() {
    if (activeDebts.isEmpty) {
      return {
        'totalDebt': 0.0,
        'monthlyPayment': 0.0,
        'suggestion': 'Bạn không có khoản nợ nào. Tuyệt vời!',
      };
    }

    final totalDebt = totalDebtBalance;
    final monthlyPayment = activeDebts.fold(
      0.0,
      (sum, debt) => sum + debt.calculateMonthlyPayment(),
    );
    final totalInterest = totalMonthlyInterest;

    String suggestion = '';
    if (totalInterest > monthlyPayment * 0.3) {
      suggestion = '⚠️ Lãi suất cao! Nên ưu tiên trả các khoản nợ lãi suất cao trước để giảm chi phí lãi vay.';
    } else if (overdueDebts.isNotEmpty) {
      suggestion = '🔴 Có ${overdueDebts.length} khoản nợ quá hạn! Cần xử lý ngay để tránh phí phạt.';
    } else {
      suggestion = '✅ Tình hình nợ ổn định. Tiếp tục trả đúng hạn để giảm nợ.';
    }

    return {
      'totalDebt': totalDebt,
      'monthlyPayment': monthlyPayment,
      'totalInterest': totalInterest,
      'suggestion': suggestion,
      'debtToIncomeRatio': 0.0, // Sẽ tính khi có thu nhập
    };
  }

  @override
  void dispose() {
    debugPrint('DebtProvider: Disposing');
    _debtsSubscription?.cancel();
    authProvider.removeListener(_onAuthChanged);
    super.dispose();
  }
}

