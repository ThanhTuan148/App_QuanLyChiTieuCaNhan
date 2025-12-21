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
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;

// Import các provider đã refactor
import '../providers/expense_provider.dart';
import '../providers/category_provider.dart';
import '../providers/date_range_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/currency_provider.dart';

// Import các model đã refactor
import '../models/expense.dart';
import '../models/user.dart';

// Import các màn hình khác
import '../widgets/date_range_selector.dart';
import '../widgets/transaction_card.dart';
import '../widgets/theme_switch.dart';
import '../utils/category_emoji_mapper.dart';
import 'add_expense_screen.dart';
import 'statistics_screen.dart';
import 'settings_screen.dart';
import 'budget_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';
import 'detailed_statistics_screen.dart';
import 'ai_chat_screen.dart';
import 'groups_screen.dart';
import 'expense_prediction_screen.dart';
import 'debt_management_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _floatAnimationController;

  @override
  void initState() {
    super.initState();
    _floatAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatAnimationController.dispose();
    super.dispose();
  }

  Widget _buildMainPage(BuildContext context) {
    final expenseProvider = context.watch<ExpenseProvider>();
    final dateRangeProvider = context.watch<DateRangeProvider>();
    final currencyFormat = context.watch<CurrencyProvider>().currencyFormat;
    final currentRange = dateRangeProvider.currentRange;
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    final expenses = expenseProvider.getExpensesByDateRange(currentRange);
    final totalIncome = expenseProvider.getTotalIncomeByDateRange(currentRange);
    final totalExpense = expenseProvider.getTotalExpensesByDateRange(currentRange);
    final balance = totalIncome - totalExpense;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header với avatar và welcome message
            _buildHeader(context, user),
            // Main content với scroll
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    // Date Range Selector
                    const DateRangeSelector(),
                    const SizedBox(height: 16),
                    // Total Balance Card
                    _buildBalanceCard(context, balance, totalIncome, totalExpense),
                    const SizedBox(height: 24),
                    // Statistics Section
                    _buildStatisticsSection(context),
                    const SizedBox(height: 24),
                    // Recent Transactions
                    _buildRecentTransactions(context, expenses),
                    const SizedBox(height: 100), // Space for bottom nav
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarImage(BuildContext context, AppUser? user) {
    if (user?.avatar == null || user!.avatar!.isEmpty) {
      return Container(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        child: Icon(
          Icons.person,
          color: Theme.of(context).primaryColor,
        ),
      );
    }

    // Trên web hoặc nếu là URL, dùng Image.network
    if (kIsWeb || user.avatar!.startsWith('http://') || user.avatar!.startsWith('https://')) {
      return Image.network(
        user.avatar!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Icon(
              Icons.person,
              color: Theme.of(context).primaryColor,
            ),
          );
        },
      );
    }

    // Trên mobile, nếu là file path, dùng Image.file
    return Image.file(
      File(user.avatar!),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Icon(
            Icons.person,
            color: Theme.of(context).primaryColor,
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, AppUser? user) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 16),
      child: Row(
        children: [
          // Drawer menu button
          Builder(
            builder: (context) => IconButton(
              icon: Icon(
                Icons.menu,
                color: isDark ? Colors.white : Colors.grey[900],
              ),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          const SizedBox(width: 8),
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).primaryColor,
                width: 2,
              ),
            ),
            child: ClipOval(
              child: _buildAvatarImage(context, user),
            ),
          ),
          const SizedBox(width: 12),
          // Welcome text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user?.username ?? 'User',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey[900],
                  ),
                ),
              ],
            ),
          ),
          // Theme toggle button
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return ThemeSwitch(
                value: themeProvider.isDarkMode,
                onChanged: (value) {
                  themeProvider.toggleDarkMode();
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(
    BuildContext context,
    double balance,
    double income,
    double expense,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormat = context.read<CurrencyProvider>().currencyFormat;

    return AnimatedBuilder(
      animation: _floatAnimationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimationController.value * 5),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Balance',
                  style: TextStyle(
                    color: Colors.green[100],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  currencyFormat.format(balance),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildBalanceItem(
                          context,
                          Icons.arrow_downward,
                          'Income',
                          income,
                          true,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 32,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      Expanded(
                        child: _buildBalanceItem(
                          context,
                          Icons.arrow_upward,
                          'Expense',
                          expense,
                          false,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBalanceItem(
    BuildContext context,
    IconData icon,
    String label,
    double amount,
    bool isIncome,
  ) {
    final currencyFormat = context.read<CurrencyProvider>().currencyFormat;
    
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: Colors.green[100],
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${isIncome ? '+' : '-'}${currencyFormat.format(amount)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.grey[900],
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) => const DetailedStatisticsScreen(),
                  ),
                );
              },
              child: Text(
                'See All',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildPieChartCard(context),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildBarChartCard(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPieChartCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF25332E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[100]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Pie chart simulation
                CircularProgressIndicator(
                  value: 0.65,
                  strokeWidth: 12,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF25332E) : Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      'Oct',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.grey[400] : Colors.grey[500],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Spending',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChartCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF25332E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[100]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 96,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildBar(context, 0.4, isDark),
                _buildBar(context, 0.7, isDark),
                _buildBar(context, 0.55, isDark),
                _buildBar(context, 0.85, isDark),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Weekly Activity',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(BuildContext context, double height, bool isDark) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.3),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
        child: FractionallySizedBox(
          heightFactor: height,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(BuildContext context, List<Expense> expenses) {
    final categoryProvider = context.read<CategoryProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Get today's date for filtering
    final today = DateTime.now();
    final todayExpenses = expenses.where((e) {
      return e.date.year == today.year &&
          e.date.month == today.month &&
          e.date.day == today.day;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey[900],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Today',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (todayExpenses.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                'No transactions today',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
          )
        else
          ...todayExpenses.take(4).map((expense) {
            final category = categoryProvider.findById(expense.categoryId);
            final iconColors = _getCategoryIconColors(category.color);
            final expenseProvider = context.read<ExpenseProvider>();

            return Dismissible(
              key: ValueKey(expense.id),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                margin: const EdgeInsets.only(bottom: 16),
                child: const Icon(Icons.delete, color: Colors.white, size: 30),
              ),
              confirmDismiss: (direction) {
                return showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
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
              onDismissed: (direction) {
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
              child: TransactionCard(
                title: expense.description,
                subtitle: DateFormat('dd MMM yyyy • HH:mm').format(expense.date),
                amount: expense.amount,
                isIncome: expense.isIncome,
                emoji: CategoryEmojiMapper.getEmojiForIcon(category.icon),
                iconColor: iconColors['icon']!,
                iconBackgroundColor: iconColors['background']!,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => AddExpenseScreen(expense: expense),
                    ),
                  );
                },
              ),
            );
          }).toList(),
      ],
    );
  }

  Map<String, Color> _getCategoryIconColors(Color categoryColor) {
    // Map category color to icon and background colors
    return {
      'icon': categoryColor,
      'background': categoryColor.withOpacity(0.1),
    };
  }

  @override
  Widget build(BuildContext context) {
    final AppUser? user = context.watch<AuthProvider>().currentUser;
    final List<Widget> pages = [
      _buildMainPage(context),
      const StatisticsScreen(),
      const BudgetScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      drawer: _buildDrawer(context, user),
      bottomNavigationBar: _buildBottomNavBar(context),
      floatingActionButton: _buildFloatingActionButton(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildDrawer(BuildContext context, AppUser? user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Drawer(
      backgroundColor: isDark ? const Color(0xFF25332E) : Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header với thông tin user
          UserAccountsDrawerHeader(
            accountName: Text(
              user?.username ?? 'Người dùng',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(user?.email ?? 'Chưa có email'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: _buildAvatarImage(context, user),
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.8),
                ],
              ),
            ),
          ),
          // Menu thông tin tài khoản
          ListTile(
            leading: Icon(Icons.person, color: isDark ? Colors.white : Colors.grey[700]),
            title: Text(
              'Thông tin tài khoản',
              style: TextStyle(color: isDark ? Colors.white : Colors.grey[900]),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (ctx) => const ProfileScreen()),
              );
            },
          ),
          // Menu Trợ lý AI
          ListTile(
            leading: Icon(Icons.smart_toy, color: isDark ? Colors.white : Colors.grey[700]),
            title: Text(
              'Trợ lý AI',
              style: TextStyle(color: isDark ? Colors.white : Colors.grey[900]),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (ctx) => const AIChatScreen()),
              );
            },
          ),
          // Menu Nhóm/Doanh nghiệp
          ListTile(
            leading: Icon(Icons.group, color: isDark ? Colors.white : Colors.grey[700]),
            title: Text(
              'Nhóm của tôi',
              style: TextStyle(color: isDark ? Colors.white : Colors.grey[900]),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (ctx) => const GroupsScreen()),
              );
            },
          ),
          // Menu Dự báo chi tiêu
          ListTile(
            leading: Icon(Icons.trending_up, color: isDark ? Colors.white : Colors.grey[700]),
            title: Text(
              'Dự báo chi tiêu',
              style: TextStyle(color: isDark ? Colors.white : Colors.grey[900]),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (ctx) => ExpensePredictionScreen()),
              );
            },
          ),
          // Menu Quản lý nợ
          ListTile(
            leading: Icon(Icons.account_balance_wallet, color: isDark ? Colors.white : Colors.grey[700]),
            title: Text(
              'Quản lý nợ',
              style: TextStyle(color: isDark ? Colors.white : Colors.grey[900]),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (ctx) => DebtManagementScreen()),
              );
            },
          ),
          const Divider(),
          // Menu đăng xuất
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text(
              'Đăng xuất',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () async {
              Navigator.pop(context);
              await context.read<AuthProvider>().logout();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF25332E) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[100]!,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(context, Icons.home, 'Home', 0),
              _buildNavItem(context, Icons.bar_chart, 'Stats', 1),
              const SizedBox(width: 40), // Space for FAB
              _buildNavItem(context, Icons.account_balance_wallet, 'Wallet', 2),
              _buildNavItem(context, Icons.settings, 'Settings', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 24,
            color: isSelected
                ? Theme.of(context).primaryColor
                : (isDark ? Colors.grey[500] : Colors.grey[400]),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : (isDark ? Colors.grey[500] : Colors.grey[400]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      child: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (ctx) => const AddExpenseScreen()),
          );
        },
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
