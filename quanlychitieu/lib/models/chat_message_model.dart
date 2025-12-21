/// Model cho Chat Message với AI
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageModel {
  final String? id;
  final String userId;
  final String message; // Tin nhắn của user
  final String? response; // Phản hồi từ AI
  final DateTime timestamp;
  final Map<String, dynamic>? context; // Ngữ cảnh khi gửi (totalExpense, totalIncome, etc.)

  ChatMessageModel({
    this.id,
    required this.userId,
    required this.message,
    this.response,
    required this.timestamp,
    this.context,
  });

  /// Tạo từ Firestore document
  factory ChatMessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessageModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      message: data['message'] ?? '',
      response: data['response'],
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      context: data['context'] != null ? Map<String, dynamic>.from(data['context']) : null,
    );
  }

  /// Chuyển thành JSON để lưu vào Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'message': message,
      'response': response,
      'timestamp': Timestamp.fromDate(timestamp),
      'context': context,
    };
  }

  /// Tạo bản copy với các thay đổi
  ChatMessageModel copyWith({
    String? id,
    String? userId,
    String? message,
    String? response,
    DateTime? timestamp,
    Map<String, dynamic>? context,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      message: message ?? this.message,
      response: response ?? this.response,
      timestamp: timestamp ?? this.timestamp,
      context: context ?? this.context,
    );
  }
}

