/// Màn hình quản lý Nhóm/Doanh nghiệp
/// Hiển thị danh sách nhóm user tham gia và cho phép tạo nhóm mới
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/group_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/theme_provider.dart';
import '../models/group.dart';
import 'create_group_screen.dart';
import 'group_detail_screen.dart';

class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

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
          Positioned(
            bottom: -MediaQuery.of(context).size.height * 0.1,
            right: -MediaQuery.of(context).size.width * 0.1,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.6,
              height: MediaQuery.of(context).size.height * 0.6,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(isDark ? 0.15 : 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: Consumer<GroupProvider>(
                    builder: (context, groupProvider, child) {
                      if (groupProvider.groups.isEmpty) {
                        return _buildEmptyState(context);
                      }

                      final theme = Theme.of(context);
                      final themeProvider = context.watch<ThemeProvider>();
                      final primaryColor = themeProvider.selectedColor;

                      return RefreshIndicator(
                        onRefresh: () async {
                          await groupProvider.refreshGroups();
                        },
                        color: primaryColor,
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: groupProvider.groups.length,
                          itemBuilder: (context, index) {
                            final group = groupProvider.groups[index];
                            return _buildGroupCard(context, group);
                          },
                        ),
                      );
                    },
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
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
              ).then((group) {
                if (group != null && context.mounted) {
                  context.read<GroupProvider>().selectGroup(group as Group);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GroupDetailScreen(group: group),
                    ),
                  );
                }
              }),
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

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final textSecondaryColor = theme.colorScheme.onSurface.withOpacity(0.5);
    final surfaceColor = theme.cardColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DASHBOARD',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: textSecondaryColor,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'My Groups',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: surfaceColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: textColor.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: Icon(Icons.settings, color: textColor),
              onPressed: () {
                // TODO: Settings
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final textSecondaryColor = theme.colorScheme.onSurface.withOpacity(0.5);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group_outlined,
            size: 80,
            color: textSecondaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Bạn chưa tham gia nhóm nào',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Tạo nhóm mới để bắt đầu quản lý chi tiêu nhóm',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: textSecondaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(BuildContext context, Group group) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = themeProvider.selectedColor;
    final surfaceColor = theme.cardColor;
    final textColor = theme.colorScheme.onSurface;
    final textSecondaryColor = theme.colorScheme.onSurface.withOpacity(0.5);
    final backgroundColor = theme.scaffoldBackgroundColor;

    final currentUser = context.read<AuthProvider>().currentUser;
    final isActive = group.isActive;
    final memberCount = group.members.length;
    
    // Tính tổng chi tiêu từ expenses của group
    final expenseProvider = context.watch<ExpenseProvider>();
    final groupExpenses = expenseProvider.expenses
        .where((e) => e.groupId == group.id && !e.isIncome)
        .toList();
    final totalSpend = groupExpenses.fold(0.0, (sum, e) => sum + e.amount);

    return GestureDetector(
      onTap: () {
        context.read<GroupProvider>().selectGroup(group);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GroupDetailScreen(group: group),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: surfaceColor.withOpacity(isDark ? 0.3 : 0.8),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: textColor.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        child: Icon(
                          Icons.group,
                          color: textColor,
                          size: 28,
                        ),
                      ),
                      if (isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: primaryColor.withOpacity(0.4),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'ACTIVE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    group.name,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${totalSpend.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: primaryColor,
                          letterSpacing: -1,
                        ),
                      ),
                      Text(
                        '.${(totalSpend % 1 * 100).toStringAsFixed(0).padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        height: 32,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            ...group.members.take(3).toList().asMap().entries.map((entry) {
                              final index = entry.key;
                              final member = entry.value;
                              return Positioned(
                                left: index * 20.0,
                                child: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: backgroundColor,
                                  child: CircleAvatar(
                                    radius: 14,
                                    backgroundColor: textColor.withOpacity(0.2),
                                    child: Text(
                                      member.username[0].toUpperCase(),
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                            if (memberCount > 3)
                              Positioned(
                                left: group.members.take(3).length * 20.0 + 4,
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: textColor.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: backgroundColor,
                                      width: 2,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '+${memberCount - 3}',
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        '$memberCount members',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: textSecondaryColor,
                          letterSpacing: 1,
                        ),
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

