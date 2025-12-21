/// Service tích hợp Groq API (MIỄN PHÍ, KHÔNG CẦN THẺ TÍN DỤNG)
/// Groq sử dụng Llama, Mixtral models - hoàn toàn miễn phí và nhanh
/// 
/// Đăng ký tại: https://console.groq.com/

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;

/// Service quản lý tích hợp Groq AI (Miễn phí, không cần thẻ tín dụng)
class GroqAIService {
  // API key từ Groq (hoàn toàn miễn phí)
  // Lấy từ environment variable hoặc secure storage
  // 
  // CÁCH CẤU HÌNH:
  // 1. Sử dụng environment variable (khuyến nghị):
  //    Windows: set GROQ_API_KEY=your-key-here
  //    Linux/Mac: export GROQ_API_KEY=your-key-here
  // 2. Hoặc sửa trực tiếp dòng dưới (chỉ để test, không commit vào Git):
  static const String _hardcodedApiKey = ''; // ⚠️ KHÔNG commit API key vào Git!
  
  static String get _apiKey {
    // Ưu tiên: Lấy từ environment variable
    const envKey = String.fromEnvironment('GROQ_API_KEY', defaultValue: '');
    if (envKey.isNotEmpty) {
      return envKey;
    }
    
    // Fallback: Sử dụng hardcoded key (chỉ để test)
    if (_hardcodedApiKey.isNotEmpty) {
      return _hardcodedApiKey;
    }
    
    // Nếu không có API key, trả về empty để sử dụng fallback response
    return '';
  }
  
  // Groq API endpoint và models
  // Models có sẵn: llama-3.1-8b-instant, mixtral-8x7b-32768, llama-3.1-70b-versatile
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama-3.1-8b-instant'; // Nhanh, miễn phí
  // Hoặc: 'mixtral-8x7b-32768' (chất lượng cao hơn)
  
  /// Gửi tin nhắn đến Groq AI và nhận phản hồi
  /// 
  /// Parameters:
  /// - message: Tin nhắn từ người dùng
  /// - context: Ngữ cảnh về chi tiêu của người dùng (tùy chọn)
  /// 
  /// Returns:
  /// - Phản hồi từ AI, null nếu có lỗi
  Future<String?> chat({
    required String message,
    Map<String, dynamic>? context,
  }) async {
    // Nếu chưa có API key, trả về response mẫu
    if (_apiKey.isEmpty) {
      return _getFallbackResponse(message, context);
    }

    try {
      // Xây dựng system prompt với ngữ cảnh về quản lý chi tiêu
      final systemPrompt = _buildSystemPrompt(context);
      
      // Groq API format (tương tự OpenAI)
      final requestBody = {
        'model': _model,
        'messages': [
          {
            'role': 'system',
            'content': systemPrompt,
          },
          {
            'role': 'user',
            'content': message,
          },
        ],
        'temperature': 0.7,
        'max_tokens': 1024,
      };

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json',
          'Accept-Charset': 'utf-8',
        },
        body: utf8.encode(jsonEncode(requestBody)),
        encoding: utf8,
      );

      if (response.statusCode == 200) {
        // Đảm bảo decode đúng UTF-8
        final responseBody = utf8.decode(response.bodyBytes);
        final data = jsonDecode(responseBody);
        final content = data['choices'][0]['message']['content'];
        
        // Đảm bảo content là UTF-8 string
        if (content is String) {
          return content;
        }
        return content.toString();
      } else {
        debugPrint('Lỗi từ Groq API: ${response.statusCode} - ${response.body}');
        
        // Xử lý lỗi cụ thể
        try {
          // Đảm bảo decode đúng UTF-8
          final responseBody = utf8.decode(response.bodyBytes);
          final errorData = jsonDecode(responseBody);
          final errorMessage = errorData['error']?['message'] ?? errorData['message'] ?? 'Unknown error';
          
          // Lỗi 401: API key không hợp lệ
          if (response.statusCode == 401) {
            return '''⚠️ **Lỗi: API key không hợp lệ**

Vui lòng kiểm tra:
1. API key đã được copy đúng chưa
2. Tạo API key mới tại: https://console.groq.com/keys
3. Đảm bảo API key còn active

Xem hướng dẫn trong FREE_AI_OPTIONS_GUIDE.md''';
          }
          
          // Lỗi 429: Quá nhiều requests
          if (response.statusCode == 429) {
            return '''⚠️ **Lỗi: Quá nhiều requests**

Bạn đã vượt quá giới hạn free tier:
- 30 requests/phút
- 14,400 requests/ngày

Vui lòng đợi một chút và thử lại sau.''';
          }
          
          return '⚠️ Lỗi từ Groq API: $errorMessage\n\nVui lòng kiểm tra lại cấu hình hoặc xem hướng dẫn trong FREE_AI_OPTIONS_GUIDE.md';
        } catch (e) {
          return _getFallbackResponse(message, context);
        }
      }
    } catch (e) {
      debugPrint('Lỗi khi gọi Groq API: $e');
      return _getFallbackResponse(message, context);
    }
  }

  /// Trả về response mẫu khi chưa có API key
  String _getFallbackResponse(String message, Map<String, dynamic>? context) {
    final lowerMessage = message.toLowerCase();
    
    if (lowerMessage.contains('ngân sách') || lowerMessage.contains('budget')) {
      final totalExpense = context?['totalExpense'] ?? 0.0;
      final totalIncome = context?['totalIncome'] ?? 0.0;
      
      if (totalIncome > 0) {
        final ratio = (totalExpense / totalIncome * 100).toStringAsFixed(1);
        return '''Dựa trên dữ liệu của bạn:
• Tổng thu nhập: ${_formatCurrency(totalIncome)} VND
• Tổng chi tiêu: ${_formatCurrency(totalExpense)} VND
• Tỷ lệ chi tiêu: $ratio%

Lời khuyên:
${totalExpense > totalIncome * 0.8 ? '⚠️ Bạn đang chi tiêu quá nhiều (>80% thu nhập). Nên cắt giảm chi tiêu không cần thiết.' : '✅ Tỷ lệ chi tiêu của bạn hợp lý. Nên tiết kiệm ít nhất 20% thu nhập.'}

Để cấu hình Groq API (miễn phí), vui lòng xem FREE_AI_OPTIONS_GUIDE.md''';
      }
      return 'Để tư vấn ngân sách chính xác, vui lòng cấu hình Groq API key (miễn phí). Xem hướng dẫn trong FREE_AI_OPTIONS_GUIDE.md';
    }
    
    if (lowerMessage.contains('phân tích') || lowerMessage.contains('chi tiêu')) {
      return '''Phân tích chi tiêu của bạn:
• Hãy xem phần Thống kê để biết chi tiết theo danh mục
• Sử dụng biểu đồ để so sánh các tháng
• Đặt ngân sách cho từng danh mục để kiểm soát tốt hơn

Để có phân tích AI chính xác, vui lòng cấu hình Groq API key (miễn phí).''';
    }
    
    if (lowerMessage.contains('tiết kiệm') || lowerMessage.contains('save')) {
      return '''Lời khuyên tiết kiệm:
1. Theo dõi chi tiêu hàng ngày
2. Đặt mục tiêu tiết kiệm cụ thể
3. Tự động chuyển tiền vào tài khoản tiết kiệm
4. Tránh mua sắm xung động
5. So sánh giá trước khi mua

Để có lời khuyên cá nhân hóa, vui lòng cấu hình Groq API key (miễn phí).''';
    }
    
    return '''Xin chào! Tôi là trợ lý AI của bạn.

Hiện tại tôi đang ở chế độ demo. Để sử dụng đầy đủ tính năng AI MIỄN PHÍ:
1. Đăng ký Groq API key tại: https://console.groq.com/keys
2. Cấu hình API key trong file lib/services/groq_ai_service.dart
3. Hoặc sử dụng environment variable GROQ_API_KEY

Groq API hoàn toàn MIỄN PHÍ với:
• 30 requests/phút
• 14,400 requests/ngày
• Không cần thẻ tín dụng
• Sử dụng Llama, Mixtral models (open source)

Bạn có thể hỏi tôi về:
• Tư vấn ngân sách
• Phân tích chi tiêu  
• Lời khuyên tiết kiệm

Xem hướng dẫn chi tiết trong FREE_AI_OPTIONS_GUIDE.md''';
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }

  /// Xây dựng system prompt với ngữ cảnh về chi tiêu
  String _buildSystemPrompt(Map<String, dynamic>? context) {
    var prompt = '''Bạn là một trợ lý AI chuyên tư vấn về quản lý chi tiêu cá nhân. 
Bạn giúp người dùng:
- Phân tích xu hướng chi tiêu
- Đưa ra lời khuyên về tiết kiệm
- Dự đoán chi tiêu tương lai
- Tư vấn về ngân sách
- Trả lời các câu hỏi về tài chính cá nhân

Hãy trả lời một cách thân thiện, dễ hiểu và bằng tiếng Việt.''';

    if (context != null) {
      if (context.containsKey('totalExpense')) {
        prompt += '\n\nTổng chi tiêu hiện tại: ${context['totalExpense']} VND';
      }
      if (context.containsKey('totalIncome')) {
        prompt += '\nTổng thu nhập: ${context['totalIncome']} VND';
      }
      if (context.containsKey('budget')) {
        prompt += '\nNgân sách: ${context['budget']} VND';
      }
      if (context.containsKey('topCategories')) {
        prompt += '\nCác danh mục chi tiêu nhiều nhất: ${context['topCategories']}';
      }
    }

    return prompt;
  }
}

