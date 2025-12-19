/// Mô hình dữ liệu cho ngân sách chi tiêu.
/// Mỗi ngân sách được gắn với một danh mục chi tiêu trong một tháng cụ thể.
/// Định nghĩa cấu trúc của một đối tượng ngân sách, bao gồm số tiền,
/// danh mục, tháng, năm áp dụng và người dùng sở hữu.
// [ĐÃ REFACTOR] lib/models/budget.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// `Budget` là một mô hình dữ liệu đại diện cho một ngân sách trong ứng dụng.
/// Chứa các thông tin cần thiết để quản lý ngân sách cho từng danh mục theo tháng và năm.
class Budget {
  /// ID của ngân sách trong Firestore.
  /// Có thể null khi tạo mới và chưa lưu lên Firestore.
  final String? id;

  /// Số tiền ngân sách được cấp cho danh mục.
  final double amount;

  /// ID của danh mục chi tiêu được áp dụng ngân sách.
  /// Liên kết tới bảng categories trong Firestore.
  final String categoryId;

  /// Tháng áp dụng ngân sách (1-12).
  final int month;

  /// Năm áp dụng ngân sách.
  final int year;

  /// ID của người dùng sở hữu ngân sách này.
  /// Liên kết tới bảng users trong Firebase Auth.
  final String userId;

  /// Constructor tạo mới một đối tượng `Budget`.
  /// @param id ID của ngân sách (có thể null).
  /// @param amount Số tiền ngân sách.
  /// @param categoryId ID của danh mục.
  /// @param month Tháng áp dụng (1-12).
  /// @param year Năm áp dụng.
  /// @param userId ID của người dùng.
  Budget({
    this.id,
    required this.amount,
    required this.categoryId,
    required this.month,
    required this.year,
    required this.userId,
  });

  /// Chuyển đổi đối tượng `Budget` thành Map để lưu lên Firestore.
  /// @return Map chứa các trường dữ liệu của ngân sách.
  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'categoryId': categoryId,
      'month': month,
      'year': year,
      'userId': userId,
    };
  }

  /// Tạo một đối tượng `Budget` từ `DocumentSnapshot` của Firestore.
  /// Đảm bảo chuyển đổi đúng kiểu dữ liệu từ Firestore.
  /// @param doc DocumentSnapshot chứa dữ liệu ngân sách từ Firestore.
  /// @return Đối tượng `Budget` được tạo từ dữ liệu.
  factory Budget.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Budget(
      id: doc.id,
      amount: (data['amount'] ?? 0.0).toDouble(),
      categoryId: data['categoryId'] ?? '',
      month: data['month'] ?? 0,
      year: data['year'] ?? 0,
      userId: data['userId'] ?? '',
    );
  }
}
