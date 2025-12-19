/// Màn hình chính của ứng dụng
/// Cho phép người dùng:
/// - Xem tổng quan thu chi trong khoảng thời gian
/// - Xem lịch sử giao dịch
/// - Thêm giao dịch mới
/// - Xóa giao dịch
/// - Chuyển đổi giữa các màn hình chính (Trang chính, Thống kê, Ngân sách, Cài đặt)
// lib/screens/home_screen.dart

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io'; // Để dùng File

// Import các provider đã refactor
import '../providers/expense_provider.dart';
import '../providers/category_provider.dart';
import '../providers/date_range_provider.dart';
import '../providers/auth_provider.dart';

// Import các model đã refactor
import '../models/expense.dart';
import '../models/user.dart'; // Import AppUser

// Import các màn hình khác
import '../widgets/date_range_selector.dart';
import 'add_expense_screen.dart';
import 'statistics_screen.dart';
import 'settings_screen.dart';
import 'budget_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';
import 'detailed_statistics_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Chỉ số của tab đang được chọn
  int _selectedIndex = 0;
  // Định dạng tiền tệ theo chuẩn Việt Nam
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  /// Xây dựng trang chính hiển thị tổng quan và lịch sử giao dịch
  Widget _buildMainPage(BuildContext context) {
    // Sử dụng context.watch để lắng nghe thay đổi và tự động rebuild
    final expenseProvider = context.watch<ExpenseProvider>();
    final dateRangeProvider = context.watch<DateRangeProvider>();
    final currentRange = dateRangeProvider.currentRange;

    // Lọc chi phí theo khoảng thời gian đã chọn
    final expenses = expenseProvider.getExpensesByDateRange(currentRange);

    // Tính toán các thông số
    final totalIncome = expenseProvider.getTotalIncomeByDateRange(currentRange);
    final totalExpense = expenseProvider.getTotalExpensesByDateRange(
      currentRange,
    );
    final balance = totalIncome - totalExpense;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Bộ chọn khoảng thời gian
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: DateRangeSelector(),
          ),
          // Card tổng quan thu chi
          _buildOverviewCard(
            currentRange.displayText,
            totalIncome,
            totalExpense,
            balance,
          ),
          // Card lịch sử giao dịch
          _buildHistoryCard(expenses),
        ],
      ),
    );
  }

  /// Xây dựng card tổng quan hiển thị thu nhập, chi tiêu và số dư
  Widget _buildOverviewCard(
    String rangeText,
    double income,
    double expense,
    double balance,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            rangeText,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildBalanceRow('Thu nhập', income, Colors.green, Icons.trending_up),
          const SizedBox(height: 8),
          _buildBalanceRow(
            'Chi tiêu',
            expense,
            Colors.red,
            Icons.trending_down,
          ),
          const SizedBox(height: 8),
          _buildBalanceRow(
            'Cân đối',
            balance,
            balance >= 0 ? Colors.blue : Colors.orange,
            Icons.account_balance_wallet,
          ),
        ],
      ),
    );
  }

  /// Xây dựng card hiển thị lịch sử giao dịch
  Widget _buildHistoryCard(List<Expense> expenses) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lịch sử Giao dịch',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          expenses.isEmpty
              ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Chưa có ghi chép nào trong khoảng thời gian này.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
              : _buildExpensesList(expenses),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Lấy user từ AuthProvider để dùng cho Drawer
    final AppUser? user = context.watch<AuthProvider>().currentUser;

    // Danh sách các trang chính của ứng dụng
    final List<Widget> pages = [
      _buildMainPage(context),
      const StatisticsScreen(),
      const BudgetScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Chi tiêu'),
        actions: [
          // Nút chuyển đến màn hình thống kê chi tiết
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Thống kê chi tiết',
            onPressed:
                () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => const DetailedStatisticsScreen(),
                  ),
                ),
          ),
        ],
      ),
      // Menu bên trái hiển thị thông tin người dùng và các tùy chọn
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Header hiển thị thông tin người dùng
            UserAccountsDrawerHeader(
              accountName: Text(user?.username ?? 'Người dùng'),
              accountEmail: Text(user?.email ?? 'Chưa có email'),
              currentAccountPicture: CircleAvatar(
                backgroundImage:
                    user?.avatar != null
                        ? FileImage(File(user!.avatar!))
                        : null,
                child:
                    user?.avatar == null
                        ? const Icon(Icons.person, size: 40)
                        : null,
              ),
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            ),
            // Menu thông tin tài khoản
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Thông tin tài khoản'),
              onTap:
                  () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (ctx) => const ProfileScreen()),
                  ),
            ),
            const Divider(),
            // Menu đăng xuất
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Đăng xuất'),
              onTap: () async {
                // Sử dụng context.read trong các hàm callback
                await context.read<AuthProvider>().logout();
                // Không cần điều hướng ở đây vì AuthWrapper sẽ xử lý
              },
            ),
          ],
        ),
      ),
      // Hiển thị trang tương ứng với tab được chọn
      body: IndexedStack(index: _selectedIndex, children: pages),
      // Thanh điều hướng dưới cùng
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chính'),
          BottomNavigationBarItem(
            icon: Icon(Icons.insert_chart),
            label: 'Thống kê',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Ngân sách',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Cài đặt'),
        ],
      ),
      // Nút thêm giao dịch mới
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed:
            () => Navigator.of(context).push(
              MaterialPageRoute(builder: (ctx) => const AddExpenseScreen()),
            ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  /// Xây dựng hàng hiển thị số tiền với icon và màu sắc tương ứng
  Widget _buildBalanceRow(
    String title,
    double amount,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const Spacer(),
          Text(
            currencyFormat.format(amount),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Xây dựng danh sách các giao dịch
  Widget _buildExpensesList(List<Expense> expenses) {
    // Dùng context.read bên trong các hàm build hoặc callback
    final expenseProvider = context.read<ExpenseProvider>();
    final categoryProvider = context.read<CategoryProvider>();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: expenses.length,
      itemBuilder: (ctx, i) {
        final expense = expenses[i];
        // [CẬP NHẬT] categoryId giờ là String
        final category = categoryProvider.findById(expense.categoryId);

        return Dismissible(
          key: ValueKey(expense.id), // ID là String, vẫn dùng làm key được
          direction: DismissDirection.endToStart,
          // Hiệu ứng xóa khi vuốt sang trái
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: const Icon(Icons.delete, color: Colors.white, size: 30),
          ),
          // Dialog xác nhận xóa
          confirmDismiss: (direction) {
            return showDialog(
              context: context,
              builder:
                  (ctx) => AlertDialog(
                    title: const Text('Xác nhận xóa'),
                    content: const Text('Bạn có chắc muốn xóa giao dịch này?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Không'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Có'),
                      ),
                    ],
                  ),
            );
          },
          // Xử lý sự kiện xóa giao dịch
          onDismissed: (direction) {
            // [CẬP NHẬT] Gọi hàm delete với String ID
            if (expense.id != null) {
              expenseProvider.deleteExpense(expense.id!);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Giao dịch đã được xóa'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
          // Hiển thị thông tin giao dịch
          child: Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: category.color,
                child: Icon(category.icon, color: Colors.white, size: 20),
              ),
              title: Text(expense.description),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(expense.date)),
              trailing: Text(
                '${expense.isIncome ? '+' : '-'} ${currencyFormat.format(expense.amount)}',
                style: TextStyle(
                  color: expense.isIncome ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Xử lý sự kiện khi nhấn vào giao dịch để chỉnh sửa
              onTap:
                  () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => AddExpenseScreen(expense: expense),
                    ),
                  ),
            ),
          ),
        );
      },
    );
  }
}
