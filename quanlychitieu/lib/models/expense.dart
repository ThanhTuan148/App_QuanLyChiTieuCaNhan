/// Mô hình dữ liệu cho khoản chi tiêu hoặc thu nhập (Expense).
/// Định nghĩa cấu trúc của một giao dịch tài chính, bao gồm số tiền, mô tả,
/// ngày, danh mục, loại (thu/chi) và người dùng liên quan.
// [ĐÃ SỬA LỖI CUỐI CÙNG] lib/models/expense.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// `Expense` là một mô hình dữ liệu đại diện cho một giao dịch tài chính (chi tiêu hoặc thu nhập) trong ứng dụng.
/// Chứa các thông tin cần thiết để lưu trữ, hiển thị và phân tích các khoản thu chi.
class Expense {
  /// ID duy nhất của giao dịch, thường là ID của tài liệu trong Firestore (có thể null khi tạo mới).
  final String? id;

  /// Số tiền của giao dịch.
  final double amount;

  /// Mô tả chi tiết về giao dịch.
  final String description;

  /// Ngày diễn ra giao dịch.
  final DateTime date;

  /// ID của danh mục liên quan đến giao dịch.
  final String categoryId;

  /// Cờ xác định đây là khoản thu nhập (true) hay chi tiêu (false).
  final bool isIncome;

  /// ID của người dùng sở hữu giao dịch này (từ Firebase Auth).
  final String userId;

  /// Constructor để tạo một đối tượng `Expense` mới.
  /// @param id ID của giao dịch (tùy chọn).
  /// @param amount Số tiền.
  /// @param description Mô tả.
  /// @param date Ngày giao dịch.
  /// @param categoryId ID danh mục.
  /// @param isIncome Là thu nhập hay chi tiêu.
  /// @param userId ID người dùng.
  Expense({
    this.id,
    required this.amount,
    required this.description,
    required this.date,
    required this.categoryId,
    required this.isIncome,
    required this.userId,
  });

  /// Chuyển đổi đối tượng `Expense` thành một Map để lưu trữ trong Firestore.
  /// Trường `date` được chuyển thành `Timestamp`.
  /// @return Map chứa dữ liệu giao dịch.
  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'description': description,
      'date': Timestamp.fromDate(date), // Khi lưu mới, luôn dùng Timestamp
      'categoryId': categoryId,
      'isIncome': isIncome,
      'userId': userId,
    };
  }

  /// Factory constructor để tạo một đối tượng `Expense` từ một `DocumentSnapshot` của Firestore.
  /// Xử lý chuyển đổi `Timestamp` hoặc `String` thành `DateTime` cho trường `date`.
  /// Xử lý chuyển đổi `categoryId` sang `String`.
  /// @param doc DocumentSnapshot từ Firestore.
  /// @return Đối tượng `Expense` được tạo từ dữ liệu Firestore.
  factory Expense.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // [SỬA LỖI] Xử lý cả hai kiểu dữ liệu cho trường 'date' (Timestamp hoặc String).
    DateTime parsedDate;
    if (data['date'] is Timestamp) {
      // Nếu là dữ liệu mới (đúng chuẩn), chuyển từ Timestamp sang DateTime.
      parsedDate = (data['date'] as Timestamp).toDate();
    } else if (data['date'] is String) {
      // Nếu là dữ liệu cũ (kiểu String), phân tích chuỗi thành DateTime.
      parsedDate = DateTime.tryParse(data['date']) ?? DateTime.now();
    } else {
      // Trường hợp dự phòng nếu kiểu dữ liệu không xác định.
      parsedDate = DateTime.now();
    }

    return Expense(
      id: doc.id,
      amount: (data['amount'] ?? 0.0).toDouble(),
      description: data['description'] ?? '',
      date: parsedDate, // Gán ngày đã được xử lý
      // [SỬA LỖI] Xử lý categoryId có thể là int (dữ liệu cũ) bằng cách chuyển sang String.
      categoryId: data['categoryId'].toString(),
      isIncome: data['isIncome'] ?? false,
      userId: data['userId'] ?? '',
    );
  }
}
