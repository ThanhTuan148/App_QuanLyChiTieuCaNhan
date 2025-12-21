/// Mô hình dữ liệu cho Nhóm/Doanh nghiệp
/// Quản lý nhóm người dùng làm việc cùng nhau
import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum định nghĩa vai trò của thành viên trong nhóm
enum GroupMemberRole {
  admin,    // Quản trị viên - có quyền cao nhất
  editor,   // Biên tập viên - có thể thêm/sửa giao dịch
  viewer,   // Người xem - chỉ xem, không chỉnh sửa
}

/// Mô hình thành viên trong nhóm
class GroupMember {
  final String userId;
  final String email;
  final String username;
  final GroupMemberRole role;
  final DateTime joinedAt;
  final String? invitedBy; // ID của người mời

  GroupMember({
    required this.userId,
    required this.email,
    required this.username,
    required this.role,
    required this.joinedAt,
    this.invitedBy,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'email': email,
      'username': username,
      'role': role.name,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'invitedBy': invitedBy,
    };
  }

  factory GroupMember.fromFirestore(Map<String, dynamic> data) {
    return GroupMember(
      userId: data['userId'] ?? '',
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      role: GroupMemberRole.values.firstWhere(
        (e) => e.name == data['role'],
        orElse: () => GroupMemberRole.viewer,
      ),
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      invitedBy: data['invitedBy'],
    );
  }
}

/// Mô hình Nhóm/Doanh nghiệp
class Group {
  final String? id;
  final String name;
  final String? description;
  final String createdBy; // ID của người tạo
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<GroupMember> members;
  final List<String> projectIds; // Danh sách ID các dự án
  final bool isActive;

  Group({
    this.id,
    required this.name,
    this.description,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.members,
    this.projectIds = const [],
    this.isActive = true,
  });

  /// Lấy danh sách admin
  List<GroupMember> get admins {
    return members.where((m) => m.role == GroupMemberRole.admin).toList();
  }

  /// Kiểm tra user có phải admin không
  bool isAdmin(String userId) {
    return members.any((m) => m.userId == userId && m.role == GroupMemberRole.admin);
  }

  /// Kiểm tra user có quyền editor không
  bool canEdit(String userId) {
    final member = members.firstWhere(
      (m) => m.userId == userId,
      orElse: () => GroupMember(
        userId: '',
        email: '',
        username: '',
        role: GroupMemberRole.viewer,
        joinedAt: DateTime.now(),
      ),
    );
    return member.role == GroupMemberRole.admin || member.role == GroupMemberRole.editor;
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'members': members.map((m) => m.toJson()).toList(),
      'projectIds': projectIds,
      'isActive': isActive,
    };
  }

  factory Group.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Group(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'],
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      members: (data['members'] as List<dynamic>?)
              ?.map((m) => GroupMember.fromFirestore(m as Map<String, dynamic>))
              .toList() ??
          [],
      projectIds: List<String>.from(data['projectIds'] ?? []),
      isActive: data['isActive'] ?? true,
    );
  }

  Group copyWith({
    String? name,
    String? description,
    List<GroupMember>? members,
    List<String>? projectIds,
    bool? isActive,
  }) {
    return Group(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      members: members ?? this.members,
      projectIds: projectIds ?? this.projectIds,
      isActive: isActive ?? this.isActive,
    );
  }
}

