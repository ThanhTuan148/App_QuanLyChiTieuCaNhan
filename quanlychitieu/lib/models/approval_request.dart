/// Mô hình dữ liệu cho Yêu cầu Phê duyệt Giao dịch
import 'package:cloud_firestore/cloud_firestore.dart';

enum ApprovalStatus {
  pending,   // Đang chờ phê duyệt
  approved,  // Đã phê duyệt
  rejected,  // Đã từ chối
}

class ApprovalRequest {
  final String? id;
  final String expenseId; // ID của giao dịch cần phê duyệt
  final String groupId;
  final String requestedBy; // ID người yêu cầu
  final String? approvedBy; // ID người phê duyệt (null nếu chưa)
  final ApprovalStatus status;
  final String? reason; // Lý do từ chối (nếu có)
  final DateTime requestedAt;
  final DateTime? reviewedAt; // Thời điểm phê duyệt/từ chối

  ApprovalRequest({
    this.id,
    required this.expenseId,
    required this.groupId,
    required this.requestedBy,
    this.approvedBy,
    required this.status,
    this.reason,
    required this.requestedAt,
    this.reviewedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'expenseId': expenseId,
      'groupId': groupId,
      'requestedBy': requestedBy,
      'approvedBy': approvedBy,
      'status': status.name,
      'reason': reason,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
    };
  }

  factory ApprovalRequest.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ApprovalRequest(
      id: doc.id,
      expenseId: data['expenseId'] ?? '',
      groupId: data['groupId'] ?? '',
      requestedBy: data['requestedBy'] ?? '',
      approvedBy: data['approvedBy'],
      status: ApprovalStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => ApprovalStatus.pending,
      ),
      reason: data['reason'],
      requestedAt: (data['requestedAt'] as Timestamp).toDate(),
      reviewedAt: (data['reviewedAt'] as Timestamp?)?.toDate(),
    );
  }

  ApprovalRequest copyWith({
    String? approvedBy,
    ApprovalStatus? status,
    String? reason,
    DateTime? reviewedAt,
  }) {
    return ApprovalRequest(
      id: id,
      expenseId: expenseId,
      groupId: groupId,
      requestedBy: requestedBy,
      approvedBy: approvedBy ?? this.approvedBy,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      requestedAt: requestedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
    );
  }
}

