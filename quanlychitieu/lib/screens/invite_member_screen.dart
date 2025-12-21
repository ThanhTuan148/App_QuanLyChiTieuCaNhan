/// Màn hình mời thành viên vào nhóm
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../providers/group_provider.dart';
import '../models/group.dart';

class InviteMemberScreen extends StatefulWidget {
  final Group group;

  const InviteMemberScreen({super.key, required this.group});

  @override
  State<InviteMemberScreen> createState() => _InviteMemberScreenState();
}

class _InviteMemberScreenState extends State<InviteMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  GroupMemberRole _selectedRole = GroupMemberRole.viewer;
  bool _isLoading = false;
  String? _invitationCode;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _inviteMember() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _invitationCode = null;
    });

    final groupProvider = context.read<GroupProvider>();
    try {
      final code = await groupProvider.inviteMember(
        groupId: widget.group.id!,
        email: _emailController.text.trim(),
        role: _selectedRole,
      );

      setState(() {
        _invitationCode = code;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mã mời đã được tạo!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  void _copyInvitationCode() {
    if (_invitationCode != null) {
      Clipboard.setData(ClipboardData(text: _invitationCode!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã sao chép mã mời!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mời thành viên'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Mời thành viên vào nhóm "${widget.group.name}"',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  hintText: 'email@example.com',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập email';
                  }
                  if (!value.contains('@')) {
                    return 'Email không hợp lệ';
                  }
                  return null;
                },
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              const Text(
                'Vai trò',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...GroupMemberRole.values.map((role) {
                return RadioListTile<GroupMemberRole>(
                  title: Text(_getRoleName(role)),
                  subtitle: Text(_getRoleDescription(role)),
                  value: role,
                  groupValue: _selectedRole,
                  onChanged: _isLoading
                      ? null
                      : (value) => setState(() => _selectedRole = value!),
                );
              }),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _inviteMember,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Tạo mã mời'),
              ),
              if (_invitationCode != null) ...[
                const SizedBox(height: 24),
                Card(
                  color: Colors.green[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 8),
                            Text(
                              'Mã mời đã được tạo',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _invitationCode!,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy),
                                onPressed: _copyInvitationCode,
                                tooltip: 'Sao chép',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Gửi mã này cho người bạn muốn mời. Họ có thể sử dụng mã này để tham gia nhóm.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getRoleName(GroupMemberRole role) {
    switch (role) {
      case GroupMemberRole.admin:
        return 'Quản trị viên';
      case GroupMemberRole.editor:
        return 'Biên tập viên';
      case GroupMemberRole.viewer:
        return 'Người xem';
    }
  }

  String _getRoleDescription(GroupMemberRole role) {
    switch (role) {
      case GroupMemberRole.admin:
        return 'Có quyền cao nhất: phê duyệt, quản lý thành viên, xóa nhóm';
      case GroupMemberRole.editor:
        return 'Có thể thêm, sửa, xóa giao dịch';
      case GroupMemberRole.viewer:
        return 'Chỉ xem, không thể chỉnh sửa';
    }
  }
}

