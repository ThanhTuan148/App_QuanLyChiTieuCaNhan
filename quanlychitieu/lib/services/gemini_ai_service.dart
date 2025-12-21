/// Service tích hợp Google Gemini API (MIỄN PHÍ)
/// Thay thế cho Grok API với free tier rộng rãi
/// 
/// Đăng ký tại: https://makersuite.google.com/app/apikey

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Service quản lý tích hợp Google Gemini AI (Miễn phí)
class GeminiAIService {
  // API key từ Google AI Studio
  // Lấy từ environment variable hoặc secure storage
  // 
  // CÁCH CẤU HÌNH:
  // 1. Sử dụng environment variable (khuyến nghị):
  //    Windows: set GEMINI_API_KEY=your-key-here
  //    Linux/Mac: export GEMINI_API_KEY=your-key-here
  // 2. Hoặc sửa trực tiếp dòng dưới (chỉ để test, không commit vào Git):
  static const String _hardcodedApiKey = 'AIzaSyDHNw0IPifT_CGcm5zhVETrq_kGZ_LBxEg'; // ⚠️ KHÔNG commit API key vào Git!
  
  static String get _apiKey {
    // Ưu tiên: Lấy từ environment variable
    const envKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
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
  
  // Sử dụng Gemini model (miễn phí)
  // Thử với API v1 (stable) - models mới hơn có trong v1
  // Nếu v1 không hoạt động, thử v1beta với gemini-pro
  static const String _apiVersion = 'v1beta';
  static const String _model = 'gemini-1.5-flash';
  static String get _baseUrl => 'https://generativelanguage.googleapis.com/$_apiVersion/models/$_model:generateContent';
  
  /// Gửi tin nhắn đến Gemini AI và nhận phản hồi
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
      
      // Gemini API format - sử dụng systemInstruction cho Gemini 1.5+
      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': message}
            ]
          }
        ],
        'systemInstruction': {
          'parts': [
            {'text': systemPrompt}
          ]
        },
        'generationConfig': {
          'temperature': 0.7,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 1024,
        },
      };

      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'];
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content']['parts'][0]['text'];
          return content;
        }
        return _getFallbackResponse(message, context);
      } else {
        debugPrint('Lỗi từ Gemini API: ${response.statusCode} - ${response.body}');
        
        // Xử lý lỗi cụ thể
        try {
          final errorData = jsonDecode(response.body);
          final errorMessage = errorData['error']?['message'] ?? 'Unknown error';
          
          // Lỗi 404: Model không tìm thấy
          if (response.statusCode == 404) {
            return '''⚠️ **Lỗi: Model không tìm thấy trong API v1beta**

Đang sử dụng model: $_model

**⚠️ QUAN TRỌNG:** Gemini 3.x (Gemini 3 Pro, Gemini 3 Flash) chưa có trong API v1beta!

**✅ Danh sách models có sẵn trong API v1beta:**
• gemini-1.5-flash (nhanh, miễn phí) - KHUYẾN NGHỊ
• gemini-1.5-pro (chất lượng cao, miễn phí)
• gemini-2.0-flash-exp (experimental)

**Giải pháp:**
1. Đổi model sang "gemini-1.5-flash" (đã được set mặc định)
2. Hoặc thử "gemini-1.5-pro" nếu muốn chất lượng cao hơn
3. Xem chi tiết: GEMINI_MODELS_LIST.md

Xem hướng dẫn trong FREE_AI_OPTIONS_GUIDE.md''';
          }
          
          // Lỗi 403: API key không hợp lệ hoặc chưa enable API
          if (response.statusCode == 403) {
            return '''⚠️ **Lỗi: API key không hợp lệ hoặc chưa enable API**

Vui lòng kiểm tra:
1. API key đã được copy đúng chưa
2. Đã enable Gemini API trong Google Cloud Console chưa
3. Tạo API key mới nếu cần

Hướng dẫn:
1. Vào: https://makersuite.google.com/app/apikey
2. Tạo API key mới
3. Enable "Generative Language API" trong Google Cloud Console

Xem hướng dẫn trong FREE_AI_OPTIONS_GUIDE.md''';
          }
          
          // Lỗi 429: Quá nhiều requests
          if (response.statusCode == 429) {
            return '''⚠️ **Lỗi: Quá nhiều requests**

Bạn đã vượt quá giới hạn free tier:
- 60 requests/phút
- 1,500 requests/ngày

Vui lòng đợi một chút và thử lại sau.''';
          }
          
          return '⚠️ Lỗi từ Gemini API: $errorMessage\n\nVui lòng kiểm tra lại cấu hình hoặc xem hướng dẫn trong FREE_AI_OPTIONS_GUIDE.md';
        } catch (e) {
          return _getFallbackResponse(message, context);
        }
      }
    } catch (e) {
      debugPrint('Lỗi khi gọi Gemini API: $e');
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

Để cấu hình Google Gemini API (miễn phí), vui lòng xem FREE_AI_OPTIONS_GUIDE.md''';
      }
      return 'Để tư vấn ngân sách chính xác, vui lòng cấu hình Google Gemini API key (miễn phí). Xem hướng dẫn trong FREE_AI_OPTIONS_GUIDE.md';
    }
    
    if (lowerMessage.contains('phân tích') || lowerMessage.contains('chi tiêu')) {
      return '''Phân tích chi tiêu của bạn:
• Hãy xem phần Thống kê để biết chi tiết theo danh mục
• Sử dụng biểu đồ để so sánh các tháng
• Đặt ngân sách cho từng danh mục để kiểm soát tốt hơn

Để có phân tích AI chính xác, vui lòng cấu hình Google Gemini API key (miễn phí).''';
    }
    
    if (lowerMessage.contains('tiết kiệm') || lowerMessage.contains('save')) {
      return '''Lời khuyên tiết kiệm:
1. Theo dõi chi tiêu hàng ngày
2. Đặt mục tiêu tiết kiệm cụ thể
3. Tự động chuyển tiền vào tài khoản tiết kiệm
4. Tránh mua sắm xung động
5. So sánh giá trước khi mua

Để có lời khuyên cá nhân hóa, vui lòng cấu hình Google Gemini API key (miễn phí).''';
    }
    
    return '''Xin chào! Tôi là trợ lý AI của bạn.

Hiện tại tôi đang ở chế độ demo. Để sử dụng đầy đủ tính năng AI MIỄN PHÍ:
1. Đăng ký Google Gemini API key tại: https://makersuite.google.com/app/apikey
2. Cấu hình API key trong file lib/services/gemini_ai_service.dart
3. Hoặc sử dụng environment variable GEMINI_API_KEY

Google Gemini API hoàn toàn MIỄN PHÍ với:
• 60 requests/phút
• 1,500 requests/ngày
• Không cần thẻ tín dụng

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

