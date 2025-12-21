/// Provider quản lý lịch sử chat với AI
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message_model.dart';
import 'auth_provider.dart';

class ChatHistoryProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthProvider authProvider;

  List<ChatMessageModel> _chatHistory = [];
  StreamSubscription? _chatHistorySubscription;
  bool _isLoading = false;
  bool _disposed = false;

  List<ChatMessageModel> get chatHistory => _chatHistory;
  bool get isLoading => _isLoading;

  ChatHistoryProvider(this.authProvider) {
    authProvider.addListener(_onAuthChanged);
    _onAuthChanged();
  }

  void _onAuthChanged() {
    if (_disposed) return; // Không xử lý nếu đã dispose
    
    if (authProvider.isLoggedIn) {
      _listenToChatHistory();
    } else {
      _chatHistory = [];
      _chatHistorySubscription?.cancel();
      if (!_disposed) {
        notifyListeners();
      }
    }
  }

  /// Lắng nghe lịch sử chat từ Firestore
  void _listenToChatHistory() {
    if (_disposed) return; // Không xử lý nếu đã dispose
    
    final userId = authProvider.currentUser?.id;
    if (userId == null) return;

    _chatHistorySubscription?.cancel();
    _isLoading = true;
    if (!_disposed) {
      notifyListeners();
    }

    // Không dùng orderBy để tránh cần composite index
    // Sẽ sort client-side thay vì
    _chatHistorySubscription = _firestore
        .collection('chat_history')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen(
      (snapshot) {
        if (_disposed) return; // Không xử lý nếu đã dispose
        
        _isLoading = false;
        _chatHistory = snapshot.docs
            .map((doc) => ChatMessageModel.fromFirestore(doc))
            .toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp)); // Sort ascending để hiển thị đúng thứ tự
        // Giới hạn 100 tin nhắn gần nhất (client-side)
        if (_chatHistory.length > 100) {
          _chatHistory = _chatHistory.sublist(_chatHistory.length - 100);
        }
        if (!_disposed) {
          notifyListeners();
        }
      },
      onError: (error) {
        if (_disposed) return; // Không xử lý nếu đã dispose
        
        _isLoading = false;
        debugPrint('Error listening to chat history: $error');
        if (!_disposed) {
          notifyListeners();
        }
      },
    );
  }

  /// Lưu tin nhắn vào lịch sử
  Future<void> saveMessage({
    required String message,
    String? response,
    Map<String, dynamic>? context,
  }) async {
    if (_disposed) return; // Không xử lý nếu đã dispose
    
    final userId = authProvider.currentUser?.id;
    if (userId == null) return;

    try {
      final chatMessage = ChatMessageModel(
        userId: userId,
        message: message,
        response: response,
        timestamp: DateTime.now(),
        context: context,
      );

      await _firestore
          .collection('chat_history')
          .add(chatMessage.toFirestore());
    } catch (e) {
      debugPrint('Error saving chat message: $e');
    }
  }

  /// Cập nhật response cho tin nhắn vừa gửi
  Future<void> updateMessageResponse({
    required String message,
    required String response,
  }) async {
    if (_disposed) return; // Không xử lý nếu đã dispose
    
    final userId = authProvider.currentUser?.id;
    if (userId == null) return;

    try {
      // Không dùng orderBy để tránh cần composite index
      // Lấy tất cả tin nhắn của user và sort client-side
      final query = await _firestore
          .collection('chat_history')
          .where('userId', isEqualTo: userId)
          .get();

      // Sort theo timestamp descending và tìm tin nhắn chưa có response
      final docs = query.docs.toList()
        ..sort((a, b) {
          final aTime = (a.data()['timestamp'] as Timestamp?)?.toDate() ?? DateTime(1970);
          final bTime = (b.data()['timestamp'] as Timestamp?)?.toDate() ?? DateTime(1970);
          return bTime.compareTo(aTime); // Descending
        });

      // Tìm tin nhắn đầu tiên có message khớp và chưa có response
      for (var doc in docs.take(20)) { // Chỉ xét 20 tin nhắn gần nhất
        final data = doc.data();
        if (data['message'] == message && 
            (data['response'] == null || (data['response'] as String).isEmpty)) {
          await _firestore
              .collection('chat_history')
              .doc(doc.id)
              .update({'response': response});
          return;
        }
      }
    } catch (e) {
      debugPrint('Error updating message response: $e');
    }
  }

  /// Xóa một tin nhắn
  Future<void> deleteMessage(String messageId) async {
    try {
      await _firestore.collection('chat_history').doc(messageId).delete();
    } catch (e) {
      debugPrint('Error deleting chat message: $e');
    }
  }

  /// Xóa toàn bộ lịch sử chat
  Future<void> clearHistory() async {
    if (_disposed) return; // Không xử lý nếu đã dispose
    
    final userId = authProvider.currentUser?.id;
    if (userId == null) return;

    try {
      final batch = _firestore.batch();
      final query = await _firestore
          .collection('chat_history')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in query.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error clearing chat history: $e');
    }
  }

  @override
  void dispose() {
    _disposed = true; // Đánh dấu đã dispose trước
    _chatHistorySubscription?.cancel();
    _chatHistorySubscription = null;
    try {
      authProvider.removeListener(_onAuthChanged);
    } catch (e) {
      // Ignore nếu listener đã bị remove
      debugPrint('Error removing listener: $e');
    }
    super.dispose();
  }
}

