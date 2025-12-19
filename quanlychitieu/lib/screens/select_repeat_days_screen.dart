/// Màn hình chọn ngày lặp lại cho nhắc nhở
/// Cho phép người dùng chọn các ngày trong tuần để lặp lại nhắc nhở
/// Sử dụng giá trị số từ 1-7 tương ứng với Thứ Hai đến Chủ Nhật
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SelectRepeatDaysScreen extends StatefulWidget {
  /// Danh sách các ngày trong tuần đã được chọn ban đầu
  /// Giá trị từ 1-7 tương ứng với Thứ Hai đến Chủ Nhật
  final List<int> initialSelectedWeekdays;

  const SelectRepeatDaysScreen({
    super.key,
    required this.initialSelectedWeekdays,
  });

  @override
  State<SelectRepeatDaysScreen> createState() => _SelectRepeatDaysScreenState();
}

class _SelectRepeatDaysScreenState extends State<SelectRepeatDaysScreen> {
  /// Danh sách các ngày trong tuần hiện tại được chọn
  late List<int> _selectedWeekdays;

  /// Danh sách tên các ngày trong tuần bằng tiếng Việt
  /// Thứ tự từ Thứ Hai đến Chủ Nhật
  final List<String> _weekdayNames = [
    'Thứ Hai',
    'Thứ Ba',
    'Thứ Tư',
    'Thứ Năm',
    'Thứ Sáu',
    'Thứ Bảy',
    'Chủ Nhật',
  ];

  @override
  void initState() {
    super.initState();
    // Khởi tạo danh sách ngày được chọn từ giá trị ban đầu
    _selectedWeekdays = List<int>.from(widget.initialSelectedWeekdays);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lặp lại'),
        actions: [
          // Nút xác nhận lựa chọn
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              // Trả về danh sách ngày đã chọn khi người dùng xác nhận
              Navigator.of(context).pop(_selectedWeekdays);
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _weekdayNames.length,
        itemBuilder: (context, index) {
          // Chuyển đổi index thành giá trị ngày (1-7)
          // Thứ Hai là 1, Chủ Nhật là 7
          final weekdayValue = index + 1;
          return CheckboxListTile(
            title: Text(_weekdayNames[index]),
            value: _selectedWeekdays.contains(weekdayValue),
            onChanged: (bool? selected) {
              setState(() {
                if (selected == true) {
                  // Thêm ngày vào danh sách nếu được chọn
                  _selectedWeekdays.add(weekdayValue);
                } else {
                  // Xóa ngày khỏi danh sách nếu bỏ chọn
                  _selectedWeekdays.remove(weekdayValue);
                }
                // Sắp xếp danh sách để đảm bảo tính nhất quán
                _selectedWeekdays.sort();
              });
            },
          );
        },
      ),
    );
  }
}
