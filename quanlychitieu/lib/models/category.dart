/// Mô hình dữ liệu cho danh mục chi tiêu hoặc thu nhập.
/// Định nghĩa cấu trúc của một danh mục, bao gồm tên, biểu tượng, màu sắc và người dùng sở hữu.
// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// `Category` là một mô hình dữ liệu đại diện cho một danh mục trong ứng dụng.
/// Chứa các thông tin cần thiết để lưu trữ, hiển thị và phân loại các khoản chi tiêu/thu nhập.
class Category {
  /// ID duy nhất của danh mục, thường là ID của tài liệu trong Firestore (có thể null khi tạo mới).
  final String? id;

  /// Tên của danh mục (ví dụ: "Ăn uống", "Di chuyển").
  final String name;

  /// Biểu tượng (IconData) đại diện cho danh mục.
  final IconData icon;

  /// Màu sắc của danh mục.
  final Color color;

  /// ID của người dùng sở hữu danh mục này (từ Firebase Auth).
  final String userId;

  /// Constructor để tạo một đối tượng `Category` mới.
  /// @param id ID của danh mục (tùy chọn).
  /// @param name Tên danh mục.
  /// @param icon Biểu tượng của danh mục.
  /// @param color Màu sắc của danh mục.
  /// @param userId ID người dùng sở hữu danh mục.
  Category({
    this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.userId,
  });

  /// Chuyển đổi đối tượng `Category` thành một Map để lưu trữ trong Firestore.
  /// Các trường `IconData` và `Color` được chuyển đổi thành giá trị số nguyên để lưu trữ.
  /// @return Map chứa dữ liệu danh mục.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'icon_code_point': icon.codePoint, // Lưu code point của icon
      'font_family': icon.fontFamily, // Lưu font family của icon
      'color_value': color.value, // Lưu giá trị số nguyên của màu sắc
      'userId': userId,
    };
  }

  /// Factory constructor để tạo một đối tượng `Category` từ một `DocumentSnapshot` của Firestore.
  /// Các giá trị số nguyên từ Firestore được chuyển đổi lại thành `IconData` và `Color`.
  /// @param doc DocumentSnapshot từ Firestore.
  /// @return Đối tượng `Category` được tạo từ dữ liệu Firestore.
  factory Category.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Category(
      id: doc.id,
      name: data['name'] ?? '',
      icon: IconData(
        data['icon_code_point'] ?? 0,
        fontFamily: data['font_family'] ?? 'MaterialIcons',
      ),
      color: Color(data['color_value'] ?? Colors.grey.value),
      userId: data['userId'] ?? '',
    );
  }
}
