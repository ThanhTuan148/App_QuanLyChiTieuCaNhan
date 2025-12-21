/// Service tích hợp ZaloPay Payment
/// Xử lý thanh toán qua ví điện tử ZaloPay
/// 
/// Lưu ý: Cần đăng ký tại Zalo Developer Portal
/// để lấy appId và cấu hình

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:crypto/crypto.dart';
import 'dart:typed_data';

/// Service quản lý tích hợp ZaloPay Payment
class ZaloPayService {
  // Cấu hình ZaloPay (cần thay đổi khi deploy production)
  static const String _appId = '2553'; // App ID test (thay bằng app ID thực tế)
  static const String _appScheme = 'quanlychitieu://app';
  static const String _environment = 'SANDBOX'; // hoặc 'PRODUCTION'
  static const String _merchantId = 'YOUR_MERCHANT_ID';
  static const String _key1 = 'YOUR_KEY1';
  static const String _key2 = 'YOUR_KEY2';

  /// Khởi tạo thanh toán ZaloPay
  /// 
  /// Parameters:
  /// - amount: Số tiền thanh toán (VND)
  /// - orderId: ID đơn hàng duy nhất
  /// - description: Mô tả giao dịch
  /// 
  /// Returns:
  /// - zpToken để mở app ZaloPay, null nếu có lỗi
  Future<String?> initiatePayment({
    required double amount,
    required String orderId,
    required String description,
  }) async {
    try {
      // Gọi API ZaloPay để lấy zpToken
      final zpToken = await _createOrder(
        amount: amount,
        orderId: orderId,
        description: description,
      );

      if (zpToken != null) {
        // Mở app ZaloPay với zpToken
        final paymentUrl = 'zalopay://app?token=$zpToken';
        final uri = Uri.parse(paymentUrl);
        
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return zpToken;
        } else {
          // Fallback: mở web payment
          final webUrl = 'https://zalopay.vn/pay?token=$zpToken';
          final webUri = Uri.parse(webUrl);
          if (await canLaunchUrl(webUri)) {
            await launchUrl(webUri, mode: LaunchMode.externalApplication);
            return zpToken;
          }
        }
      }

      Fluttertoast.showToast(
        msg: 'Không thể mở ứng dụng ZaloPay. Vui lòng cài đặt ứng dụng ZaloPay.',
        toastLength: Toast.LENGTH_LONG,
      );
      return null;
    } catch (e) {
      debugPrint('Lỗi khi khởi tạo thanh toán ZaloPay: $e');
      Fluttertoast.showToast(
        msg: 'Lỗi khi khởi tạo thanh toán: $e',
        toastLength: Toast.LENGTH_LONG,
      );
      return null;
    }
  }

  /// Tạo đơn hàng và lấy zpToken từ ZaloPay API
  /// 
  /// Parameters:
  /// - amount: Số tiền
  /// - orderId: ID đơn hàng
  /// - description: Mô tả
  /// 
  /// Returns:
  /// - zpToken nếu thành công, null nếu có lỗi
  Future<String?> _createOrder({
    required double amount,
    required String orderId,
    required String description,
  }) async {
    try {
      // Tạo request data
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final embedData = jsonEncode({});
      final item = jsonEncode([{
        'itemid': 'item1',
        'itemname': description,
        'itemprice': amount.toInt(),
        'itemquantity': 1,
      }]);

      // Tạo mac (message authentication code)
      final macData = '${_appId}|$orderId|${amount.toInt()}|$timestamp|$embedData|$item';
      final mac = _hmacSHA256(macData, _key1);

      // Gọi API ZaloPay
      final response = await http.post(
        Uri.parse('https://sandbox.zalopay.vn/v001/tpe/createorder'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'appid': _appId,
          'appuser': 'user123', // User ID của app
          'apptime': timestamp.toString(),
          'amount': amount.toInt().toString(),
          'apptransid': orderId,
          'description': description,
          'bankcode': 'zalopayapp', // hoặc 'zalopayapp' để mở app
          'item': item,
          'embeddata': embedData,
          'mac': mac,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['returncode'] == 1) {
          return data['zp_trans_token'];
        } else {
          debugPrint('Lỗi từ ZaloPay API: ${data['returnmessage']}');
          return null;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Lỗi khi tạo đơn hàng ZaloPay: $e');
      return null;
    }
  }

  /// Tính toán HMAC SHA256
  String _hmacSHA256(String data, String key) {
    final hmac = Hmac(sha256, utf8.encode(key));
    final digest = hmac.convert(utf8.encode(data));
    return digest.toString();
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
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final macData = '${_appId}|$orderId|$timestamp';
      final mac = _hmacSHA256(macData, _key1);

      final response = await http.post(
        Uri.parse('https://sandbox.zalopay.vn/v001/tpe/queryorder'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'appid': _appId,
          'apptransid': orderId,
          'mac': mac,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['returncode'] == 1,
          'orderId': data['apptransid'],
          'amount': data['amount'],
          'message': data['returnmessage'],
        };
      }
      return null;
    } catch (e) {
      debugPrint('Lỗi khi kiểm tra trạng thái thanh toán: $e');
      return null;
    }
  }

  /// Xử lý callback từ ZaloPay sau khi thanh toán
  /// 
  /// Parameters:
  /// - url: URL callback từ ZaloPay
  /// 
  /// Returns:
  /// - Map chứa thông tin kết quả thanh toán
  Map<String, dynamic>? handlePaymentCallback(Uri url) {
    try {
      if (url.scheme == 'quanlychitieu' && url.host == 'app') {
        final params = url.queryParameters;
        
        final status = params['status'];
        final orderId = params['orderId'];
        final amount = params['amount'];

        return {
          'success': status == 'SUCCESS',
          'orderId': orderId,
          'amount': amount != null ? double.tryParse(amount) : null,
          'message': params['message'] ?? '',
        };
      }
      return null;
    } catch (e) {
      debugPrint('Lỗi khi xử lý callback ZaloPay: $e');
      return null;
    }
  }
}

