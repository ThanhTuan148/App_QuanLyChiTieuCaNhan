/// Mô hình dữ liệu cho Nợ cá nhân
/// Học từ cách các doanh nghiệp giảm nợ vay để tối ưu dòng tiền
import 'package:cloud_firestore/cloud_firestore.dart';

enum DebtType {
  creditCard,    // Thẻ tín dụng
  personalLoan,  // Vay cá nhân
  mortgage,      // Vay mua nhà
  other,         // Khác
}

enum DebtStatus {
  active,        // Đang nợ
  paid,          // Đã trả xong
  overdue,       // Quá hạn
}

class Debt {
  final String? id;
  final String userId;
  final String name; // Tên khoản nợ (ví dụ: "Thẻ tín dụng Vietcombank")
  final DebtType type;
  final double principalAmount; // Số tiền gốc
  final double currentBalance; // Số dư hiện tại
  final double interestRate; // Lãi suất (%/năm)
  final DateTime startDate;
  final DateTime? dueDate; // Ngày đáo hạn
  final DateTime? paidDate; // Ngày trả xong
  final DebtStatus status;
  final String? description;
  final String? creditor; // Chủ nợ (ngân hàng, công ty tài chính)

  Debt({
    this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.principalAmount,
    required this.currentBalance,
    required this.interestRate,
    required this.startDate,
    this.dueDate,
    this.paidDate,
    required this.status,
    this.description,
    this.creditor,
  });

  /// Tính số tiền lãi hàng tháng
  double get monthlyInterest {
    return currentBalance * (interestRate / 100 / 12);
  }

  /// Tính tổng số tiền cần trả hàng tháng (nếu trả đều)
  double calculateMonthlyPayment({
    int months = 12,
  }) {
    if (months <= 0) return 0;
    final monthlyRate = interestRate / 100 / 12;
    if (monthlyRate == 0) {
      return currentBalance / months;
    }
    final ratePlusOne = 1 + monthlyRate;
    final numerator = monthlyRate * _power(ratePlusOne, months);
    final denominator = _power(ratePlusOne, months) - 1;
    return currentBalance * numerator / denominator;
  }

  /// Helper function for power calculation
  double _power(double base, int exponent) {
    double result = 1.0;
    for (int i = 0; i < exponent; i++) {
      result *= base;
    }
    return result;
  }

  /// Kiểm tra có quá hạn không
  bool get isOverdue {
    if (dueDate == null || status != DebtStatus.active) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  /// Số ngày quá hạn
  int? get daysOverdue {
    if (!isOverdue) return null;
    return DateTime.now().difference(dueDate!).inDays;
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'type': type.name,
      'principalAmount': principalAmount,
      'currentBalance': currentBalance,
      'interestRate': interestRate,
      'startDate': Timestamp.fromDate(startDate),
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'paidDate': paidDate != null ? Timestamp.fromDate(paidDate!) : null,
      'status': status.name,
      'description': description,
      'creditor': creditor,
    };
  }

  factory Debt.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Debt(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      type: DebtType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => DebtType.other,
      ),
      principalAmount: (data['principalAmount'] ?? 0.0).toDouble(),
      currentBalance: (data['currentBalance'] ?? 0.0).toDouble(),
      interestRate: (data['interestRate'] ?? 0.0).toDouble(),
      startDate: (data['startDate'] as Timestamp).toDate(),
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
      paidDate: (data['paidDate'] as Timestamp?)?.toDate(),
      status: DebtStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => DebtStatus.active,
      ),
      description: data['description'],
      creditor: data['creditor'],
    );
  }

  Debt copyWith({
    String? name,
    double? currentBalance,
    DateTime? dueDate,
    DateTime? paidDate,
    DebtStatus? status,
    String? description,
  }) {
    return Debt(
      id: id,
      userId: userId,
      name: name ?? this.name,
      type: type,
      principalAmount: principalAmount,
      currentBalance: currentBalance ?? this.currentBalance,
      interestRate: interestRate,
      startDate: startDate,
      dueDate: dueDate ?? this.dueDate,
      paidDate: paidDate ?? this.paidDate,
      status: status ?? this.status,
      description: description ?? this.description,
      creditor: creditor,
    );
  }
}

