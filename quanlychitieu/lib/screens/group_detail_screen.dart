/// Màn hình chi tiết nhóm
/// Hiển thị thông tin nhóm, thành viên, dự án và các chức năng quản lý
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/group_provider.dart';
import '../providers/auth_provider.dart';
import '../models/group.dart';
import '../models/project.dart';
import 'invite_member_screen.dart';
import 'approval_screen.dart';
import 'group_reports_screen.dart';
import 'cash_flow_screen.dart';
import 'add_expense_screen.dart';
import 'create_project_screen.dart';

class GroupDetailScreen extends StatelessWidget {
  final Group group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.currentUser?.id ?? '';
    final isAdmin = group.isAdmin(currentUserId);
    final canEdit = group.canEdit(currentUserId);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(group.name),
          actions: [
            if (isAdmin)
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  // TODO: Settings screen
                },
                tooltip: 'Cài đặt nhóm',
              ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.info), text: 'Thông tin'),
              Tab(icon: Icon(Icons.people), text: 'Thành viên'),
              Tab(icon: Icon(Icons.folder), text: 'Dự án'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildInfoTab(context, isAdmin, canEdit),
            _buildMembersTab(context, isAdmin),
            _buildProjectsTab(context, isAdmin),
          ],
        ),
        floatingActionButton: Builder(
          builder: (context) {
            final tabController = DefaultTabController.of(context);
            // Hiển thị FAB khác nhau tùy theo tab
            if (tabController.index == 1 && isAdmin) {
              // Tab Thành viên - FAB mời thành viên
              return FloatingActionButton.extended(
                icon: const Icon(Icons.person_add),
                label: const Text('Mời thành viên'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InviteMemberScreen(group: group),
                  ),
                ),
              );
            } else if (tabController.index == 2 && isAdmin) {
              // Tab Dự án - FAB tạo dự án
              return FloatingActionButton.extended(
                icon: const Icon(Icons.add),
                label: const Text('Tạo dự án'),
                    onPressed: () async {
                      final project = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreateProjectScreen(group: group),
                        ),
                      );
                      if (project != null) {
                        // Refresh projects list
                        context.read<GroupProvider>().selectGroup(group);
                      }
                    },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildInfoTab(BuildContext context, bool isAdmin, bool canEdit) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thông tin nhóm
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thông tin nhóm',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (group.description != null) ...[
                    Text(
                      group.description!,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _buildInfoRow(
                    Icons.calendar_today,
                    'Ngày tạo',
                    _formatDate(group.createdAt),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.people,
                    'Số thành viên',
                    '${group.members.length} người',
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.folder,
                    'Số dự án',
                    '${group.projectIds.length} dự án',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Quick actions
          const Text(
            'Thao tác nhanh',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2.5,
            children: [
              _buildActionCard(
                context,
                Icons.add_chart,
                'Thêm giao dịch',
                Colors.blue,
                () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddExpenseScreen(
                        preSelectedGroupId: group.id,
                      ),
                    ),
                  );
                  // Refresh group data when returning
                  context.read<GroupProvider>().selectGroup(group);
                },
              ),
              _buildActionCard(
                context,
                Icons.bar_chart,
                'Báo cáo',
                Colors.green,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GroupReportsScreen(group: group),
                  ),
                ),
              ),
              _buildActionCard(
                context,
                Icons.account_balance,
                'Dòng tiền',
                Colors.teal,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CashFlowScreen(group: group),
                  ),
                ),
              ),
              if (canEdit)
                _buildActionCard(
                  context,
                  Icons.check_circle,
                  'Phê duyệt',
                  Colors.orange,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ApprovalScreen(group: group),
                    ),
                  ),
                ),
              _buildActionCard(
                context,
                Icons.history,
                'Lịch sử',
                Colors.purple,
                () {
                  // TODO: Audit log screen
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMembersTab(BuildContext context, bool isAdmin) {
    return Consumer<GroupProvider>(
      builder: (context, groupProvider, child) {
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: group.members.length,
          itemBuilder: (context, index) {
            final member = group.members[index];
            final isCurrentUser = member.userId ==
                context.read<AuthProvider>().currentUser?.id;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getRoleColor(member.role),
                  child: Text(
                    member.username[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(
                  member.username,
                  style: TextStyle(
                    fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(member.email),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getRoleColor(member.role).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getRoleName(member.role),
                        style: TextStyle(
                          fontSize: 12,
                          color: _getRoleColor(member.role),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                trailing: isAdmin && !isCurrentUser
                    ? IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () {
                          // TODO: Show menu to change role or remove
                        },
                      )
                    : null,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProjectsTab(BuildContext context, bool isAdmin) {
    return Consumer<GroupProvider>(
      builder: (context, groupProvider, child) {
        if (groupProvider.projects.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Chưa có dự án nào',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                if (isAdmin) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Tạo dự án'),
                    onPressed: () async {
                      final project = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreateProjectScreen(group: group),
                        ),
                      );
                      if (project != null) {
                        // Refresh projects list
                        context.read<GroupProvider>().selectGroup(group);
                      }
                    },
                  ),
                ],
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: groupProvider.projects.length,
          itemBuilder: (context, index) {
            final project = groupProvider.projects[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.folder),
                ),
                title: Text(project.name),
                subtitle: project.description != null
                    ? Text(project.description!)
                    : null,
                trailing: project.budget != null
                    ? Text(
                        '${_formatCurrency(project.budget!)} VND',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      )
                    : null,
                onTap: () {
                  // TODO: Project detail screen
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(color: Colors.grey[600]),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      color: color.withOpacity(0.1),
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(GroupMemberRole role) {
    switch (role) {
      case GroupMemberRole.admin:
        return Colors.red;
      case GroupMemberRole.editor:
        return Colors.blue;
      case GroupMemberRole.viewer:
        return Colors.grey;
    }
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }

}

