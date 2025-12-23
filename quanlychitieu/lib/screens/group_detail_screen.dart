/// Màn hình chi tiết nhóm
/// Hiển thị thông tin nhóm, thành viên, dự án và các chức năng quản lý
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/group_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/theme_provider.dart';
import '../models/group.dart';
import '../models/expense.dart';
import 'add_expense_screen.dart';

class GroupDetailScreen extends StatefulWidget {
  final Group group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = themeProvider.selectedColor;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final surfaceColor = theme.cardColor;
    final textColor = theme.colorScheme.onSurface;
    final textSecondaryColor = theme.colorScheme.onSurface.withOpacity(0.6);

    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.currentUser?.id ?? '';
    final isAdmin = widget.group.isAdmin(currentUserId);
    final canEdit = widget.group.canEdit(currentUserId);
    final expenseProvider = context.watch<ExpenseProvider>();
    
    // Tính tổng chi tiêu của group
    final groupExpenses = expenseProvider.expenses
        .where((e) => e.groupId == widget.group.id && !e.isIncome)
        .toList();
    final totalSpend = groupExpenses.fold(0.0, (sum, e) => sum + e.amount);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Decorative gradients
          Positioned(
            top: -MediaQuery.of(context).size.height * 0.1,
            left: -MediaQuery.of(context).size.width * 0.1,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.5,
              height: MediaQuery.of(context).size.height * 0.5,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, isAdmin, theme, textColor, surfaceColor, textSecondaryColor),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildHeroCard(context, totalSpend, theme, themeProvider, isDark, primaryColor, backgroundColor, surfaceColor, textColor, textSecondaryColor),
                        const SizedBox(height: 24),
                        _buildQuickActions(context, isAdmin, canEdit, theme, themeProvider, primaryColor, surfaceColor, textColor, textSecondaryColor),
                        const SizedBox(height: 24),
                        _buildTabSwitcher(theme, themeProvider, primaryColor, surfaceColor, backgroundColor, textColor, textSecondaryColor),
                        const SizedBox(height: 16),
                        _buildTabContent(context, isAdmin, canEdit, groupExpenses, theme, themeProvider, primaryColor, surfaceColor, textColor, textSecondaryColor),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Floating Action Button
          Positioned(
            bottom: 32,
            right: 32,
            child: FloatingActionButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddExpenseScreen(
                      preSelectedGroupId: widget.group.id,
                    ),
                  ),
                );
                if (context.mounted) {
                  context.read<GroupProvider>().selectGroup(widget.group);
                }
              },
              backgroundColor: primaryColor,
              foregroundColor: isDark ? Colors.white : Colors.black,
              elevation: 0,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.5),
                      blurRadius: 30,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: const Icon(Icons.add, size: 32),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isAdmin, ThemeData theme, Color textColor, Color surfaceColor, Color textSecondaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: surfaceColor.withOpacity(0.85),
        border: Border(
          bottom: BorderSide(
            color: textColor.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            'Group Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          IconButton(
            icon: Icon(Icons.settings, color: textColor),
            onPressed: isAdmin ? () {
              // TODO: Settings
            } : null,
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context, double totalSpend, ThemeData theme, ThemeProvider themeProvider, bool isDark, Color primaryColor, Color backgroundColor, Color surfaceColor, Color textColor, Color textSecondaryColor) {
    final memberCount = widget.group.members.length;
    final displayedMembers = widget.group.members.take(3).toList();
    final remainingCount = memberCount > 3 ? memberCount - 3 : 0;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: surfaceColor.withOpacity(isDark ? 0.3 : 0.8),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: textColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Column(
            children: [
              Text(
                widget.group.name,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ...displayedMembers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final member = entry.value;
                      return Positioned(
                        left: index * 32.0,
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: backgroundColor,
                          child: CircleAvatar(
                            radius: 22,
                            backgroundColor: textColor.withOpacity(0.2),
                            child: Text(
                              member.username[0].toUpperCase(),
                              style: TextStyle(
                                color: textColor,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    if (remainingCount > 0)
                      Positioned(
                        left: displayedMembers.length * 32.0 + 4,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: textColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: backgroundColor,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '+$remainingCount',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'TOTAL SPEND',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: textSecondaryColor,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '\$${totalSpend.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                  letterSpacing: -2,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      textColor.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Your Position (placeholder)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your Position',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textSecondaryColor,
                    ),
                  ),
                  Text(
                    'You are owed \$120.00',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: textColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: 0.65,
                      child: Container(
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.6),
                              blurRadius: 15,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, bool isAdmin, bool canEdit, ThemeData theme, ThemeProvider themeProvider, Color primaryColor, Color surfaceColor, Color textColor, Color textSecondaryColor) {
    final isDark = theme.brightness == Brightness.dark;
    final actions = [
      {'label': 'Expense', 'icon': Icons.add_circle, 'primary': true},
      {'label': 'Settle Up', 'icon': Icons.payments, 'primary': false},
      {'label': 'Analytics', 'icon': Icons.ssid_chart, 'primary': false},
      {'label': 'Export', 'icon': Icons.receipt_long, 'primary': false},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: actions.map((action) {
        return Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: surfaceColor.withOpacity(isDark ? 0.3 : 0.5),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: (action['primary'] as bool)
                      ? primaryColor.withOpacity(0.4)
                      : textColor.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Icon(
                action['icon'] as IconData,
                color: (action['primary'] as bool) ? primaryColor : textColor,
                size: 32,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              action['label'] as String,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: textSecondaryColor,
                letterSpacing: 1,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildTabSwitcher(ThemeData theme, ThemeProvider themeProvider, Color primaryColor, Color surfaceColor, Color backgroundColor, Color textColor, Color textSecondaryColor) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: surfaceColor.withOpacity(isDark ? 0.3 : 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: textColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.2),
              blurRadius: 20,
            ),
          ],
        ),
        labelColor: isDark ? Colors.white : Colors.black,
        unselectedLabelColor: textSecondaryColor,
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        tabs: const [
          Tab(text: 'Activity'),
          Tab(text: 'Balances'),
          Tab(text: 'Members'),
        ],
      ),
    );
  }

  Widget _buildTabContent(BuildContext context, bool isAdmin, bool canEdit, List<Expense> groupExpenses, ThemeData theme, ThemeProvider themeProvider, Color primaryColor, Color surfaceColor, Color textColor, Color textSecondaryColor) {
    return SizedBox(
      height: 400,
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildActivityTab(context, groupExpenses, theme, themeProvider, primaryColor, surfaceColor, textColor, textSecondaryColor),
          _buildBalancesTab(context, theme, textColor),
          _buildMembersTab(context, isAdmin, theme, surfaceColor, textColor, textSecondaryColor),
        ],
      ),
    );
  }

  Widget _buildActivityTab(BuildContext context, List<Expense> groupExpenses, ThemeData theme, ThemeProvider themeProvider, Color primaryColor, Color surfaceColor, Color textColor, Color textSecondaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'VIEW ALL',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: groupExpenses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.payments,
                        size: 64,
                        color: textSecondaryColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No expenses yet',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: groupExpenses.length,
                  itemBuilder: (context, index) {
                    final expense = groupExpenses[index];
                    return _buildExpenseCard(context, expense, theme, themeProvider, primaryColor, surfaceColor, textColor, textSecondaryColor);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildExpenseCard(BuildContext context, Expense expense, ThemeData theme, ThemeProvider themeProvider, Color primaryColor, Color surfaceColor, Color textColor, Color textSecondaryColor) {
    final isDark = theme.brightness == Brightness.dark;
    final paidByMember = widget.group.members.firstWhere(
      (m) => m.userId == expense.userId,
      orElse: () => widget.group.members.first,
    );
    final isYou = expense.userId == context.read<AuthProvider>().currentUser?.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor.withOpacity(isDark ? 0.3 : 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: textColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: textColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: textColor.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Icon(Icons.receipt, color: textColor, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        expense.description,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '\$${expense.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: isYou ? primaryColor : textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Paid by ${isYou ? 'You' : paidByMember.username}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: textSecondaryColor,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      DateFormat('MMM d').format(expense.date),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: textSecondaryColor.withOpacity(0.7),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalancesTab(BuildContext context, ThemeData theme, Color textColor) {
    return Center(
      child: Text(
        'Balances',
        style: TextStyle(color: textColor),
      ),
    );
  }

  Widget _buildMembersTab(BuildContext context, bool isAdmin, ThemeData theme, Color surfaceColor, Color textColor, Color textSecondaryColor) {
    final isDark = theme.brightness == Brightness.dark;
    return ListView.builder(
      itemCount: widget.group.members.length,
      itemBuilder: (context, index) {
        final member = widget.group.members[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: surfaceColor.withOpacity(isDark ? 0.3 : 0.5),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: textColor.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: textColor.withOpacity(0.2),
                radius: 24,
                child: Text(
                  member.username[0].toUpperCase(),
                  style: TextStyle(color: textColor),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.username,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      member.email,
                      style: TextStyle(
                        fontSize: 14,
                        color: textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
