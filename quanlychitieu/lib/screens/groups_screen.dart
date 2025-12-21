/// Màn hình quản lý Nhóm/Doanh nghiệp
/// Hiển thị danh sách nhóm user tham gia và cho phép tạo nhóm mới
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/group_provider.dart';
import '../providers/auth_provider.dart';
import '../models/group.dart';
import 'create_group_screen.dart';
import 'group_detail_screen.dart';

class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhóm của tôi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
            ).then((group) {
              if (group != null) {
                // Chọn nhóm vừa tạo
                context.read<GroupProvider>().selectGroup(group as Group);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GroupDetailScreen(group: group),
                  ),
                );
              }
            }),
            tooltip: 'Tạo nhóm mới',
          ),
        ],
      ),
      body: Consumer<GroupProvider>(
        builder: (context, groupProvider, child) {
          if (groupProvider.groups.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.group_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Bạn chưa tham gia nhóm nào',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tạo nhóm mới để bắt đầu quản lý chi tiêu nhóm',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Tạo nhóm mới'),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreateGroupScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: groupProvider.groups.length,
            itemBuilder: (context, index) {
              final group = groupProvider.groups[index];
              final currentUser = context.read<AuthProvider>().currentUser;
              final isAdmin = group.isAdmin(currentUser?.id ?? '');
              final memberCount = group.members.length;
              final projectCount = group.projectIds.length;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: const Icon(Icons.group, color: Colors.white),
                  ),
                  title: Text(
                    group.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (group.description != null)
                        Text(
                          group.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.people, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '$memberCount thành viên',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.folder, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '$projectCount dự án',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      if (isAdmin)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Quản trị viên',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.orange[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    groupProvider.selectGroup(group);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GroupDetailScreen(group: group),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

