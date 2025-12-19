/// Màn hình thông tin cá nhân người dùng
/// Cho phép người dùng:
/// - Xem thông tin cá nhân hiện tại
/// - Cập nhật ảnh đại diện
/// - Chỉnh sửa tên người dùng và số điện thoại
/// - Lưu các thay đổi vào cơ sở dữ liệu
// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';

class ProfileScreen extends StatefulWidget {
  static const routeName = '/profile';

  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Key để quản lý form
  final _formKey = GlobalKey<FormState>();
  // Controller cho các trường nhập liệu
  late TextEditingController _usernameController;
  late TextEditingController _phoneController;
  // File ảnh đại diện được chọn
  File? _imageFile;
  // Instance của ImagePicker để chọn ảnh
  final _picker = ImagePicker();
  // Trạng thái loading khi đang cập nhật thông tin
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Khởi tạo giá trị ban đầu cho các controller từ thông tin người dùng hiện tại
    final user = context.read<AuthProvider>().currentUser;
    _usernameController = TextEditingController(text: user?.username ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    // Giải phóng bộ nhớ khi widget bị hủy
    _usernameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Chọn ảnh từ thư viện
  /// Sử dụng ImagePicker để chọn ảnh và cập nhật _imageFile
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  /// Lưu thông tin cá nhân đã cập nhật
  /// - Kiểm tra tính hợp lệ của form
  /// - Cập nhật thông tin người dùng
  /// - Xử lý ảnh đại diện
  /// - Lưu vào cơ sở dữ liệu
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      setState(() => _isLoading = false);
      return;
    }

    String? avatarPath = currentUser.avatar;
    if (_imageFile != null) {
      // Trong thực tế, bạn sẽ upload ảnh lên Firebase Storage và lấy URL
      // Ở đây, để đơn giản, chúng ta chỉ lưu đường dẫn local (không hoạt động trên nhiều thiết bị)
      avatarPath = _imageFile!.path;
    }

    // Sử dụng hàm copyWith đã tạo trong model
    final updatedUser = currentUser.copyWith(
      username: _usernameController.text.trim(),
      phone: _phoneController.text.trim(),
      avatar: avatarPath,
    );

    try {
      // [SỬA LỖI] Gọi hàm mới trong AuthProvider
      await authProvider.updateUserProfile(updatedUser);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật thông tin thành công'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(); // Quay lại màn hình trước
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cập nhật thất bại: $e'),
            backgroundColor: Colors.red,
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
    // Dùng watch để UI tự cập nhật khi thông tin người dùng thay đổi
    final user = context.watch<AuthProvider>().currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Vui lòng đăng nhập để xem thông tin')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Thông tin tài khoản')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Phần hiển thị và chọn ảnh đại diện
              Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage:
                        _imageFile != null
                            ? FileImage(_imageFile!)
                            : (user.avatar != null
                                    ? FileImage(File(user.avatar!))
                                    : null)
                                as ImageProvider?,
                    child:
                        user.avatar == null && _imageFile == null
                            ? const Icon(Icons.person, size: 50)
                            : null,
                  ),
                  // Nút chọn ảnh
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: IconButton(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.camera_alt),
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Hiển thị tên người dùng
              Text(
                'Xin chào, ${user.username}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              // Trường nhập tên người dùng
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Tên người dùng',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Vui lòng nhập tên người dùng'
                            : null,
              ),
              const SizedBox(height: 16),
              // Trường nhập số điện thoại
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),
              // Nút lưu thay đổi
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child:
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Lưu thay đổi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
