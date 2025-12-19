/// Mô hình dữ liệu cho người dùng ứng dụng.
/// Định nghĩa cấu trúc của một đối tượng người dùng, bao gồm thông tin cá nhân và cờ trạng thái.
//  lib/models/user.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// `AppUser` là một mô hình dữ liệu đại diện cho người dùng trong ứng dụng.
/// Chứa các thông tin cơ bản về người dùng và hỗ trợ chuyển đổi dữ liệu sang/từ Firestore.
class AppUser {
  /// ID duy nhất của người dùng, thường là UID từ Firebase Authentication.
  final String id;

  /// Tên người dùng được hiển thị.
  final String username;

  /// Địa chỉ email của người dùng.
  final String email;

  /// Thời điểm người dùng được tạo tài khoản.
  final DateTime createdAt;

  /// URL hoặc đường dẫn đến ảnh đại diện của người dùng (có thể null).
  final String? avatar;

  /// Số điện thoại của người dùng (có thể null).
  final String? phone; // [QUAN TRỌNG] Đảm bảo dòng này tồn tại

  /// Cờ kiểm tra xem các danh mục mặc định đã được thêm cho người dùng này chưa.
  final bool
  defaultCategoriesAdded; // [MỚI] Thêm cờ để kiểm tra danh mục mặc định đã thêm chưa

  /// Constructor để tạo một đối tượng `AppUser` mới.
  /// @param id ID duy nhất của người dùng.
  /// @param username Tên người dùng.
  /// @param email Địa chỉ email.
  /// @param createdAt Thời điểm tạo tài khoản.
  /// @param avatar URL ảnh đại diện (tùy chọn).
  /// @param phone Số điện thoại (tùy chọn).
  /// @param defaultCategoriesAdded Cờ thêm danh mục mặc định (mặc định là false).
  AppUser({
    required this.id,
    required this.username,
    required this.email,
    required this.createdAt,
    this.avatar,
    this.phone,
    this.defaultCategoriesAdded = false, // Mặc định là false
  });

  /// Chuyển đổi đối tượng `AppUser` thành một Map để lưu trữ trong Firestore.
  /// @return Map chứa dữ liệu người dùng.
  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'createdAt': Timestamp.fromDate(createdAt),
      'avatar': avatar,
      'phone': phone,
      'defaultCategoriesAdded': defaultCategoriesAdded, // Thêm vào toJson
    };
  }

  /// Factory constructor để tạo một đối tượng `AppUser` từ một `DocumentSnapshot` của Firestore.
  /// @param doc DocumentSnapshot từ Firestore.
  /// @return Đối tượng `AppUser` được tạo từ dữ liệu Firestore.
  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AppUser(
      id: doc.id,
      username: data['username'] ?? '',
      email: data['email'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      avatar: data['avatar'],
      phone: data['phone'],
      defaultCategoriesAdded:
          data['defaultCategoriesAdded'] ??
          false, // Đọc từ Firestore, mặc định là false
    );
  }

  /// Tạo một bản sao của đối tượng `AppUser` với các thuộc tính được cập nhật.
  /// Các tham số tùy chọn cho phép chỉ cập nhật những trường cần thiết.
  /// @param username Tên người dùng mới (tùy chọn).
  /// @param phone Số điện thoại mới (tùy chọn).
  /// @param avatar URL ảnh đại diện mới (tùy chọn).
  /// @param defaultCategoriesAdded Trạng thái cờ danh mục mặc định mới (tùy chọn).
  /// @return Một đối tượng `AppUser` mới với các thuộc tính đã cập nhật.
  // [QUAN TRỌNG] Đảm bảo hàm này tồn tại
  AppUser copyWith({
    String? username,
    String? phone,
    String? avatar,
    bool? defaultCategoriesAdded,
  }) {
    return AppUser(
      id: id,
      username: username ?? this.username,
      email: email,
      createdAt: createdAt,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      defaultCategoriesAdded:
          defaultCategoriesAdded ?? this.defaultCategoriesAdded,
    );
  }
}
