/// Mô hình dữ liệu cho Audit Log (Lịch sử thay đổi)
/// Ghi lại mọi thay đổi trong nhóm để kiểm soát
import 'package:cloud_firestore/cloud_firestore.dart';

enum AuditAction {
  expenseCreated,
  expenseUpdated,
  expenseDeleted,
  expenseApproved,
  expenseRejected,
  memberAdded,
  memberRemoved,
  memberRoleChanged,
  groupUpdated,
  projectCreated,
  projectUpdated,
  projectDeleted,
}

class AuditLog {
  final String? id;
  final String groupId;
  final AuditAction action;
  final String userId; // Người thực hiện hành động
  final String? targetId; // ID của đối tượng bị thay đổi (expense, member, etc.)
  final String description; // Mô tả chi tiết
  final Map<String, dynamic>? metadata; // Dữ liệu bổ sung
  final DateTime timestamp;

  AuditLog({
    this.id,
    required this.groupId,
    required this.action,
    required this.userId,
    this.targetId,
    required this.description,
    this.metadata,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'groupId': groupId,
      'action': action.name,
      'userId': userId,
      'targetId': targetId,
      'description': description,
      'metadata': metadata,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory AuditLog.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AuditLog(
      id: doc.id,
      groupId: data['groupId'] ?? '',
      action: AuditAction.values.firstWhere(
        (e) => e.name == data['action'],
        orElse: () => AuditAction.expenseCreated,
      ),
      userId: data['userId'] ?? '',
      targetId: data['targetId'],
      description: data['description'] ?? '',
      metadata: data['metadata'] != null
          ? Map<String, dynamic>.from(data['metadata'])
          : null,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }
}

