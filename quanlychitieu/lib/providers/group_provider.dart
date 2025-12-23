/// Provider quản lý Nhóm/Doanh nghiệp
/// Xử lý tất cả logic liên quan đến nhóm: tạo, mời thành viên, quản lý quyền
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/group.dart';
import '../models/project.dart';
import '../models/approval_request.dart';
import '../models/audit_log.dart';
import 'auth_provider.dart';

class GroupProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthProvider authProvider;

  List<Group> _groups = [];
  Group? _currentGroup;
  List<Project> _projects = [];
  List<ApprovalRequest> _pendingApprovals = [];
  StreamSubscription? _groupsSubscription;
  StreamSubscription? _projectsSubscription;
  StreamSubscription? _approvalsSubscription;

  List<Group> get groups => _groups;
  Group? get currentGroup => _currentGroup;
  List<Project> get projects => _projects;
  List<ApprovalRequest> get pendingApprovals => _pendingApprovals;

  GroupProvider(this.authProvider) {
    authProvider.addListener(_onAuthChanged);
    _onAuthChanged();
  }

  void _onAuthChanged() {
    if (authProvider.isLoggedIn) {
      _listenToGroups();
    } else {
      _groups = [];
      _currentGroup = null;
      _projects = [];
      _pendingApprovals = [];
      _groupsSubscription?.cancel();
      _projectsSubscription?.cancel();
      _approvalsSubscription?.cancel();
      notifyListeners();
    }
  }

  /// Lắng nghe danh sách nhóm của user
  void _listenToGroups() {
    final userId = authProvider.currentUser?.id;
    if (userId == null) return;

    _groupsSubscription?.cancel();
    // Lưu ý: Firestore không hỗ trợ query trực tiếp array of objects
    // Nên query tất cả groups và filter trong code
    _groupsSubscription = _firestore
        .collection('groups')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      _groups = snapshot.docs
          .map((doc) => Group.fromFirestore(doc))
          .where((group) => 
            // Kiểm tra user là người tạo hoặc có trong members
            group.createdBy == userId || 
            group.members.any((m) => m.userId == userId)
          )
          .toList();
      notifyListeners();
    });
  }

  /// Làm mới danh sách nhóm thủ công (ví dụ pull-to-refresh)
  Future<void> refreshGroups() async {
    _listenToGroups();
  }

  /// Tạo nhóm mới
  Future<Group> createGroup({
    required String name,
    String? description,
  }) async {
    final userId = authProvider.currentUser?.id;
    if (userId == null) throw Exception('Người dùng chưa đăng nhập');

    final now = DateTime.now();
    final creator = GroupMember(
      userId: userId,
      email: authProvider.currentUser!.email,
      username: authProvider.currentUser!.username,
      role: GroupMemberRole.admin,
      joinedAt: now,
    );

    final group = Group(
      name: name,
      description: description,
      createdBy: userId,
      createdAt: now,
      updatedAt: now,
      members: [creator],
    );

    final docRef = await _firestore.collection('groups').add(group.toJson());
    final createdGroup = Group.fromFirestore(
      await docRef.get(),
    );

    // Tạo audit log
    await _createAuditLog(
      groupId: createdGroup.id!,
      action: AuditAction.groupUpdated,
      description: 'Nhóm được tạo: $name',
    );

    return createdGroup;
  }

  /// Mời thành viên vào nhóm (tạo invitation link)
  Future<String> inviteMember({
    required String groupId,
    required String email,
    GroupMemberRole role = GroupMemberRole.viewer,
  }) async {
    // Tạo dynamic link (sẽ implement sau với Firebase Dynamic Links)
    // Tạm thời trả về invitation code
    final invitationCode = _generateInvitationCode();
    
    await _firestore.collection('group_invitations').add({
      'groupId': groupId,
      'email': email,
      'role': role.name,
      'invitedBy': authProvider.currentUser?.id,
      'createdAt': Timestamp.now(),
      'code': invitationCode,
      'used': false,
    });

    // Tạo audit log
    await _createAuditLog(
      groupId: groupId,
      action: AuditAction.memberAdded,
      description: 'Mời thành viên: $email với vai trò ${role.name}',
    );

    return invitationCode;
  }

  /// Tham gia nhóm bằng invitation code
  Future<void> joinGroup(String invitationCode) async {
    final userId = authProvider.currentUser?.id;
    if (userId == null) throw Exception('Người dùng chưa đăng nhập');

    final invitations = await _firestore
        .collection('group_invitations')
        .where('code', isEqualTo: invitationCode)
        .where('used', isEqualTo: false)
        .limit(1)
        .get();

    if (invitations.docs.isEmpty) {
      throw Exception('Mã mời không hợp lệ hoặc đã được sử dụng');
    }

    final invitation = invitations.docs.first.data();
    final groupId = invitation['groupId'] as String;
    final role = GroupMemberRole.values.firstWhere(
      (e) => e.name == invitation['role'],
      orElse: () => GroupMemberRole.viewer,
    );

    // Thêm member vào group
    final groupRef = _firestore.collection('groups').doc(groupId);
    final groupDoc = await groupRef.get();
    if (!groupDoc.exists) {
      throw Exception('Nhóm không tồn tại');
    }

    final group = Group.fromFirestore(groupDoc);
    final newMember = GroupMember(
      userId: userId,
      email: authProvider.currentUser!.email,
      username: authProvider.currentUser!.username,
      role: role,
      joinedAt: DateTime.now(),
      invitedBy: invitation['invitedBy'] as String?,
    );

    final updatedMembers = [...group.members, newMember];
    await groupRef.update({
      'members': updatedMembers.map((m) => m.toJson()).toList(),
      'updatedAt': Timestamp.now(),
    });

    // Đánh dấu invitation đã sử dụng
    await invitations.docs.first.reference.update({'used': true});

    // Tạo audit log
    await _createAuditLog(
      groupId: groupId,
      action: AuditAction.memberAdded,
      description: '${authProvider.currentUser!.username} đã tham gia nhóm',
    );
  }

  /// Chọn nhóm hiện tại
  void selectGroup(Group group) {
    _currentGroup = group;
    _listenToProjects(group.id!);
    _listenToApprovals(group.id!);
    notifyListeners();
  }

  /// Lắng nghe danh sách dự án
  void _listenToProjects(String groupId) {
    _projectsSubscription?.cancel();
    _projectsSubscription = _firestore
        .collection('projects')
        .where('groupId', isEqualTo: groupId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      _projects = snapshot.docs
          .map((doc) => Project.fromFirestore(doc))
          .toList();
      notifyListeners();
    });
  }

  /// Lắng nghe yêu cầu phê duyệt
  void _listenToApprovals(String groupId) {
    final userId = authProvider.currentUser?.id;
    if (userId == null) return;

    _approvalsSubscription?.cancel();
    _approvalsSubscription = _firestore
        .collection('approval_requests')
        .where('groupId', isEqualTo: groupId)
        .where('status', isEqualTo: ApprovalStatus.pending.name)
        .snapshots()
        .listen((snapshot) {
      _pendingApprovals = snapshot.docs
          .map((doc) => ApprovalRequest.fromFirestore(doc))
          .toList();
      notifyListeners();
    });
  }

  /// Tạo dự án mới
  Future<Project> createProject({
    required String groupId,
    required String name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    double? budget,
  }) async {
    final userId = authProvider.currentUser?.id;
    if (userId == null) throw Exception('Người dùng chưa đăng nhập');

    final project = Project(
      groupId: groupId,
      name: name,
      description: description,
      createdBy: userId,
      createdAt: DateTime.now(),
      startDate: startDate,
      endDate: endDate,
      budget: budget,
    );

    final docRef = await _firestore.collection('projects').add(project.toJson());
    final createdProject = Project.fromFirestore(await docRef.get());

    // Cập nhật projectIds trong group
    final group = _groups.firstWhere((g) => g.id == groupId);
    await _firestore.collection('groups').doc(groupId).update({
      'projectIds': FieldValue.arrayUnion([createdProject.id]),
      'updatedAt': Timestamp.now(),
    });

    // Tạo audit log
    await _createAuditLog(
      groupId: groupId,
      action: AuditAction.projectCreated,
      description: 'Tạo dự án: $name',
      targetId: createdProject.id,
    );

    return createdProject;
  }

  /// Phê duyệt giao dịch
  Future<void> approveExpense({
    required String approvalRequestId,
    required String expenseId,
  }) async {
    final userId = authProvider.currentUser?.id;
    if (userId == null) throw Exception('Người dùng chưa đăng nhập');

    final batch = _firestore.batch();

    // Cập nhật approval request
    final approvalRef = _firestore.collection('approval_requests').doc(approvalRequestId);
    batch.update(approvalRef, {
      'status': ApprovalStatus.approved.name,
      'approvedBy': userId,
      'reviewedAt': Timestamp.now(),
    });

    // Cập nhật expense
    final expenseRef = _firestore.collection('expenses').doc(expenseId);
    batch.update(expenseRef, {
      'isApproved': true,
      'approvedBy': userId,
    });

    await batch.commit();

    // Tạo audit log
    final approval = _pendingApprovals.firstWhere((a) => a.id == approvalRequestId);
    await _createAuditLog(
      groupId: approval.groupId,
      action: AuditAction.expenseApproved,
      description: 'Phê duyệt giao dịch: $expenseId',
      targetId: expenseId,
    );
  }

  /// Từ chối giao dịch
  Future<void> rejectExpense({
    required String approvalRequestId,
    required String reason,
  }) async {
    final userId = authProvider.currentUser?.id;
    if (userId == null) throw Exception('Người dùng chưa đăng nhập');

    final approvalRef = _firestore.collection('approval_requests').doc(approvalRequestId);
    await approvalRef.update({
      'status': ApprovalStatus.rejected.name,
      'approvedBy': userId,
      'reason': reason,
      'reviewedAt': Timestamp.now(),
    });

    // Tạo audit log
    final approval = _pendingApprovals.firstWhere((a) => a.id == approvalRequestId);
    await _createAuditLog(
      groupId: approval.groupId,
      action: AuditAction.expenseRejected,
      description: 'Từ chối giao dịch: ${approval.expenseId}. Lý do: $reason',
      targetId: approval.expenseId,
    );
  }

  /// Tạo audit log
  Future<void> _createAuditLog({
    required String groupId,
    required AuditAction action,
    required String description,
    String? targetId,
    Map<String, dynamic>? metadata,
  }) async {
    final userId = authProvider.currentUser?.id;
    if (userId == null) return;

    await _firestore.collection('audit_logs').add(
      AuditLog(
        groupId: groupId,
        action: action,
        userId: userId,
        targetId: targetId,
        description: description,
        metadata: metadata,
        timestamp: DateTime.now(),
      ).toJson(),
    );
  }

  /// Tạo mã mời ngẫu nhiên
  String _generateInvitationCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return List.generate(8, (index) {
      return chars[(random + index) % chars.length];
    }).join();
  }

  @override
  void dispose() {
    _groupsSubscription?.cancel();
    _projectsSubscription?.cancel();
    _approvalsSubscription?.cancel();
    authProvider.removeListener(_onAuthChanged);
    super.dispose();
  }
}

