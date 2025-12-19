// Widget DateRangeSelector - Cho phép người dùng chọn khoảng thời gian để xem dữ liệu chi tiêu
// Hỗ trợ các chế độ: Ngày, Tuần, Tháng, Năm và Tùy chỉnh

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/date_range.dart';
import '../providers/date_range_provider.dart';

/// Widget chính cho phép chọn khoảng thời gian
/// Hiển thị các nút chọn thời gian và xử lý logic chọn ngày
class DateRangeSelector extends StatelessWidget {
  const DateRangeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final dateRangeProvider = Provider.of<DateRangeProvider>(context);
    final currentRange = dateRangeProvider.currentRange;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hiển thị tiêu đề và khoảng thời gian hiện tại
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Icon(Icons.date_range, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Khoảng thời gian: ${currentRange.displayText}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Thanh cuộn ngang chứa các nút chọn thời gian
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Các nút chọn thời gian với icon calendar
                  _buildRangeButtonWithIcon(
                    context,
                    label: 'Ngày',
                    type: DateRangeType.day,
                    provider: dateRangeProvider,
                    isSelected: currentRange.type == DateRangeType.day,
                    onIconTap: () => _pickDay(context, dateRangeProvider),
                  ),
                  const SizedBox(width: 8),
                  _buildRangeButtonWithIcon(
                    context,
                    label: 'Tuần',
                    type: DateRangeType.week,
                    provider: dateRangeProvider,
                    isSelected: currentRange.type == DateRangeType.week,
                    onIconTap: () => _pickWeek(context, dateRangeProvider),
                  ),
                  const SizedBox(width: 8),
                  _buildRangeButtonWithIcon(
                    context,
                    label: 'Tháng',
                    type: DateRangeType.month,
                    provider: dateRangeProvider,
                    isSelected: currentRange.type == DateRangeType.month,
                    onIconTap: () => _pickMonth(context, dateRangeProvider),
                  ),
                  const SizedBox(width: 8),
                  _buildRangeButtonWithIcon(
                    context,
                    label: 'Năm',
                    type: DateRangeType.year,
                    provider: dateRangeProvider,
                    isSelected: currentRange.type == DateRangeType.year,
                    onIconTap: () => _pickYear(context, dateRangeProvider),
                  ),
                  const SizedBox(width: 8),
                  _buildRangeButtonWithIcon(
                    context,
                    label: 'Tùy chọn',
                    type: DateRangeType.custom,
                    provider: dateRangeProvider,
                    isSelected: currentRange.type == DateRangeType.custom,
                    onIconTap:
                        () => _pickCustomRange(context, dateRangeProvider),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Xây dựng nút chọn thời gian với icon calendar
  /// [label] - Nhãn hiển thị trên nút
  /// [type] - Loại khoảng thời gian
  /// [provider] - Provider quản lý trạng thái
  /// [isSelected] - Trạng thái được chọn
  /// [onIconTap] - Callback khi nhấn vào icon
  Widget _buildRangeButtonWithIcon(
    BuildContext context, {
    required String label,
    required DateRangeType type,
    required DateRangeProvider provider,
    required bool isSelected,
    required VoidCallback onIconTap,
  }) {
    return Row(
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade200,
            foregroundColor: isSelected ? Colors.white : Colors.black87,
            elevation: isSelected ? 4 : 1,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          onPressed: () => provider.setDateRangeType(type),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.calendar_today, size: 20, color: Colors.blue),
          tooltip: 'Chọn $label',
          onPressed: onIconTap,
        ),
      ],
    );
  }

  /// Chọn một ngày cụ thể
  /// Hiển thị date picker và cập nhật khoảng thời gian
  void _pickDay(BuildContext context, DateRangeProvider provider) async {
    final now = DateTime.now();
    final initialDate =
        provider.currentRange.type == DateRangeType.day
            ? provider.currentRange.startDate
            : now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(now) ? initialDate : now,
      firstDate: DateTime(2020),
      lastDate: now,
    );

    if (picked != null && context.mounted) {
      // Ngày bắt đầu và kết thúc là cùng một ngày
      final start = DateTime(picked.year, picked.month, picked.day);
      final end = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);

      provider.setCustomRangeWithType(start, end, DateRangeType.day);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã chọn ngày: ${DateFormat('dd/MM/yyyy').format(start)}',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Chọn một tuần cụ thể
  /// Tự động tính toán ngày đầu tuần (thứ 2) và ngày cuối tuần (chủ nhật)
  void _pickWeek(BuildContext context, DateRangeProvider provider) async {
    final now = DateTime.now();
    final initialDate =
        provider.currentRange.type == DateRangeType.week
            ? provider.currentRange.startDate
            : now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(now) ? initialDate : now,
      firstDate: DateTime(2020),
      lastDate: now,
    );

    if (picked != null && context.mounted) {
      // Tìm ngày đầu tuần (thứ 2)
      final start = picked.subtract(Duration(days: picked.weekday - 1));
      // Tìm ngày cuối tuần (chủ nhật)
      final end = start.add(
        const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
      );

      // Nếu tuần vượt quá ngày hiện tại, giới hạn lại
      final adjustedEnd = end.isAfter(now) ? now : end;

      provider.setCustomRangeWithType(start, adjustedEnd, DateRangeType.week);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã chọn tuần từ ${DateFormat('dd/MM/yyyy').format(start)} đến ${DateFormat('dd/MM/yyyy').format(adjustedEnd)}',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Chọn một tháng cụ thể
  /// Sử dụng custom month picker để chọn tháng và năm
  void _pickMonth(BuildContext context, DateRangeProvider provider) async {
    final now = DateTime.now();
    final initialDate =
        provider.currentRange.type == DateRangeType.month
            ? provider.currentRange.startDate
            : now;

    final picked = await showMonthPicker(
      context: context,
      initialDate: initialDate,
      lastDate: now,
    );

    if (picked != null && context.mounted) {
      // Ngày đầu tháng
      final start = DateTime(picked.year, picked.month, 1);
      // Ngày cuối tháng
      final lastDayOfMonth = DateTime(
        picked.year,
        picked.month + 1,
        0,
        23,
        59,
        59,
      );
      // Nếu tháng vượt quá ngày hiện tại, giới hạn lại
      final end = lastDayOfMonth.isAfter(now) ? now : lastDayOfMonth;

      provider.setCustomRangeWithType(start, end, DateRangeType.month);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã chọn tháng ${picked.month}/${picked.year}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Chọn một năm cụ thể
  /// Sử dụng custom year picker để chọn năm
  void _pickYear(BuildContext context, DateRangeProvider provider) async {
    final now = DateTime.now();
    final initialYear =
        provider.currentRange.type == DateRangeType.year
            ? provider.currentRange.startDate.year
            : now.year;

    final picked = await showYearPicker(
      context: context,
      initialDate: DateTime(initialYear),
      firstDate: DateTime(2020),
      lastDate: now,
    );

    if (picked != null && context.mounted) {
      // Ngày đầu năm
      final start = DateTime(picked.year, 1, 1);
      // Ngày cuối năm
      final lastDayOfYear = DateTime(picked.year, 12, 31, 23, 59, 59);
      // Nếu năm hiện tại, giới hạn đến ngày hiện tại
      final end = picked.year == now.year ? now : lastDayOfYear;

      provider.setCustomRangeWithType(start, end, DateRangeType.year);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã chọn năm ${picked.year}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Chọn khoảng thời gian tùy chỉnh
  /// Cho phép người dùng chọn ngày bắt đầu và kết thúc tự do
  void _pickCustomRange(
    BuildContext context,
    DateRangeProvider provider,
  ) async {
    final now = DateTime.now();
    final initialDateRange = DateTimeRange(
      start: provider.currentRange.startDate,
      end:
          provider.currentRange.endDate.isAfter(now)
              ? now
              : provider.currentRange.endDate,
    );

    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: initialDateRange,
      firstDate: DateTime(2020),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && context.mounted) {
      provider.setCustomRangeWithType(
        picked.start,
        picked.end,
        DateRangeType.custom,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã chọn từ ${DateFormat('dd/MM/yyyy').format(picked.start)} đến ${DateFormat('dd/MM/yyyy').format(picked.end)}',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Hiển thị dialog chọn năm
  /// Custom widget để chọn năm với giới hạn từ 2020 đến năm hiện tại
  Future<DateTime?> showYearPicker({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    DateTime? selectedDate;
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Chọn năm'),
          content: SizedBox(
            width: 300,
            height: 300,
            child: YearPicker(
              firstDate: firstDate,
              lastDate: lastDate,
              selectedDate: initialDate,
              onChanged: (DateTime yearDate) {
                selectedDate = yearDate;
                Navigator.of(context).pop();
              },
            ),
          ),
        );
      },
    );
    return selectedDate;
  }
}

/// Custom widget để chọn tháng
/// Cho phép chọn tháng và năm với giới hạn không cho chọn tháng trong tương lai
Future<DateTime?> showMonthPicker({
  required BuildContext context,
  required DateTime initialDate,
  DateTime? lastDate,
}) async {
  final now = lastDate ?? DateTime.now();
  return showDialog<DateTime>(
    context: context,
    builder: (context) {
      int selectedYear = initialDate.year;
      int selectedMonth = initialDate.month;
      return AlertDialog(
        title: const Text('Chọn tháng'),
        content: SizedBox(
          width: 300,
          height: 250,
          child: Column(
            children: [
              // Chọn năm với nút tăng/giảm
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_left),
                    onPressed: () {
                      if (selectedYear > 2020) {
                        selectedYear--;
                        (context as Element).markNeedsBuild();
                      }
                    },
                  ),
                  Text('$selectedYear', style: const TextStyle(fontSize: 18)),
                  IconButton(
                    icon: const Icon(Icons.arrow_right),
                    onPressed: () {
                      if (selectedYear < now.year) {
                        selectedYear++;
                        (context as Element).markNeedsBuild();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Hiển thị lưới 12 tháng
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(12, (index) {
                  final month = index + 1;
                  final isFutureMonth =
                      (selectedYear > now.year) ||
                      (selectedYear == now.year && month > now.month);
                  return GestureDetector(
                    onTap:
                        isFutureMonth
                            ? null
                            : () {
                              Navigator.of(
                                context,
                              ).pop(DateTime(selectedYear, month));
                            },
                    child: Container(
                      width: 60,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color:
                            isFutureMonth
                                ? Colors.grey.shade300
                                : month == selectedMonth
                                ? Colors.blue
                                : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$month',
                        style: TextStyle(
                          color:
                              isFutureMonth
                                  ? Colors.grey
                                  : month == selectedMonth
                                  ? Colors.white
                                  : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      );
    },
  );
}
