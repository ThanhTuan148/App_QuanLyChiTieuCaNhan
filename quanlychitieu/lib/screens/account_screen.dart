/// Màn hình tài khoản người dùng
/// Hiển thị hai trạng thái:
/// 1. Đã đăng nhập:
///    - Hiển thị thông tin người dùng (avatar, tên, email)
///    - Nút đăng xuất
/// 2. Chưa đăng nhập:
///    - Thông báo chưa đăng nhập
///    - Nút đăng nhập
///    - Link đăng ký tài khoản mới
// [ĐÃ REFACTOR] lib/screens/account_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Sử dụng Consumer để lắng nghe thay đổi trạng thái đăng nhập
    // và tự động rebuild UI khi cần thiết
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Kiểm tra trạng thái đăng nhập
        if (authProvider.isLoggedIn) {
          // UI khi đã đăng nhập
          final user = authProvider.currentUser;
          return Scaffold(
            appBar: AppBar(title: const Text('Tài khoản')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Avatar người dùng (hiện tại là icon mặc định)
                  const CircleAvatar(
                    radius: 50,
                    child: Icon(Icons.person, size: 50),
                  ),
                  const SizedBox(height: 20),
                  // Tên người dùng
                  Text(
                    user?.username ?? 'Không có tên',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  // Email người dùng
                  Text(
                    user?.email ?? 'Không có email',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 30),
                  // Nút đăng xuất
                  ElevatedButton(
                    onPressed: () {
                      // Gọi hàm đăng xuất từ AuthProvider
                      context.read<AuthProvider>().logout();
                    },
                    child: const Text('Đăng xuất'),
                  ),
                ],
              ),
            ),
          );
        } else {
          // UI khi chưa đăng nhập
          return Scaffold(
            appBar: AppBar(title: const Text('Tài khoản')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Thông báo chưa đăng nhập
                  const Text(
                    'Bạn chưa đăng nhập',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  // Nút chuyển đến màn hình đăng nhập
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => const LoginScreen(),
                        ),
                      );
                    },
                    child: const Text('Đăng nhập'),
                  ),
                  const SizedBox(height: 10),
                  // Link chuyển đến màn hình đăng ký
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => const RegisterScreen(),
                        ),
                      );
                    },
                    child: const Text('Chưa có tài khoản? Đăng ký ngay'),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}
