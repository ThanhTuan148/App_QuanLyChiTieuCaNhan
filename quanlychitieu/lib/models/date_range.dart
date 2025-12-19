import 'package:flutter/material.dart';

/// Enum định nghĩa các loại khoảng thời gian được sử dụng trong ứng dụng.
/// Bao gồm các loại cố định như ngày, tuần, tháng, năm và một loại tùy chỉnh.
enum DateRangeType { day, week, month, year, custom }

/// Mô hình dữ liệu cho khoảng thời gian (DateRange).
/// Định nghĩa một khoảng thời gian với ngày bắt đầu, ngày kết thúc và loại khoảng thời gian.
class DateRange {
  /// Loại của khoảng thời gian (ví dụ: day, week, month, year, custom).
  final DateRangeType type;

  /// Ngày bắt đầu của khoảng thời gian.
  final DateTime startDate;

  /// Ngày kết thúc của khoảng thời gian.
  final DateTime endDate;

  /// Constructor để tạo một đối tượng `DateRange` mới.
  /// @param type Loại khoảng thời gian.
  /// @param startDate Ngày bắt đầu.
  /// @param endDate Ngày kết thúc.
  DateRange({
    required this.type,
    required this.startDate,
    required this.endDate,
  });

  /// Factory constructor để tạo một khoảng thời gian cho 'Hôm nay'.
  /// Ngày bắt đầu là đầu ngày hôm nay và ngày kết thúc là cuối ngày hôm nay.
  factory DateRange.today() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return DateRange(type: DateRangeType.day, startDate: start, endDate: end);
  }

  /// Factory constructor để tạo một khoảng thời gian cho 'Tuần này'.
  /// Ngày bắt đầu là đầu ngày Thứ 2 của tuần hiện tại và ngày kết thúc là cuối ngày Chủ Nhật của tuần đó.
  factory DateRange.thisWeek() {
    final now = DateTime.now();
    // Tìm ngày đầu tuần (thứ 2)
    final start = now.subtract(Duration(days: now.weekday - 1));
    final startDate = DateTime(start.year, start.month, start.day);
    // Tìm ngày cuối tuần (chủ nhật)
    final end = startDate.add(const Duration(days: 6));
    final endDate = DateTime(end.year, end.month, end.day, 23, 59, 59);

    return DateRange(
      type: DateRangeType.week,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Factory constructor để tạo một khoảng thời gian cho 'Tháng này'.
  /// Ngày bắt đầu là đầu tháng hiện tại và ngày kết thúc là cuối tháng hiện tại.
  factory DateRange.thisMonth() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    // Tìm ngày cuối tháng
    final end =
        (now.month < 12)
            ? DateTime(now.year, now.month + 1, 0, 23, 59, 59)
            : DateTime(now.year + 1, 1, 0, 23, 59, 59);

    return DateRange(type: DateRangeType.month, startDate: start, endDate: end);
  }

  /// Factory constructor để tạo một khoảng thời gian cho 'Năm nay'.
  /// Ngày bắt đầu là đầu năm hiện tại và ngày kết thúc là cuối năm hiện tại.
  factory DateRange.thisYear() {
    final now = DateTime.now();
    final start = DateTime(now.year, 1, 1);
    final end = DateTime(now.year, 12, 31, 23, 59, 59);

    return DateRange(type: DateRangeType.year, startDate: start, endDate: end);
  }

  /// Factory constructor để tạo một khoảng thời gian tùy chỉnh.
  /// Đảm bảo ngày bắt đầu và kết thúc được chuẩn hóa về đầu ngày và cuối ngày.
  /// @param start Ngày bắt đầu được chọn.
  /// @param end Ngày kết thúc được chọn.
  factory DateRange.custom(DateTime start, DateTime end) {
    return DateRange(
      type: DateRangeType.custom,
      startDate: DateTime(start.year, start.month, start.day),
      endDate: DateTime(end.year, end.month, end.day, 23, 59, 59),
    );
  }

  /// Kiểm tra xem một ngày cụ thể có nằm trong khoảng thời gian này không.
  /// @param date Ngày cần kiểm tra.
  /// @return `true` nếu ngày nằm trong khoảng, ngược lại `false`.
  bool contains(DateTime date) {
    return (date.isAtSameMomentAs(startDate) || date.isAfter(startDate)) &&
        (date.isAtSameMomentAs(endDate) || date.isBefore(endDate));
  }

  /// Getter trả về chuỗi hiển thị thân thiện cho khoảng thời gian.
  /// Ví dụ: 'Hôm nay', 'Tuần này', 'Tháng 10/2023', 'Từ 01/01/2023 đến 31/12/2023'.
  String get displayText {
    switch (type) {
      case DateRangeType.day:
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final selectedDay = DateTime(
          startDate.year,
          startDate.month,
          startDate.day,
        );

        if (selectedDay.isAtSameMomentAs(today)) {
          return 'Hôm nay';
        } else {
          return 'Ngày ${startDate.day}/${startDate.month}/${startDate.year}';
        }

      case DateRangeType.week:
        final now = DateTime.now();
        final thisWeekStart = now.subtract(Duration(days: now.weekday - 1));
        final startOfThisWeek = DateTime(
          thisWeekStart.year,
          thisWeekStart.month,
          thisWeekStart.day,
        );

        if (startDate.isAtSameMomentAs(startOfThisWeek)) {
          return 'Tuần này';
        } else {
          return 'Tuần từ ${startDate.day}/${startDate.month} đến ${endDate.day}/${endDate.month}/${endDate.year}';
        }

      case DateRangeType.month:
        final now = DateTime.now();
        final thisMonth = DateTime(now.year, now.month, 1);

        if (startDate.year == thisMonth.year &&
            startDate.month == thisMonth.month) {
          return 'Tháng này';
        } else {
          return 'Tháng ${startDate.month}/${startDate.year}';
        }

      case DateRangeType.year:
        final now = DateTime.now();

        if (startDate.year == now.year) {
          return 'Năm nay';
        } else {
          return 'Năm ${startDate.year}';
        }

      case DateRangeType.custom:
        return 'Từ ${startDate.day}/${startDate.month}/${startDate.year} đến ${endDate.day}/${endDate.month}/${endDate.year}';
    }
  }
}
