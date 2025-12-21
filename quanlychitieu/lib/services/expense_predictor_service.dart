/// Service dự đoán chi tiêu sử dụng TensorFlow Lite
/// Phân tích lịch sử chi tiêu để dự đoán chi tiêu tương lai
/// 
/// Lưu ý: 
/// - Cần train model LSTM trước và đặt file .tflite trong assets
/// - Chỉ hoạt động trên mobile (Android/iOS), không hoạt động trên web

import 'package:flutter/material.dart';
import 'dart:typed_data';

// Conditional import - chỉ import tflite trên mobile
import 'package:flutter/foundation.dart' show kIsWeb;

// Tạm thời comment out tflite import vì không tương thích web
// import 'package:tflite_flutter/tflite_flutter.dart';

/// Service dự đoán chi tiêu dựa trên lịch sử
class ExpensePredictorService {
  // Tạm thời comment out vì không tương thích web
  // Interpreter? _interpreter;
  bool _isModelLoaded = false;

  /// Load model TensorFlow Lite từ assets
  /// 
  /// Parameters:
  /// - modelPath: Đường dẫn đến file .tflite trong assets
  /// 
  /// Returns:
  /// - true nếu load thành công, false nếu có lỗi
  /// 
  /// Lưu ý: Chỉ hoạt động trên mobile, không hoạt động trên web
  Future<bool> loadModel({String modelPath = 'assets/expense_model.tflite'}) async {
    if (kIsWeb) {
      debugPrint('TensorFlow Lite không hỗ trợ web. Sử dụng fallback prediction.');
      _isModelLoaded = false;
      return false;
    }
    
    // Tạm thời comment out vì không tương thích web
    // try {
    //   _interpreter = await Interpreter.fromAsset(modelPath);
    //   _isModelLoaded = true;
    //   debugPrint('Model TensorFlow Lite đã được load thành công');
    //   return true;
    // } catch (e) {
    //   debugPrint('Lỗi khi load model: $e');
    //   debugPrint('Lưu ý: Cần train model và đặt file .tflite trong assets');
    //   _isModelLoaded = false;
    //   return false;
    // }
    
    _isModelLoaded = false;
    return false;
  }

  /// Dự đoán chi tiêu tiếp theo dựa trên lịch sử
  /// 
  /// Parameters:
  /// - pastExpenses: Danh sách chi tiêu trong quá khứ (theo thứ tự thời gian)
  /// - sequenceLength: Độ dài sequence để dự đoán (mặc định 30 ngày)
  /// 
  /// Returns:
  /// - Số tiền dự đoán cho ngày tiếp theo, null nếu có lỗi
  /// 
  /// Lưu ý: Sử dụng fallback prediction nếu model chưa load hoặc trên web
  Future<double?> predictNextExpense({
    required List<double> pastExpenses,
    int sequenceLength = 30,
  }) async {
    if (!_isModelLoaded || kIsWeb) {
      // Fallback: Sử dụng trung bình có trọng số
      return _fallbackPrediction(pastExpenses);
    }

    // Tạm thời comment out vì không tương thích web
    // try {
    //   // Chuẩn hóa dữ liệu đầu vào
    //   final normalizedInput = _normalizeData(pastExpenses);
    //   ...
    //   _interpreter!.run(inputBuffer, outputBuffer);
    //   ...
    // } catch (e) {
    //   debugPrint('Lỗi khi dự đoán: $e');
    //   return _fallbackPrediction(pastExpenses);
    // }
    
    return _fallbackPrediction(pastExpenses);
  }

  /// Fallback prediction sử dụng trung bình có trọng số
  double? _fallbackPrediction(List<double> pastExpenses) {
    if (pastExpenses.isEmpty) return 0.0;
    if (pastExpenses.length == 1) return pastExpenses[0];
    
    // Trung bình có trọng số (giá trị gần nhất quan trọng hơn)
    final weights = List.generate(pastExpenses.length, (i) => (i + 1).toDouble());
    final totalWeight = weights.fold(0.0, (a, b) => a + b);
    
    var weightedSum = 0.0;
    for (int i = 0; i < pastExpenses.length; i++) {
      weightedSum += pastExpenses[i] * weights[i];
    }
    
    return weightedSum / totalWeight;
  }

  /// Dự đoán chi tiêu cho nhiều ngày tiếp theo
  /// 
  /// Parameters:
  /// - pastExpenses: Danh sách chi tiêu trong quá khứ
  /// - days: Số ngày cần dự đoán
  /// 
  /// Returns:
  /// - Danh sách chi tiêu dự đoán cho các ngày tiếp theo
  Future<List<double>> predictMultipleDays({
    required List<double> pastExpenses,
    int days = 7,
  }) async {
    final predictions = <double>[];
    var currentHistory = List<double>.from(pastExpenses);

    for (int i = 0; i < days; i++) {
      final prediction = await predictNextExpense(pastExpenses: currentHistory);
      if (prediction != null) {
        predictions.add(prediction);
        currentHistory.add(prediction);
        // Giữ chỉ 30 ngày gần nhất
        if (currentHistory.length > 30) {
          currentHistory = currentHistory.sublist(currentHistory.length - 30);
        }
      } else {
        // Nếu không dự đoán được, sử dụng giá trị trung bình
        final avg = currentHistory.isNotEmpty
            ? currentHistory.reduce((a, b) => a + b) / currentHistory.length
            : 0.0;
        predictions.add(avg);
        currentHistory.add(avg);
      }
    }

    return predictions;
  }

  /// Chuẩn hóa dữ liệu về khoảng [0, 1]
  List<double> _normalizeData(List<double> data) {
    if (data.isEmpty) return [];
    
    final min = data.reduce((a, b) => a < b ? a : b);
    final max = data.reduce((a, b) => a > b ? a : b);
    final range = max - min;

    if (range == 0) return data.map((e) => 0.5).toList();

    return data.map((e) => (e - min) / range).toList();
  }

  /// Denormalize dữ liệu về giá trị thực
  List<double> _denormalizeData(List<double> normalized, List<double> original) {
    if (original.isEmpty || normalized.isEmpty) return normalized;
    
    final min = original.reduce((a, b) => a < b ? a : b);
    final max = original.reduce((a, b) => a > b ? a : b);
    final range = max - min;

    return normalized.map((e) => e * range + min).toList();
  }

  /// Giải phóng tài nguyên
  void dispose() {
    // _interpreter?.close();
    // _interpreter = null;
    _isModelLoaded = false;
  }
}

