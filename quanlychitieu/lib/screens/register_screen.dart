/// Màn hình đăng ký tài khoản
/// Cho phép người dùng:
/// - Nhập thông tin đăng ký (email, tên người dùng, mật khẩu)
/// - Kiểm tra tính hợp lệ của thông tin
/// - Gửi yêu cầu đăng ký đến server
/// - Xử lý các trường hợp lỗi và hiển thị thông báo
// lib/screens/register_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  // [SỬA LỖI] Đổi tên lớp State thành public
  RegisterScreenState createState() => RegisterScreenState();
}

//Đổi tên lớp State thành public
class RegisterScreenState extends State<RegisterScreen> {
  // Key để quản lý form
  final _formKey = GlobalKey<FormState>();
  // Controller cho các trường nhập liệu
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  // Trạng thái loading khi đang xử lý đăng ký
  bool _isLoading = false;

  /// Xử lý sự kiện khi người dùng nhấn nút đăng ký
  /// - Kiểm tra tính hợp lệ của form
  /// - Gọi API đăng ký thông qua AuthProvider
  /// - Xử lý kết quả và hiển thị thông báo
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isLoading) {
      return;
    }
    setState(() => _isLoading = true);

    try {
      await context.read<AuthProvider>().signup(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _usernameController.text.trim(),
      );

      if (mounted) {
        // Pop màn hình đăng ký để quay lại màn hình đăng nhập
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đăng ký thất bại: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    // Giải phóng bộ nhớ khi widget bị hủy
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Trường nhập email
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator:
                      (value) =>
                          value!.isEmpty || !value.contains('@')
                              ? 'Email không hợp lệ'
                              : null,
                ),
                const SizedBox(height: 16),
                // Trường nhập tên người dùng
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên người dùng',
                    border: OutlineInputBorder(),
                  ),
                  validator:
                      (value) =>
                          value!.isEmpty
                              ? 'Vui lòng nhập tên người dùng'
                              : null,
                ),
                const SizedBox(height: 16),
                // Trường nhập mật khẩu
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Mật khẩu',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator:
                      (value) =>
                          value!.length < 6
                              ? 'Mật khẩu phải có ít nhất 6 ký tự'
                              : null,
                ),
                const SizedBox(height: 24),
                // Nút đăng ký
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child:
                      _isLoading
                          ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                          : const Text('Đăng ký'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
