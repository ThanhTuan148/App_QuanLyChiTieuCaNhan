/// Service quản lý thông báo và nhắc nhở trong ứng dụng
/// Sử dụng flutter_local_notifications để xử lý thông báo trên cả Android và iOS
/// Hỗ trợ nhiều loại thông báo: một lần, hàng ngày, hàng tuần, hàng tháng
/// Tích hợp với timezone để đảm bảo thông báo đúng thời gian
// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz_lib;
import 'package:timezone/data/latest.dart' as tz_data;
import 'dart:typed_data';
import '../models/reminder.dart';

class NotificationService {
  /// Singleton instance của NotificationService
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Plugin xử lý thông báo cục bộ
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Khởi tạo service thông báo
  ///
  /// Quy trình:
  /// 1. Khởi tạo timezone
  /// 2. Tạo notification channel cho Android
  /// 3. Cấu hình cho Android và iOS
  /// 4. Khởi tạo plugin với các cài đặt
  /// 5. Xử lý sự kiện khi thông báo được nhấn
  Future<void> init() async {
    // Khởi tạo timezone
    tz_data.initializeTimeZones();

    // Tạo notification channel cho Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'reminder_channel',
      'Nhắc nhở',
      description: 'Kênh thông báo cho các nhắc nhở',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    // Cấu hình Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Cấu hình iOS
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestSoundPermission: true,
          requestBadgePermission: true,
          requestAlertPermission: true,
        );

    // Kết hợp cấu hình
    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    // Khởi tạo plugin với xử lý sự kiện
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        debugPrint('Notification clicked: ${response.payload}');
        if (response.actionId == 'stop_alarm') {
          debugPrint('Dừng báo thức được nhấn');
          await flutterLocalNotificationsPlugin.cancelAll();
        }
      },
    );

    // Tạo channel cho Android
    final androidPlugin =
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(channel);
    }
  }

  /// Yêu cầu quyền thông báo từ người dùng
  ///
  /// Returns:
  /// - true: Nếu quyền được cấp phép
  /// - false: Nếu quyền bị từ chối
  Future<bool> requestPermission() async {
    final plugin =
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    if (plugin != null) {
      return await plugin.requestNotificationsPermission() ?? false;
    }
    return false;
  }

  /// Lên lịch thông báo nhắc nhở
  ///
  /// Parameters:
  /// - reminder: Đối tượng Reminder chứa thông tin nhắc nhở
  ///
  /// Hỗ trợ các tần suất:
  /// - once: Một lần
  /// - daily: Hàng ngày
  /// - weekly: Hàng tuần (với các ngày cụ thể)
  /// - monthly: Hàng tháng
  Future<void> scheduleReminderNotification(Reminder reminder) async {
    if (reminder.id == null) {
      debugPrint('Không thể lên lịch thông báo: Reminder ID là null.');
      return;
    }

    final int notificationId = reminder.id.hashCode;

    // Cấu hình thông báo cho Android
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'reminder_channel',
          'Nhắc nhở',
          channelDescription: 'Kênh thông báo cho các nhắc nhở',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          playSound: true,
          sound: _getAndroidSoundResource(reminder.sound),
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
          visibility: NotificationVisibility.public,
          category: AndroidNotificationCategory.alarm,
          fullScreenIntent: reminder.notificationType == 'Báo thức',
          actions: <AndroidNotificationAction>[
            const AndroidNotificationAction(
              'stop_alarm',
              'Dừng',
              cancelNotification: true,
              showsUserInterface: true,
            ),
          ],
        );

    // Cấu hình thông báo cho iOS
    final DarwinNotificationDetails darwinPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: reminder.sound != 'Không có',
          sound: _getiOSSoundResource(reminder.sound),
        );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: darwinPlatformChannelSpecifics,
    );

    // Chuyển đổi và kiểm tra thời gian
    tz_lib.TZDateTime scheduledDate = tz_lib.TZDateTime.from(
      reminder.scheduledTime,
      tz_lib.local,
    );

    // Kiểm tra thời gian đã qua
    if (scheduledDate.isBefore(tz_lib.TZDateTime.now(tz_lib.local))) {
      debugPrint(
        'Thời gian lên lịch cho nhắc nhở ${reminder.title} đã trôi qua. Sẽ lên lịch cho lần tiếp theo nếu có.',
      );
    }

    // Lên lịch thông báo theo tần suất
    if (reminder.frequency == 'once') {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        reminder.title,
        reminder.content,
        scheduledDate,
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: reminder.id,
      );
    } else if (reminder.frequency == 'daily') {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        reminder.title,
        reminder.content,
        scheduledDate,
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: reminder.id,
      );
    } else if (reminder.frequency == 'weekly') {
      for (int weekday in reminder.weekdays) {
        tz_lib.TZDateTime nextScheduledDate = _getNextWeekdayOccurrence(
          scheduledDate,
          weekday,
        );
        await flutterLocalNotificationsPlugin.zonedSchedule(
          notificationId + weekday,
          reminder.title,
          reminder.content,
          nextScheduledDate,
          platformChannelSpecifics,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: reminder.id,
        );
      }
    } else if (reminder.frequency == 'monthly') {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        reminder.title,
        reminder.content,
        scheduledDate,
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
        payload: reminder.id,
      );
    }
  }

  /// Tìm lần xuất hiện tiếp theo của một ngày trong tuần
  ///
  /// Parameters:
  /// - scheduledTime: Thời gian đã lên lịch
  /// - weekday: Ngày trong tuần (1-7)
  ///
  /// Returns:
  /// - TZDateTime của lần xuất hiện tiếp theo
  tz_lib.TZDateTime _getNextWeekdayOccurrence(
    tz_lib.TZDateTime scheduledTime,
    int weekday,
  ) {
    tz_lib.TZDateTime now = tz_lib.TZDateTime.now(tz_lib.local);
    tz_lib.TZDateTime nextOccurrence = tz_lib.TZDateTime(
      tz_lib.local,
      scheduledTime.year,
      scheduledTime.month,
      scheduledTime.day,
      scheduledTime.hour,
      scheduledTime.minute,
      scheduledTime.second,
    );

    // Tìm ngày tiếp theo phù hợp
    while (nextOccurrence.weekday != weekday || nextOccurrence.isBefore(now)) {
      nextOccurrence = nextOccurrence.add(const Duration(days: 1));
    }
    return nextOccurrence;
  }

  /// Hủy thông báo cho một nhắc nhở cụ thể
  ///
  /// Parameters:
  /// - reminderId: ID của nhắc nhở cần hủy
  Future<void> cancelReminderNotification(String reminderId) async {
    final int notificationId = reminderId.hashCode;
    await flutterLocalNotificationsPlugin.cancel(notificationId);
    debugPrint('Đã hủy thông báo cho nhắc nhở với ID: $reminderId');
    // Hủy tất cả các thông báo liên quan cho nhắc nhở hàng tuần
    for (int i = 1; i <= 7; i++) {
      await flutterLocalNotificationsPlugin.cancel(notificationId + i);
    }
  }

  /// Hủy tất cả các thông báo đang lên lịch
  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
    debugPrint('Đã hủy tất cả thông báo.');
  }

  /// Ánh xạ tên âm thanh thân thiện sang tên tài nguyên Android
  ///
  /// Parameters:
  /// - soundName: Tên âm thanh thân thiện
  ///
  /// Returns:
  /// - RawResourceAndroidNotificationSound tương ứng hoặc null
  RawResourceAndroidNotificationSound? _getAndroidSoundResource(
    String soundName,
  ) {
    switch (soundName) {
      case 'Còi báo động ngắn':
        return const RawResourceAndroidNotificationSound('alarm_clock_short');
      case 'Báo động Hy Lạp':
        return const RawResourceAndroidNotificationSound('greece_eas_alarm');
      case 'Báo động Thái Lan':
        return const RawResourceAndroidNotificationSound('thailand_eas_alarm');
      case 'Radar':
        return const RawResourceAndroidNotificationSound('alarm');
      case 'Mặc định':
        return null;
      default:
        return null;
    }
  }

  /// Ánh xạ tên âm thanh thân thiện sang tên tài nguyên iOS
  ///
  /// Parameters:
  /// - soundName: Tên âm thanh thân thiện
  ///
  /// Returns:
  /// - Tên file âm thanh iOS tương ứng hoặc null
  String? _getiOSSoundResource(String soundName) {
    switch (soundName) {
      case 'Còi báo động ngắn':
        return 'alarm-clock-short-6402.mp3';
      case 'Báo động Hy Lạp':
        return 'greece-eas-alarm-1949-271565.mp3';
      case 'Báo động Thái Lan':
        return 'thailand-eas-alarm-2006-266492.mp3';
      case 'Radar':
        return 'greece-eas-alarm-1949-271565.mp3';
      case 'Mặc định':
        return null;
      default:
        return null;
    }
  }
}
