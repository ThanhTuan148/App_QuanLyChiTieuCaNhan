/// Provider quản lý các nhắc nhở (reminders) trong ứng dụng.
/// Lắng nghe thay đổi nhắc nhở từ Firebase, lên lịch và hủy thông báo cục bộ.
// lib/providers/reminder_provider.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../models/reminder.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';
import 'auth_provider.dart';

/// `ReminderProvider` quản lý trạng thái và logic liên quan đến các nhắc nhở.
/// Nó tích hợp với `FirebaseService` để đồng bộ dữ liệu và `NotificationService` để quản lý thông báo.
class ReminderProvider with ChangeNotifier {
  /// Instance của `FirebaseService` để tương tác với Firebase Firestore.
  final FirebaseService _firebaseService = FirebaseService();

  /// Instance của `NotificationService` để quản lý thông báo cục bộ.
  final NotificationService _notificationService = NotificationService();

  /// Provider xác thực người dùng để lắng nghe trạng thái đăng nhập/đăng xuất.
  final AuthProvider authProvider;

  /// Danh sách các nhắc nhở hiện có của người dùng.
  List<Reminder> _reminders = [];

  /// Subscription để lắng nghe các thay đổi từ luồng nhắc nhở Firebase.
  StreamSubscription? _reminderSubscription;

  /// Getter trả về danh sách các nhắc nhở hiện tại.
  List<Reminder> get reminders => _reminders;

  /// Constructor của `ReminderProvider`.
  /// @param authProvider Provider xác thực người dùng.
  ReminderProvider(this.authProvider) {
    // Lắng nghe sự kiện thay đổi trạng thái xác thực.
    authProvider.addListener(_onAuthChanged);
    // Gọi ngay lần đầu để xử lý trạng thái hiện tại.
    _onAuthChanged();
  }

  /// Xử lý khi trạng thái xác thực của người dùng thay đổi.
  /// Nếu người dùng đăng nhập, bắt đầu lắng nghe nhắc nhở. Ngược lại, hủy bỏ subscription và xóa nhắc nhở.
  void _onAuthChanged() {
    if (authProvider.isLoggedIn) {
      _listenToReminders();
    } else {
      _reminders = [];
      _reminderSubscription?.cancel();
      // Hủy tất cả thông báo khi người dùng đăng xuất
      _notificationService.cancelAllNotifications();
      notifyListeners();
    }
  }

  /// Lắng nghe luồng các nhắc nhở từ Firebase.
  /// Hủy subscription cũ (nếu có) và tạo một subscription mới.
  void _listenToReminders() {
    _reminderSubscription?.cancel();
    _reminderSubscription = _firebaseService.getRemindersStream().listen((
      newReminders,
    ) {
      _reminders = newReminders;
      debugPrint(
        "ReminderProvider: Nhận được ${newReminders.length} nhắc nhở. Bắt đầu lên lịch lại.",
      );
      _rescheduleAllNotifications();
      notifyListeners();
    });
  }

  /// Hủy tất cả thông báo hiện có và lên lịch lại cho các nhắc nhở đang hoạt động.
  Future<void> _rescheduleAllNotifications() async {
    await _notificationService.cancelAllNotifications();
    for (final reminder in _reminders) {
      if (reminder.isActive) {
        // Gọi đúng tên hàm để lên lịch thông báo nhắc nhở
        await _notificationService.scheduleReminderNotification(reminder);
      }
    }
    debugPrint(
      "ReminderProvider: Đã lên lịch lại tất cả các thông báo đang hoạt động.",
    );
  }

  /// Lưu một nhắc nhở vào Firebase.
  /// @param reminder Đối tượng nhắc nhở cần lưu (có thể là mới hoặc cập nhật).
  Future<void> saveReminder(Reminder reminder) async {
    await _firebaseService.saveReminder(reminder);
  }

  /// Xóa một nhắc nhở khỏi Firebase và hủy thông báo tương ứng.
  /// @param reminderId ID của nhắc nhở cần xóa.
  Future<void> deleteReminder(String reminderId) async {
    // Hủy thông báo cục bộ trước khi xóa nhắc nhở khỏi Firebase
    await _notificationService.cancelReminderNotification(reminderId);
    await _firebaseService.deleteReminder(reminderId);
  }

  /// Cập nhật trạng thái kích hoạt của một nhắc nhở.
  /// @param reminder Đối tượng nhắc nhở cần cập nhật.
  /// @param isActive Trạng thái kích hoạt mới (true để bật, false để tắt).
  Future<void> updateReminderStatus(Reminder reminder, bool isActive) async {
    final updatedReminder = reminder.copyWith(isActive: isActive);
    await saveReminder(updatedReminder);
  }

  /// Giải phóng tài nguyên khi provider không còn được sử dụng.
  /// Hủy bỏ lắng nghe `AuthProvider` và subscription nhắc nhở.
  @override
  void dispose() {
    authProvider.removeListener(_onAuthChanged);
    _reminderSubscription?.cancel();
    super.dispose();
  }
}
