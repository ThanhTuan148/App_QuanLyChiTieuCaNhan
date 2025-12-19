/// Màn hình đăng nhập
/// Cho phép người dùng:
/// - Đăng nhập bằng email và mật khẩu
/// - Đăng nhập bằng tài khoản Google
/// - Khôi phục mật khẩu qua email
// lib/screens/login_screen.dart

// ignore_for_file: curly_braces_in_flow_control_structures, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Key để quản lý form
  final _formKey = GlobalKey<FormState>();
  // Controller cho các trường nhập liệu
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  // Trạng thái hiển thị/ẩn mật khẩu
  bool _isPasswordVisible = false;
  // Trạng thái loading khi đang xử lý đăng nhập
  bool _isLoading = false;

  @override
  void dispose() {
    // Giải phóng bộ nhớ khi widget bị hủy
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Xử lý sự kiện đăng nhập
  /// - Kiểm tra tính hợp lệ của form
  /// - Gọi API đăng nhập thông qua AuthProvider
  /// - Xử lý kết quả và hiển thị thông báo
  Future<void> _login() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;
    setState(() => _isLoading = true);
    try {
      await context.read<AuthProvider>().login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Đăng nhập thất bại: Sai tài khoản hoặc mật khẩu!',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Hiển thị dialog khôi phục mật khẩu
  /// - Cho phép người dùng nhập email
  /// - Gửi email khôi phục mật khẩu
  /// - Hiển thị thông báo kết quả
  void _showForgotPasswordDialog() {
    final emailResetController = TextEditingController();
    final dialogFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Đặt lại mật khẩu'),
            content: Form(
              key: dialogFormKey,
              child: TextFormField(
                controller: emailResetController,
                autofocus: true,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Nhập email đã đăng ký',
                ),
                validator:
                    (value) =>
                        (value == null || value.isEmpty || !value.contains('@'))
                            ? 'Vui lòng nhập email hợp lệ'
                            : null,
              ),
            ),
            actions: [
              // Nút hủy
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Hủy'),
              ),
              // Nút gửi email khôi phục
              ElevatedButton(
                onPressed: () async {
                  if (dialogFormKey.currentState!.validate()) {
                    final email = emailResetController.text.trim();
                    Navigator.of(ctx).pop(); // Đóng dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đang gửi email...')),
                    );
                    try {
                      await context.read<AuthProvider>().sendPasswordResetEmail(
                        email,
                      );
                      if (mounted)
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Đã gửi link. Vui lòng kiểm tra hộp thư!',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                    } catch (e) {
                      if (mounted)
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Lỗi: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                    }
                  }
                },
                child: const Text('Gửi'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Tiêu đề màn hình
                  const Text(
                    'Đăng nhập',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  // Trường nhập email
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator:
                        (value) =>
                            (value == null ||
                                    value.isEmpty ||
                                    !value.contains('@'))
                                ? 'Vui lòng nhập email hợp lệ'
                                : null,
                  ),
                  const SizedBox(height: 16),
                  // Trường nhập mật khẩu
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed:
                            () => setState(
                              () => _isPasswordVisible = !_isPasswordVisible,
                            ),
                      ),
                    ),
                    obscureText: !_isPasswordVisible,
                    validator:
                        (value) =>
                            (value == null || value.length < 6)
                                ? 'Mật khẩu phải có ít nhất 6 ký tự'
                                : null,
                  ),
                  // Link quên mật khẩu
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _showForgotPasswordDialog,
                      child: const Text('Quên mật khẩu?'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Nút đăng nhập
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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
                            : const Text(
                              'Đăng nhập',
                              style: TextStyle(fontSize: 18),
                            ),
                  ),
                  const SizedBox(height: 32),
                  // Phân cách giữa các phương thức đăng nhập
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          "Hoặc đăng nhập với",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Nút đăng nhập bằng Google
                  ElevatedButton.icon(
                    icon: Image.asset(
                      'assets/images/google_logo.png',
                      height: 24.0,
                      width: 24.0,
                    ),
                    label: const Text('Đăng nhập với Google'),
                    onPressed:
                        _isLoading
                            ? null
                            : () async {
                              setState(() => _isLoading = true);
                              try {
                                await context
                                    .read<AuthProvider>()
                                    .signInWithGoogle();
                              } catch (e) {
                                if (mounted)
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Đăng nhập Google thất bại: $e',
                                      ),
                                    ),
                                  );
                              } finally {
                                if (mounted) setState(() => _isLoading = false);
                              }
                            },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.black,
                      backgroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Link chuyển đến màn hình đăng ký
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Chưa có tài khoản?'),
                      TextButton(
                        onPressed:
                            _isLoading
                                ? null
                                : () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (ctx) => const RegisterScreen(),
                                    ),
                                  );
                                },
                        child: const Text('Đăng ký ngay'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
