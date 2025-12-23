/// Màn hình thêm/sửa nhắc nhở
/// Cho phép người dùng:
/// - Thêm mới hoặc chỉnh sửa nhắc nhở
/// - Thiết lập tiêu đề và nội dung
/// - Chọn thời gian nhắc nhở
/// - Cấu hình tần suất lặp lại (một lần/hàng ngày/hàng tuần/hàng tháng)
/// - Chọn các ngày lặp lại trong tuần
/// - Chọn loại thông báo và âm thanh
/// - Gán nhắc nhở với danh mục
/// - Bật/tắt trạng thái hoạt động
// [HOÀN THIỆN] lib/screens/add_edit_reminder_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/reminder.dart';
import '../providers/reminder_provider.dart';
import '../providers/auth_provider.dart';
import '../models/category.dart' as app_category;
import '../providers/category_provider.dart';
import '../utils/category_emoji_mapper.dart';
import 'select_repeat_days_screen.dart';
import 'select_sound_screen.dart';

class AddEditReminderScreen extends StatefulWidget {
  /// Nhắc nhở cần chỉnh sửa (null nếu là thêm mới)
  final Reminder? reminder;

  const AddEditReminderScreen({super.key, this.reminder});

  @override
  State<AddEditReminderScreen> createState() => _AddEditReminderScreenState();
}

class _AddEditReminderScreenState extends State<AddEditReminderScreen> {
  /// Key để quản lý form
  final _formKey = GlobalKey<FormState>();

  /// Controller cho các trường nhập liệu
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  /// Thời gian đã lên lịch cho nhắc nhở
  late DateTime _scheduledTime;

  /// ID của danh mục được chọn
  String? _selectedCategoryId;

  /// Trạng thái hoạt động của nhắc nhở
  late bool _isActive;

  /// Tần suất lặp lại (once/daily/weekly/monthly)
  late String _selectedFrequency;

  /// Danh sách các ngày trong tuần được chọn (1-7)
  late List<int> _selectedWeekdays;

  /// Loại thông báo (Thông báo/Báo thức)
  late String _selectedNotificationType;

  /// Âm thanh thông báo
  late String _selectedSound;

  /// Trạng thái đang xử lý
  bool _isLoading = false;

  /// Kiểm tra xem có đang ở chế độ chỉnh sửa không
  bool get _isEditing => widget.reminder != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      // Khởi tạo dữ liệu từ nhắc nhở cần chỉnh sửa
      final r = widget.reminder!;
      _titleController = TextEditingController(text: r.title);
      _contentController = TextEditingController(text: r.content);
      _scheduledTime = r.scheduledTime;
      _isActive = r.isActive;
      _selectedCategoryId = r.categoryId;
      _selectedFrequency = r.frequency;
      _selectedWeekdays = List<int>.from(r.weekdays);
      _selectedNotificationType = r.notificationType;
      _selectedSound = r.sound;
    } else {
      // Khởi tạo giá trị mặc định cho nhắc nhở mới
      _titleController = TextEditingController();
      _contentController = TextEditingController();
      _scheduledTime = DateTime.now().add(const Duration(minutes: 5));
      _isActive = true;
      _selectedCategoryId = null;
      _selectedFrequency = 'once';
      _selectedWeekdays = [];
      _selectedNotificationType = 'Thông báo';
      _selectedSound = 'Mặc định';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  /// Hiển thị dialog chọn ngày và giờ
  Future<void> _presentDateTimePicker() async {
    final DateTime now = DateTime.now();
    final DateTime initialDatePickerDate =
        (_isEditing && _scheduledTime.isAfter(now)) ? _scheduledTime : now;

    // Chọn ngày
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate:
          initialDatePickerDate.isBefore(now) ? now : initialDatePickerDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      if (!mounted) return;
      // Chọn giờ
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_scheduledTime),
      );
      if (pickedTime != null) {
        setState(() {
          final DateTime newScheduledTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          // Kiểm tra và xử lý thời gian trong quá khứ
          if (newScheduledTime.isBefore(now)) {
            _scheduledTime = now.add(const Duration(minutes: 1));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Không thể chọn thời gian trong quá khứ. Đã tự động đặt sau 1 phút.',
                ),
              ),
            );
          } else {
            _scheduledTime = newScheduledTime;
          }
        });
      }
    }
  }

  /// Lưu nhắc nhở vào cơ sở dữ liệu
  Future<void> _saveReminder() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn một danh mục')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Kiểm tra đăng nhập
    final authProvider = context.read<AuthProvider>();
    if (authProvider.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi: Người dùng chưa đăng nhập.')),
      );
      setState(() => _isLoading = false);
      return;
    }

    // Tạo đối tượng nhắc nhở mới
    final newReminder = Reminder(
      id: widget.reminder?.id,
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      scheduledTime: _scheduledTime,
      frequency: _selectedFrequency,
      weekdays: _selectedFrequency == 'weekly' ? _selectedWeekdays : [],
      day: _selectedFrequency == 'monthly' ? _scheduledTime.day : null,
      isActive: _isActive,
      userId: authProvider.currentUser!.id,
      categoryId: _selectedCategoryId!,
      notificationType: _selectedNotificationType,
      sound: _selectedSound,
    );

    try {
      // Lưu nhắc nhở
      await context.read<ReminderProvider>().saveReminder(newReminder);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isEditing 
                        ? 'Đã cập nhật nhắc nhở thành công!' 
                        : 'Đã thêm nhắc nhở thành công!',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Đợi một chút để đảm bảo stream đã cập nhật
        await Future.delayed(const Duration(milliseconds: 300));
        Navigator.of(context).pop(true); // Trả về true để báo hiệu đã lưu thành công
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Lưu thất bại: $e',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();
    final List<app_category.Category> categories = categoryProvider.categories;

    // Tự động chọn danh mục đầu tiên nếu chưa có danh mục nào được chọn
    if (_selectedCategoryId == null && categories.isNotEmpty) {
      _selectedCategoryId = categories.first.id;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Sửa Nhắc nhở' : 'Thêm Nhắc nhở'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveReminder),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Trường nhập tiêu đề
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Tiêu đề'),
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? 'Vui lòng nhập tiêu đề'
                              : null,
                ),
                const SizedBox(height: 16),
                // Trường nhập nội dung
                TextFormField(
                  controller: _contentController,
                  decoration: const InputDecoration(labelText: 'Nội dung'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                // Hiển thị và chọn thời gian
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Thời gian: ${DateFormat('dd/MM/yyyy HH:mm').format(_scheduledTime)}',
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: _presentDateTimePicker,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Chọn tần suất lặp lại
                DropdownButtonFormField<String>(
                  value: _selectedFrequency,
                  decoration: const InputDecoration(
                    labelText: 'Tần suất lặp lại',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'once', child: Text('Một lần')),
                    DropdownMenuItem(value: 'daily', child: Text('Hàng ngày')),
                    DropdownMenuItem(value: 'weekly', child: Text('Hàng tuần')),
                    DropdownMenuItem(
                      value: 'monthly',
                      child: Text('Hàng tháng'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedFrequency = value!;
                      if (_selectedFrequency != 'weekly') {
                        _selectedWeekdays = [];
                      }
                    });
                  },
                ),
                // Hiển thị chọn ngày lặp lại nếu tần suất là hàng tuần
                if (_selectedFrequency == 'weekly') ...[
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Lặp lại'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_getWeekdaysDisplay()),
                        const Icon(Icons.arrow_forward_ios),
                      ],
                    ),
                    onTap: () async {
                      final List<int>? result = await Navigator.of(
                        context,
                      ).push<List<int>>(
                        MaterialPageRoute(
                          builder:
                              (ctx) => SelectRepeatDaysScreen(
                                initialSelectedWeekdays: _selectedWeekdays,
                              ),
                        ),
                      );
                      if (result != null) {
                        setState(() => _selectedWeekdays = result);
                      }
                    },
                  ),
                ],
                const SizedBox(height: 16),
                // Chọn loại thông báo
                DropdownButtonFormField<String>(
                  value: _selectedNotificationType,
                  decoration: const InputDecoration(
                    labelText: 'Loại thông báo',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Thông báo',
                      child: Text('Thông báo'),
                    ),
                    DropdownMenuItem(
                      value: 'Báo thức',
                      child: Text('Báo thức'),
                    ),
                  ],
                  onChanged:
                      (value) =>
                          setState(() => _selectedNotificationType = value!),
                ),
                const SizedBox(height: 16),
                // Chọn âm thanh
                ListTile(
                  title: const Text('Âm thanh'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_selectedSound),
                      const Icon(Icons.arrow_forward_ios),
                    ],
                  ),
                  onTap: () async {
                    final String? result = await Navigator.of(
                      context,
                    ).push<String?>(
                      MaterialPageRoute(
                        builder:
                            (ctx) =>
                                SelectSoundScreen(initialSound: _selectedSound),
                      ),
                    );
                    if (result != null) setState(() => _selectedSound = result);
                  },
                ),
                const SizedBox(height: 16),
                // Chọn danh mục
                if (categories.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: _selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Danh mục',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        categories.map((category) {
                          return DropdownMenuItem(
                            value: category.id,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: category.color,
                                  radius: 12,
                                  child: Text(
                                    CategoryEmojiMapper.getEmojiForIcon(category.icon),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(category.name),
                              ],
                            ),
                          );
                        }).toList(),
                    onChanged:
                        (value) => setState(() => _selectedCategoryId = value),
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Vui lòng chọn danh mục'
                                : null,
                  )
                else
                  const Center(child: Text('Vui lòng tạo danh mục trước.')),
                const SizedBox(height: 16),
                // Bật/tắt nhắc nhở
                SwitchListTile(
                  title: const Text('Bật nhắc nhở'),
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Chuyển đổi danh sách ngày trong tuần thành chuỗi hiển thị
  String _getWeekdaysDisplay() {
    if (_selectedWeekdays.isEmpty) return 'Không có';
    _selectedWeekdays.sort();
    final List<String> weekdayNames = [
      'T2',
      'T3',
      'T4',
      'T5',
      'T6',
      'T7',
      'CN',
    ];
    return _selectedWeekdays.map((day) => weekdayNames[day - 1]).join(', ');
  }
}
