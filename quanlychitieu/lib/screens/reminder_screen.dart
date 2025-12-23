/// Màn hình quản lý nhắc nhở
/// Cho phép người dùng:
/// - Xem danh sách các nhắc nhở
/// - Thêm nhắc nhở mới
/// - Chỉnh sửa nhắc nhở hiện có
/// - Bật/tắt nhắc nhở
/// - Xóa nhắc nhở
// [ĐÃ SỬA LỖI TÊN CLASS] lib/screens/reminder_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/reminder.dart';
import '../providers/reminder_provider.dart';
// [SỬA] Import đúng file màn hình thêm/sửa
import 'add_reminder_screen.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  @override
  void initState() {
    super.initState();
    // Đảm bảo provider được khởi tạo và lắng nghe stream
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final reminderProvider = context.read<ReminderProvider>();
      // Stream sẽ tự động cập nhật, nhưng đảm bảo provider được refresh
      reminderProvider.notifyListeners();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Lấy provider quản lý nhắc nhở
    final reminderProvider = context.watch<ReminderProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Nhắc nhở'),
        actions: [
          // Nút thêm nhắc nhở mới
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              // Điều hướng đến màn hình thêm nhắc nhở và đợi kết quả
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (ctx) => const AddEditReminderScreen(),
                ),
              );
              // Nếu lưu thành công, refresh lại provider
              if (result == true && mounted) {
                // Stream sẽ tự động cập nhật, nhưng đảm bảo UI được refresh
                reminderProvider.notifyListeners();
              }
            },
          ),
        ],
      ),
      body: reminderProvider.reminders.isEmpty
          ? _buildEmptyState(context)
          : RefreshIndicator(
              onRefresh: () async {
                // Stream sẽ tự động cập nhật, nhưng refresh để đảm bảo
                reminderProvider.notifyListeners();
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: ListView.builder(
                itemCount: reminderProvider.reminders.length,
                itemBuilder: (ctx, index) {
                  final reminder = reminderProvider.reminders[index];
                  return _buildReminderCard(context, reminder);
                },
              ),
            ),
    );
  }

  /// Xây dựng UI khi chưa có nhắc nhở nào
  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có nhắc nhở nào',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Thêm nhắc nhở để không bỏ lỡ các khoản chi tiêu quan trọng',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[500],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Thêm nhắc nhở'),
            onPressed: () async {
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (ctx) => const AddEditReminderScreen(),
                ),
              );
              if (result == true && mounted) {
                context.read<ReminderProvider>().notifyListeners();
              }
            },
          ),
        ],
      ),
    );
  }

  /// Xây dựng card hiển thị thông tin nhắc nhở
  ///
  /// Parameters:
  /// - context: BuildContext
  /// - reminder: Đối tượng Reminder cần hiển thị
  Widget _buildReminderCard(BuildContext context, Reminder reminder) {
    final reminderProvider = context.read<ReminderProvider>();
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        // Xử lý sự kiện khi nhấn vào card
        onTap: () {
          // [SỬA] Điều hướng đến đúng tên class AddEditReminderScreen
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => AddEditReminderScreen(reminder: reminder),
            ),
          );
        },
        // Tiêu đề nhắc nhở
        title: Text(
          reminder.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        // Nội dung chi tiết nhắc nhở
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(reminder.content),
            const SizedBox(height: 4),
            Text(
              'Lúc: ${DateFormat('HH:mm - dd/MM/yyyy').format(reminder.scheduledTime)}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        // Nút bật/tắt nhắc nhở
        trailing: Switch(
          value: reminder.isActive,
          onChanged: (value) {
            // [SỬA] Gọi đúng hàm updateReminderStatus
            reminderProvider.updateReminderStatus(reminder, value);
          },
        ),
        // Xử lý sự kiện khi giữ lâu vào card
        onLongPress: () => _showDeleteConfirmation(context, reminder.id!),
      ),
    );
  }

  /// Hiển thị dialog xác nhận xóa nhắc nhở
  ///
  /// Parameters:
  /// - context: BuildContext
  /// - reminderId: ID của nhắc nhở cần xóa
  void _showDeleteConfirmation(BuildContext context, String reminderId) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Xác nhận xóa'),
            content: const Text('Bạn có chắc muốn xóa nhắc nhở này?'),
            actions: [
              // Nút hủy xóa
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Hủy'),
              ),
              // Nút xác nhận xóa
              TextButton(
                onPressed: () {
                  context.read<ReminderProvider>().deleteReminder(reminderId);
                  Navigator.of(ctx).pop();
                },
                child: const Text('Xóa', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }
}
