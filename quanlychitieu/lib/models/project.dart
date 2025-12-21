/// Mô hình dữ liệu cho Dự án trong nhóm
import 'package:cloud_firestore/cloud_firestore.dart';

class Project {
  final String? id;
  final String groupId;
  final String name;
  final String? description;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? budget; // Ngân sách dự án
  final bool isActive;

  Project({
    this.id,
    required this.groupId,
    required this.name,
    this.description,
    required this.createdBy,
    required this.createdAt,
    this.startDate,
    this.endDate,
    this.budget,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'groupId': groupId,
      'name': name,
      'description': description,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'budget': budget,
      'isActive': isActive,
    };
  }

  factory Project.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Project(
      id: doc.id,
      groupId: data['groupId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'],
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      startDate: (data['startDate'] as Timestamp?)?.toDate(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      budget: (data['budget'] as num?)?.toDouble(),
      isActive: data['isActive'] ?? true,
    );
  }

  Project copyWith({
    String? name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    double? budget,
    bool? isActive,
  }) {
    return Project(
      id: id,
      groupId: groupId,
      name: name ?? this.name,
      description: description ?? this.description,
      createdBy: createdBy,
      createdAt: createdAt,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      budget: budget ?? this.budget,
      isActive: isActive ?? this.isActive,
    );
  }
}

