// File chính của ứng dụng Quản lý Chi tiêu
// Chứa các cấu hình cơ bản và khởi tạo ứng dụng

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

// Import các provider để quản lý state
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/expense_provider.dart';
import 'providers/category_provider.dart';
import 'providers/budget_provider.dart';
import 'providers/reminder_provider.dart';
import 'providers/date_range_provider.dart';
import 'providers/group_provider.dart';
import 'providers/debt_provider.dart';
import 'providers/currency_provider.dart';
import 'providers/chat_history_provider.dart';
import 'models/date_range.dart';

// Import các màn hình chính
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';

/// Hàm main - điểm khởi đầu của ứng dụng
void main() async {
  // Đảm bảo Flutter binding được khởi tạo
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo và yêu cầu quyền thông báo trước khi chạy app
  await NotificationService().init();
  await NotificationService().requestPermission();

  // Khởi tạo Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

/// Widget gốc của ứng dụng
/// Cấu hình theme và các provider
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provider quản lý theme (sáng/tối)
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        // Provider quản lý khoảng thời gian
        ChangeNotifierProvider(create: (_) => DateRangeProvider()),
        // Provider quản lý tiền tệ
        ChangeNotifierProvider(create: (_) => CurrencyProvider()..loadCurrency()),
        // Provider quản lý xác thực người dùng
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // Provider quản lý chi tiêu, phụ thuộc vào AuthProvider
        ChangeNotifierProxyProvider<AuthProvider, ExpenseProvider>(
          create:
              (ctx) => ExpenseProvider(
                Provider.of<AuthProvider>(ctx, listen: false),
              ),
          update: (_, auth, previous) => ExpenseProvider(auth),
        ),
        // Provider quản lý danh mục, phụ thuộc vào AuthProvider
        ChangeNotifierProxyProvider<AuthProvider, CategoryProvider>(
          create:
              (ctx) => CategoryProvider(
                Provider.of<AuthProvider>(ctx, listen: false),
              ),
          update: (_, auth, previous) => CategoryProvider(auth),
        ),
        // Provider quản lý nhắc nhở, phụ thuộc vào AuthProvider
        ChangeNotifierProxyProvider<AuthProvider, ReminderProvider>(
          create:
              (ctx) => ReminderProvider(
                Provider.of<AuthProvider>(ctx, listen: false),
              ),
          update: (_, auth, previous) => ReminderProvider(auth),
        ),
        // Provider quản lý ngân sách, phụ thuộc vào AuthProvider và DateRangeProvider
        ChangeNotifierProxyProvider2<
          AuthProvider,
          DateRangeProvider,
          BudgetProvider
        >(
          create:
              (ctx) => BudgetProvider(
                Provider.of<AuthProvider>(ctx, listen: false),
                Provider.of<DateRangeProvider>(ctx, listen: false),
              ),
          update:
              (_, auth, dateRange, previous) => BudgetProvider(auth, dateRange),
        ),
        // Provider quản lý nhóm/doanh nghiệp, phụ thuộc vào AuthProvider
        ChangeNotifierProxyProvider<AuthProvider, GroupProvider>(
          create:
              (ctx) => GroupProvider(
                Provider.of<AuthProvider>(ctx, listen: false),
              ),
          update:
              (_, auth, previous) => GroupProvider(auth),
        ),
        // Provider quản lý nợ, phụ thuộc vào AuthProvider
        ChangeNotifierProxyProvider<AuthProvider, DebtProvider>(
          create:
              (ctx) => DebtProvider(
                Provider.of<AuthProvider>(ctx, listen: false),
              ),
          update:
              (_, auth, previous) {
                // Dispose stream cũ trước khi tạo mới
                previous?.dispose();
                return DebtProvider(auth);
              },
        ),
        // Provider quản lý lịch sử chat với AI, phụ thuộc vào AuthProvider
        ChangeNotifierProxyProvider<AuthProvider, ChatHistoryProvider>(
          create:
              (ctx) => ChatHistoryProvider(
                Provider.of<AuthProvider>(ctx, listen: false),
              ),
          update:
              (_, auth, previous) {
                previous?.dispose();
                return ChatHistoryProvider(auth);
              },
        ),
      ],
      // Sử dụng Consumer để lắng nghe thay đổi theme
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Quản lý Chi tiêu',
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const AuthWrapper(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

/// Widget kiểm tra trạng thái đăng nhập và điều hướng người dùng
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        // Nếu đã đăng nhập thì hiển thị màn hình chính
        if (auth.isLoggedIn) {
          return const HomeScreen();
        } else {
          // Nếu chưa đăng nhập thì hiển thị màn hình đăng nhập
          return const LoginScreen();
        }
      },
    );
  }
}
