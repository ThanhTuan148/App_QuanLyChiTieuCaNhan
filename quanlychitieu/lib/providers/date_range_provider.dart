/// Provider quản lý khoảng thời gian được chọn để xem dữ liệu chi tiêu.
/// Cung cấp các phương thức để thiết lập nhanh các khoảng thời gian phổ biến (Hôm nay, Tuần này, Tháng này, Năm nay)
/// và hỗ trợ tùy chỉnh khoảng thời gian.
import 'package:flutter/material.dart';
import '../models/date_range.dart';

/// `DateRangeProvider` quản lý và thông báo các thay đổi về khoảng thời gian hiện tại.
/// Nó lưu trữ khoảng thời gian đang được chọn và các khoảng thời gian tùy chỉnh đã sử dụng trước đó.
class DateRangeProvider with ChangeNotifier {
  /// Khoảng thời gian hiện tại đang được chọn và hiển thị.
  DateRange _currentRange = DateRange.thisMonth(); // Mặc định là tháng hiện tại

  /// Map lưu trữ các khoảng thời gian tùy chỉnh đã chọn theo loại `DateRangeType`.
  /// Điều này giúp khôi phục các lựa chọn tùy chỉnh trước đó.
  final Map<DateRangeType, DateRange> _customRanges =
      {}; // Lưu các khoảng thời gian đã chọn theo loại

  /// Getter trả về khoảng thời gian hiện tại.
  DateRange get currentRange => _currentRange;

  /// Thiết lập khoảng thời gian hiện tại là 'Hôm nay'.
  /// Lưu lại khoảng thời gian này vào `_customRanges` và thông báo cho các listener.
  void setToday() {
    _currentRange = DateRange.today();
    _customRanges[DateRangeType.day] = _currentRange;
    notifyListeners();
  }

  /// Thiết lập khoảng thời gian hiện tại là 'Tuần này'.
  /// Lưu lại khoảng thời gian này vào `_customRanges` và thông báo cho các listener.
  void setThisWeek() {
    _currentRange = DateRange.thisWeek();
    _customRanges[DateRangeType.week] = _currentRange;
    notifyListeners();
  }

  /// Thiết lập khoảng thời gian hiện tại là 'Tháng này'.
  /// Lưu lại khoảng thời gian này vào `_customRanges` và thông báo cho các listener.
  void setThisMonth() {
    _currentRange = DateRange.thisMonth();
    _customRanges[DateRangeType.month] = _currentRange;
    notifyListeners();
  }

  /// Thiết lập khoảng thời gian hiện tại là 'Năm này'.
  /// Lưu lại khoảng thời gian này vào `_customRanges` và thông báo cho các listener.
  void setThisYear() {
    _currentRange = DateRange.thisYear();
    _customRanges[DateRangeType.year] = _currentRange;
    notifyListeners();
  }

  /// Thiết lập khoảng thời gian tùy chỉnh với ngày bắt đầu và kết thúc cụ thể.
  /// Lưu lại khoảng thời gian này vào `_customRanges` với loại `custom` và thông báo cho các listener.
  /// @param start Ngày bắt đầu của khoảng thời gian.
  /// @param end Ngày kết thúc của khoảng thời gian.
  void setCustomRange(DateTime start, DateTime end) {
    _currentRange = DateRange.custom(start, end);
    _customRanges[DateRangeType.custom] = _currentRange;
    notifyListeners();
  }

  /// Đặt một khoảng thời gian tùy chỉnh với một loại `DateRangeType` cụ thể.
  /// Thường được sử dụng khi khoảng thời gian tùy chỉnh được chọn lại từ một loại đã lưu.
  /// @param start Ngày bắt đầu của khoảng thời gian.
  /// @param end Ngày kết thúc của khoảng thời gian.
  /// @param type Loại khoảng thời gian (ví dụ: `DateRangeType.month` cho khoảng tháng tùy chỉnh).
  void setCustomRangeWithType(
    DateTime start,
    DateTime end,
    DateRangeType type,
  ) {
    _currentRange = DateRange(type: type, startDate: start, endDate: end);
    _customRanges[type] = _currentRange;
    notifyListeners();
  }

  /// Thiết lập khoảng thời gian hiện tại dựa trên một loại `DateRangeType`.
  /// Nếu loại đó đã có khoảng thời gian tùy chỉnh đã lưu, nó sẽ được sử dụng lại.
  /// Nếu không, một khoảng thời gian mặc định cho loại đó sẽ được tạo.
  /// @param type Loại khoảng thời gian cần thiết lập (ví dụ: `DateRangeType.day`, `DateRangeType.month`).
  void setDateRangeType(DateRangeType type) {
    // Nếu đã có khoảng thời gian tùy chỉnh đã chọn trước đó cho loại này, sử dụng lại.
    if (_customRanges.containsKey(type)) {
      _currentRange = _customRanges[type]!;
      notifyListeners();
      return;
    }

    // Nếu chưa có, thiết lập khoảng thời gian mặc định cho loại đó.
    switch (type) {
      case DateRangeType.day:
        setToday();
        break;
      case DateRangeType.week:
        setThisWeek();
        break;
      case DateRangeType.month:
        setThisMonth();
        break;
      case DateRangeType.year:
        setThisYear();
        break;
      case DateRangeType.custom:
        // Nếu chưa có khoảng tùy chỉnh nào được lưu, tạo một khoảng mặc định 30 ngày gần nhất.
        final now = DateTime.now();
        setCustomRange(now.subtract(const Duration(days: 30)), now);
        break;
    }
  }
}
