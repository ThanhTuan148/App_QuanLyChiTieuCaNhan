/// Màn hình chọn âm thanh cho nhắc nhở
/// Cho phép người dùng chọn từ danh sách các âm thanh có sẵn
/// hoặc tắt âm thanh cho nhắc nhở
import 'package:flutter/material.dart';

class SelectSoundScreen extends StatefulWidget {
  /// Âm thanh được chọn ban đầu
  final String initialSound;

  const SelectSoundScreen({super.key, required this.initialSound});

  @override
  State<SelectSoundScreen> createState() => _SelectSoundScreenState();
}

class _SelectSoundScreenState extends State<SelectSoundScreen> {
  /// Âm thanh hiện tại được chọn
  late String _selectedSound;

  /// Danh sách các âm thanh có sẵn
  /// Bao gồm:
  /// - Mặc định: Âm thanh mặc định của hệ thống
  /// - Không có: Tắt âm thanh
  /// - Còi báo động ngắn: Âm thanh báo động ngắn
  /// - Báo động Hy Lạp: Âm thanh báo động kiểu Hy Lạp
  /// - Báo động Thái Lan: Âm thanh báo động kiểu Thái Lan
  final List<String> _availableSounds = [
    'Mặc định',
    'Không có',
    'Còi báo động ngắn',
    'Báo động Hy Lạp',
    'Báo động Thái Lan',
  ];

  @override
  void initState() {
    super.initState();
    // Khởi tạo âm thanh được chọn từ giá trị ban đầu
    _selectedSound = widget.initialSound;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Âm thanh'),
        actions: [
          // Nút xác nhận lựa chọn
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              // Trả về âm thanh đã chọn khi người dùng xác nhận
              Navigator.of(context).pop(_selectedSound);
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _availableSounds.length,
        itemBuilder: (context, index) {
          final soundName = _availableSounds[index];
          return RadioListTile<String>(
            title: Text(soundName),
            value: soundName,
            groupValue: _selectedSound,
            onChanged: (String? value) {
              setState(() {
                if (value != null) {
                  _selectedSound = value;
                }
              });
            },
          );
        },
      ),
    );
  }
}
