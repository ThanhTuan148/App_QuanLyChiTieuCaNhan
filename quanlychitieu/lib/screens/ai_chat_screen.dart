/// Màn hình Chatbox AI sử dụng Grok API
/// Cho phép người dùng chat với AI để tư vấn về quản lý chi tiêu

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/groq_ai_service.dart'; // Sử dụng Groq (miễn phí, không cần thẻ tín dụng)
// import '../services/gemini_ai_service.dart'; // Hoặc dùng Gemini
// import '../services/grok_ai_service.dart'; // Hoặc dùng Grok
import '../providers/expense_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_history_provider.dart';
import '../models/chat_message_model.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  // Sử dụng Groq AI (miễn phí, không cần thẻ tín dụng, nhanh)
  final GroqAIService _aiService = GroqAIService();
  // final GeminiAIService _aiService = GeminiAIService(); // Hoặc dùng Gemini
  // final GrokAIService _aiService = GrokAIService(); // Hoặc dùng Grok
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Load lịch sử chat từ Firestore
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChatHistory();
    });
  }

  /// Load lịch sử chat từ Firestore
  void _loadChatHistory() {
    final chatHistoryProvider = context.read<ChatHistoryProvider>();
    
    // Sử dụng Consumer để lắng nghe thay đổi từ provider
    // Đợi một chút để provider load xong
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      
      final history = chatHistoryProvider.chatHistory;

      if (history.isEmpty) {
        // Nếu chưa có lịch sử, hiển thị welcome message
        if (mounted) {
          setState(() {
            _messages.clear();
            _addWelcomeMessage();
          });
        }
      } else {
        // Load lịch sử vào UI
        if (mounted) {
          setState(() {
            _messages.clear();
            for (var chatMsg in history) {
              // Thêm tin nhắn của user
              _messages.add(ChatMessage(
                text: chatMsg.message,
                isUser: true,
              ));
              // Thêm phản hồi từ AI (nếu có)
              if (chatMsg.response != null && chatMsg.response!.isNotEmpty) {
                _messages.add(ChatMessage(
                  text: chatMsg.response!,
                  isUser: false,
                ));
              }
            }
          });
          // Scroll xuống cuối
          _scrollToBottom();
        }
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add(
        ChatMessage(
          text: 'Xin chào! Tôi là trợ lý AI của bạn. Tôi có thể giúp bạn:\n'
              '• Phân tích xu hướng chi tiêu\n'
              '• Tư vấn về ngân sách\n'
              '• Dự đoán chi tiêu tương lai\n'
              '• Trả lời câu hỏi về tài chính cá nhân\n\n'
              'Bạn muốn hỏi gì?',
          isUser: false,
        ),
      );
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _messageController.clear();
      _isLoading = true;
    });

    _scrollToBottom();

    // Lấy ngữ cảnh về chi tiêu của người dùng
    final expenseProvider = context.read<ExpenseProvider>();
    final expenses = expenseProvider.expenses;
    
    final totalExpense = expenses
        .where((e) => !e.isIncome)
        .fold(0.0, (sum, e) => sum + e.amount);
    final totalIncome = expenses
        .where((e) => e.isIncome)
        .fold(0.0, (sum, e) => sum + e.amount);

    final contextData = {
      'totalExpense': totalExpense,
      'totalIncome': totalIncome,
    };

    // Lưu tin nhắn vào lịch sử (chưa có response)
    final chatHistoryProvider = context.read<ChatHistoryProvider>();
    await chatHistoryProvider.saveMessage(
      message: text,
      response: null, // Sẽ cập nhật sau khi có response
      context: contextData,
    );

    try {
      final response = await _aiService.chat(
        message: text,
        context: contextData,
      );

      setState(() {
        _isLoading = false;
        if (response != null) {
          _messages.add(ChatMessage(text: response, isUser: false));
          
          // Cập nhật response vào lịch sử
          chatHistoryProvider.updateMessageResponse(
            message: text,
            response: response,
          );
        } else {
          final errorMsg = 'Xin lỗi, tôi không thể trả lời ngay bây giờ. Vui lòng thử lại sau.';
          _messages.add(ChatMessage(text: errorMsg, isUser: false));
          
          // Cập nhật error message vào lịch sử
          chatHistoryProvider.updateMessageResponse(
            message: text,
            response: errorMsg,
          );
        }
      });
    } catch (e) {
      final errorMsg = 'Đã xảy ra lỗi: $e';
      setState(() {
        _isLoading = false;
        _messages.add(ChatMessage(text: errorMsg, isUser: false));
      });
      
      // Cập nhật error vào lịch sử
      chatHistoryProvider.updateMessageResponse(
        message: text,
        response: errorMsg,
      );
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendQuickQuestion(String question) {
    _messageController.text = question;
    _sendMessage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trợ lý AI'),
        actions: [
          // Xóa lịch sử chat
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _showClearHistoryDialog(context),
            tooltip: 'Xóa lịch sử',
          ),
          // Bắt đầu lại (chỉ clear UI, không xóa lịch sử)
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _messages.clear();
                _addWelcomeMessage();
              });
            },
            tooltip: 'Bắt đầu lại',
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick questions
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickQuestionButton('Tư vấn ngân sách'),
                  const SizedBox(width: 8),
                  _buildQuickQuestionButton('Phân tích chi tiêu'),
                  const SizedBox(width: 8),
                  _buildQuickQuestionButton('Lời khuyên tiết kiệm'),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return const _LoadingIndicator();
                }
                return _ChatBubble(message: _messages[index]);
              },
            ),
          ),
          // Input area
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Nhập câu hỏi...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    onPressed: _isLoading ? null : _sendMessage,
                    color: Theme.of(context).primaryColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickQuestionButton(String text) {
    return OutlinedButton(
      onPressed: () => _sendQuickQuestion(text),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }

  /// Hiển thị dialog xác nhận xóa lịch sử
  void _showClearHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa lịch sử chat'),
        content: const Text('Bạn có chắc muốn xóa toàn bộ lịch sử chat? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await context.read<ChatHistoryProvider>().clearHistory();
              if (context.mounted) {
                Navigator.pop(context);
                setState(() {
                  _messages.clear();
                  _addWelcomeMessage();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xóa lịch sử chat')),
                );
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.smart_toy, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: message.isUser
                    ? null
                    : Border.all(
                        color: Theme.of(context).dividerColor,
                        width: 1,
                      ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser ? Colors.white : null,
                ),
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.secondary,
              child: const Icon(Icons.person, size: 18, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(context).primaryColor,
            child: const Icon(Icons.smart_toy, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
            child: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ],
      ),
    );
  }
}

