/// Service tích hợp MoMo Payment
/// Xử lý thanh toán qua ví điện tử MoMo
/// 
/// Lưu ý: Cần đăng ký merchant tại https://business.momo.vn
/// để lấy merchantname, merchantcode, partnerCode

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:fluttertoast/fluttertoast.dart';

/// Service quản lý tích hợp MoMo Payment
class MoMoService {
  // Cấu hình MoMo (cần thay đổi khi deploy production)
  static const String _merchantName = 'YOUR_MERCHANT_NAME';
  static const String _merchantCode = 'YOUR_MERCHANT_CODE';
  static const String _partnerCode = 'YOUR_PARTNER_CODE';
  static const String _appScheme = 'quanlychitieu'; // URL scheme của app
  static const bool _isTestMode = true; // Chuyển sang false cho production

  /// Khởi tạo thanh toán MoMo
  /// 
  /// Parameters:
  /// - amount: Số tiền thanh toán (VND)
  /// - orderId: ID đơn hàng duy nhất
  /// - description: Mô tả giao dịch
  /// 
  /// Returns:
  /// - true nếu mở được app MoMo, false nếu có lỗi
  Future<bool> initiatePayment({
    required double amount,
    required String orderId,
    required String description,
  }) async {
    try {
      // Tạo payment URL hoặc deep link
      // Lưu ý: Trong thực tế, cần gọi API MoMo để lấy payment URL
      // Đây là ví dụ đơn giản, cần tích hợp với backend thực tế
      
      final paymentUrl = _buildPaymentUrl(
        amount: amount,
        orderId: orderId,
        description: description,
      );

      // Mở app MoMo hoặc web payment
      final uri = Uri.parse(paymentUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      } else {
        Fluttertoast.showToast(
          msg: 'Không thể mở ứng dụng MoMo. Vui lòng cài đặt ứng dụng MoMo.',
          toastLength: Toast.LENGTH_LONG,
        );
        return false;
      }
    } catch (e) {
      debugPrint('Lỗi khi khởi tạo thanh toán MoMo: $e');
      Fluttertoast.showToast(
        msg: 'Lỗi khi khởi tạo thanh toán: $e',
        toastLength: Toast.LENGTH_LONG,
      );
      return false;
    }
  }

  /// Xây dựng payment URL cho MoMo
  /// 
  /// Trong production, cần gọi API MoMo để lấy payment URL thực tế
  String _buildPaymentUrl({
    required double amount,
    required String orderId,
    required String description,
  }) {
    // URL scheme để mở app MoMo
    // Format: momo://payment?param1=value1&param2=value2
    // Hoặc sử dụng deep link từ MoMo API
    
    // Ví dụ URL (cần thay thế bằng API thực tế)
    final params = {
      'merchantname': _merchantName,
      'merchantcode': _merchantCode,
      'partnerCode': _partnerCode,
      'amount': amount.toInt().toString(),
      'orderId': orderId,
      'description': description,
      'appScheme': _appScheme,
    };

    // Trong thực tế, cần gọi MoMo API để lấy payment URL
    // Tạm thời trả về URL scheme
    return 'momo://payment?${Uri(queryParameters: params).query}';
  }

  /// Xử lý callback từ MoMo sau khi thanh toán
  /// 
  /// Parameters:
  /// - url: URL callback từ MoMo
  /// 
  /// Returns:
  /// - Map chứa thông tin kết quả thanh toán
  Map<String, dynamic>? handlePaymentCallback(Uri url) {
    try {
      if (url.scheme == _appScheme && url.host == 'payment') {
        final params = url.queryParameters;
        
        // Kiểm tra kết quả thanh toán
        final status = params['status'];
        final orderId = params['orderId'];
        final amount = params['amount'];
        final message = params['message'] ?? '';

        return {
          'success': status == 'success',
          'orderId': orderId,
          'amount': amount != null ? double.tryParse(amount) : null,
          'message': message,
          'phoneNumber': params['phonenumber'],
          'token': params['token'],
        };
      }
      return null;
    } catch (e) {
      debugPrint('Lỗi khi xử lý callback MoMo: $e');
      return null;
    }
  }

  /// Kiểm tra trạng thái thanh toán
  /// 
  /// Parameters:
  /// - orderId: ID đơn hàng cần kiểm tra
  /// 
  /// Returns:
  /// - Map chứa thông tin trạng thái thanh toán
  Future<Map<String, dynamic>?> checkPaymentStatus(String orderId) async {
    try {
      // Gọi API MoMo để kiểm tra trạng thái
      // Trong thực tế, cần tích hợp với backend API
      
      // Ví dụ API call (cần thay thế bằng endpoint thực tế)
      final response = await http.post(
        Uri.parse('https://test-payment.momo.vn/v2/gateway/api/query'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'partnerCode': _partnerCode,
          'orderId': orderId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['resultCode'] == 0,
          'orderId': data['orderId'],
          'amount': data['amount'],
          'message': data['message'],
        };
      }
      return null;
    } catch (e) {
      debugPrint('Lỗi khi kiểm tra trạng thái thanh toán: $e');
      return null;
    }
  }
}

