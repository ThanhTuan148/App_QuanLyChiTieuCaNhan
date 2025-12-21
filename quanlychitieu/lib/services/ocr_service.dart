/// Service OCR để trích xuất thông tin từ hóa đơn
/// Sử dụng Google ML Kit để quét và đọc hóa đơn tự động
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:io';

/// Kết quả OCR từ hóa đơn
class ReceiptData {
  final double? amount;
  final DateTime? date;
  final String? merchant;
  final String? description;
  final Map<String, dynamic> rawData;

  ReceiptData({
    this.amount,
    this.date,
    this.merchant,
    this.description,
    required this.rawData,
  });
}

/// Service xử lý OCR hóa đơn
class OCRService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  /// Quét và trích xuất thông tin từ ảnh hóa đơn
  /// 
  /// Parameters:
  /// - imagePath: Đường dẫn đến file ảnh
  /// 
  /// Returns:
  /// - ReceiptData chứa thông tin đã trích xuất
  Future<ReceiptData> scanReceipt(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      // Phân tích text để tìm amount, date, merchant
      final text = recognizedText.text;
      final amount = _extractAmount(text);
      final date = _extractDate(text);
      final merchant = _extractMerchant(text);
      final description = _extractDescription(text);

      return ReceiptData(
        amount: amount,
        date: date,
        merchant: merchant,
        description: description,
        rawData: {
          'fullText': text,
          'blocks': recognizedText.blocks.map((b) => {
            'text': b.text,
            'boundingBox': b.boundingBox.toString(),
          }).toList(),
        },
      );
    } catch (e) {
      debugPrint('Lỗi khi quét hóa đơn: $e');
      rethrow;
    }
  }

  /// Trích xuất số tiền từ text
  double? _extractAmount(String text) {
    // Tìm pattern số tiền (ví dụ: "100,000 VND", "100.000đ", "100000")
    final patterns = [
      RegExp(r'(\d{1,3}(?:[.,]\d{3})*(?:\s*(?:VND|đ|VNĐ)))', caseSensitive: false),
      RegExp(r'(?:Tổng|Tong|Total|Thành tiền)[:\s]*(\d{1,3}(?:[.,]\d{3})*)', caseSensitive: false),
      RegExp(r'(\d{1,3}(?:[.,]\d{3})*)\s*(?:VND|đ)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final amountStr = match.group(1)?.replaceAll(RegExp(r'[.,\s]'), '') ?? '';
        final amount = double.tryParse(amountStr);
        if (amount != null && amount > 0) {
          return amount;
        }
      }
    }
    return null;
  }

  /// Trích xuất ngày từ text
  DateTime? _extractDate(String text) {
    // Tìm pattern ngày (ví dụ: "01/12/2025", "01-12-2025", "01 Dec 2025")
    final patterns = [
      RegExp(r'(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{4})'),
      RegExp(r'(\d{1,2})\s+(?:Tháng|Thang|Month)\s+(\d{1,2}),?\s+(\d{4})', caseSensitive: false),
      RegExp(r'(?:Ngày|Ngay|Date)[:\s]*(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{4})', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final day = int.tryParse(match.group(1) ?? '');
        final month = int.tryParse(match.group(2) ?? '');
        final year = int.tryParse(match.group(3) ?? '');
        
        if (day != null && month != null && year != null) {
          try {
            return DateTime(year, month, day);
          } catch (e) {
            continue;
          }
        }
      }
    }
    
    // Nếu không tìm thấy, trả về ngày hiện tại
    return DateTime.now();
  }

  /// Trích xuất tên cửa hàng/merchant
  String? _extractMerchant(String text) {
    // Tìm dòng đầu tiên hoặc dòng có từ khóa như "Cửa hàng", "Store", "Merchant"
    final lines = text.split('\n');
    
    // Tìm dòng có từ khóa merchant
    for (final line in lines.take(5)) {
      if (line.contains(RegExp(r'(?:Cửa hàng|Store|Merchant|Nhà hàng|Restaurant)', caseSensitive: false))) {
        return line.replaceAll(RegExp(r'(?:Cửa hàng|Store|Merchant|Nhà hàng|Restaurant)[:\s]*', caseSensitive: false), '').trim();
      }
    }
    
    // Nếu không tìm thấy, lấy dòng đầu tiên (thường là tên cửa hàng)
    if (lines.isNotEmpty && lines[0].trim().isNotEmpty) {
      return lines[0].trim();
    }
    
    return null;
  }

  /// Trích xuất mô tả từ text
  String? _extractDescription(String text) {
    // Lấy một số dòng giữa (thường chứa thông tin sản phẩm)
    final lines = text.split('\n');
    if (lines.length > 2) {
      return lines.sublist(1, lines.length - 1).join(' ').trim();
    }
    return null;
  }

  /// Giải phóng tài nguyên
  void dispose() {
    _textRecognizer.close();
  }
}

