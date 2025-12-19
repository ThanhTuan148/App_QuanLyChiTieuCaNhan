/// Mô hình dữ liệu cho nhắc nhở (Reminder).
/// Định nghĩa cấu trúc của một đối tượng nhắc nhở, bao gồm thông tin chi tiết về nội dung,
/// thời gian, tần suất, trạng thái và các thuộc tính liên quan đến thông báo.
// [ĐÃ REFACTOR] lib/models/reminder.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// `Reminder` là một mô hình dữ liệu đại diện cho một nhắc nhở trong ứng dụng.
/// Chứa các thông tin cần thiết để lên lịch và hiển thị thông báo nhắc nhở.
class Reminder {
  /// ID duy nhất của nhắc nhở, thường là ID của tài liệu trong Firestore (có thể null khi tạo mới).
  final String? id; // [THAY ĐỔI] ID của Firestore là String

  /// Tiêu đề của nhắc nhở.
  final String title;

  /// Nội dung chi tiết của nhắc nhở.
  final String content;

  /// Thời gian cụ thể mà nhắc nhở được lên lịch (bao gồm ngày, giờ, phút).
  final DateTime scheduledTime;

  /// Tần suất lặp lại của nhắc nhở (ví dụ: 'daily', 'weekly', 'monthly', 'once').
  final String frequency;

  /// Danh sách các ngày trong tuần mà nhắc nhở lặp lại (đối với tần suất 'weekly').
  /// Giá trị từ 1 (Thứ 2) đến 7 (Chủ Nhật).
  final List<int> weekdays; // Firestore hỗ trợ lưu trữ mảng (Array)

  /// Ngày trong tháng mà nhắc nhở lặp lại (đối với tần suất 'monthly') (có thể null).
  final int? day;

  /// Trạng thái kích hoạt của nhắc nhở (true nếu hoạt động, false nếu bị tắt).
  final bool isActive;

  /// ID của người dùng sở hữu nhắc nhở này (từ Firebase Auth).
  final String userId; // [THAY ĐỔI] userId của Firebase Auth là String

  /// ID của danh mục liên quan đến nhắc nhở (có thể null).
  final String? categoryId; // [MỚI] Thêm ID danh mục

  /// Loại thông báo (ví dụ: 'Báo thức', 'Thông báo').
  final String
  notificationType; // [MỚI] Loại thông báo: 'Báo thức', 'Thông báo'

  /// Tên âm thanh báo thức được chọn (ví dụ: 'Radar', 'None', 'Mặc định').
  final String sound; // [MỚI] Âm thanh báo thức: 'Radar', 'None', etc.

  /// Constructor để tạo một đối tượng `Reminder` mới.
  /// @param id ID của nhắc nhở (tùy chọn).
  /// @param title Tiêu đề của nhắc nhở.
  /// @param content Nội dung của nhắc nhở.
  /// @param scheduledTime Thời gian lên lịch.
  /// @param frequency Tần suất lặp lại.
  /// @param weekdays Danh sách ngày trong tuần (mặc định rỗng).
  /// @param day Ngày trong tháng (tùy chọn).
  /// @param isActive Trạng thái hoạt động.
  /// @param userId ID người dùng.
  /// @param categoryId ID danh mục (tùy chọn).
  /// @param notificationType Loại thông báo (mặc định 'Thông báo').
  /// @param sound Âm thanh (mặc định 'Mặc định').
  Reminder({
    this.id,
    required this.title,
    required this.content,
    required this.scheduledTime,
    required this.frequency,
    this.weekdays = const [],
    this.day,
    required this.isActive,
    required this.userId,
    this.categoryId,
    this.notificationType = 'Thông báo',
    this.sound = 'Mặc định',
  });

  /// Chuyển đổi đối tượng `Reminder` thành một Map để lưu trữ trong Firestore.
  /// Các trường DateTime được chuyển thành `Timestamp`.
  /// @return Map chứa dữ liệu nhắc nhở.
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'scheduledTime': Timestamp.fromDate(
        scheduledTime,
      ), // [QUAN TRỌNG] Dùng Timestamp
      'frequency': frequency,
      'weekdays': weekdays, // Lưu trực tiếp list int
      'day': day,
      'isActive': isActive,
      'userId': userId,
      'categoryId': categoryId, // [MỚI] Thêm vào toJson
      'notificationType': notificationType,
      'sound': sound,
    };
  }

  /// Factory constructor để tạo một đối tượng `Reminder` từ một `DocumentSnapshot` của Firestore.
  /// Xử lý chuyển đổi `Timestamp` thành `DateTime` và list `dynamic` sang `list int`.
  /// @param doc DocumentSnapshot từ Firestore.
  /// @return Đối tượng `Reminder` được tạo từ dữ liệu Firestore.
  factory Reminder.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Chuyển đổi list dynamic sang list int một cách an toàn cho `weekdays`.
    List<int> weekdaysFromDb = [];
    if (data['weekdays'] is List) {
      weekdaysFromDb = List<int>.from(data['weekdays']);
    }

    return Reminder(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      scheduledTime:
          (data['scheduledTime'] as Timestamp)
              .toDate(), // Chuyển Timestamp về DateTime
      frequency: data['frequency'] ?? '',
      weekdays: weekdaysFromDb,
      day: data['day'],
      isActive: data['isActive'] ?? false,
      userId: data['userId'] ?? '',
      categoryId: data['categoryId'], // [MỚI] Đọc từ Firestore
      notificationType: data['notificationType'] ?? 'Thông báo',
      sound: data['sound'] ?? 'Mặc định',
    );
  }

  /// Tạo một bản sao của đối tượng `Reminder` với các thuộc tính được cập nhật.
  /// Các tham số tùy chọn cho phép chỉ cập nhật những trường cần thiết.
  /// @param id ID mới (tùy chọn).
  /// @param title Tiêu đề mới (tùy chọn).
  /// @param content Nội dung mới (tùy chọn).
  /// @param scheduledTime Thời gian lên lịch mới (tùy chọn).
  /// @param frequency Tần suất mới (tùy chọn).
  /// @param weekdays Danh sách ngày trong tuần mới (tùy chọn).
  /// @param day Ngày trong tháng mới (tùy chọn).
  /// @param isActive Trạng thái hoạt động mới (tùy chọn).
  /// @param userId ID người dùng mới (tùy chọn).
  /// @param categoryId ID danh mục mới (tùy chọn).
  /// @param notificationType Loại thông báo mới (tùy chọn).
  /// @param sound Âm thanh mới (tùy chọn).
  Reminder copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? scheduledTime,
    String? frequency,
    List<int>? weekdays,
    int? day,
    bool? isActive,
    String? userId,
    String? categoryId,
    String? notificationType,
    String? sound,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      frequency: frequency ?? this.frequency,
      weekdays: weekdays ?? this.weekdays,
      day: day ?? this.day,
      isActive: isActive ?? this.isActive,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      notificationType: notificationType ?? this.notificationType,
      sound: sound ?? this.sound,
    );
  }
}
