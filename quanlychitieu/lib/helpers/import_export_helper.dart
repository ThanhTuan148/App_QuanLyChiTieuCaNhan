/// Lớp tiện ích giúp nhập/xuất dữ liệu chi tiêu.
/// Hiện tại hỗ trợ xuất dữ liệu sang định dạng Excel và chia sẻ file đã xuất.
// lib/helpers/import_export_helper.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../models/expense.dart';
import '../models/category.dart' as app_category;
import '../models/date_range.dart';

/// `ImportExportHelper` là một lớp tĩnh (static class) cung cấp các phương thức để xử lý việc nhập và xuất dữ liệu tài chính.
/// Các phương thức trong lớp này được thiết kế để dễ dàng sử dụng trực tiếp mà không cần khởi tạo đối tượng.
class ImportExportHelper {
  // --- EXPORT TO EXCEL ---
  /// Xuất danh sách các khoản chi tiêu ra file Excel và chia sẻ file đó.
  /// @param context BuildContext hiện tại để hiển thị dialog lỗi và chia sẻ file.
  /// @param expenses Danh sách các khoản chi tiêu cần xuất.
  /// @param categories Danh sách các danh mục để ánh xạ `categoryId` sang `name`.
  /// @param dateRange Khoảng thời gian của dữ liệu đang được xuất (dùng cho tiêu đề báo cáo).
  /// @param fileName Tên file Excel sẽ được tạo (không bao gồm phần mở rộng).
  static Future<void> exportToExcel(
    BuildContext context,
    List<Expense> expenses,
    List<app_category.Category> categories,
    DateRange dateRange,
    String fileName,
  ) async {
    // Hàm hiển thị dialog lỗi nếu có vấn đề trong quá trình xuất file.
    void showErrorDialog(String errorMsg) {
      if (!context.mounted) return; // Đảm bảo context vẫn còn tồn tại
      showDialog(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('Lỗi'),
              content: Text('Không thể xuất file Excel: $errorMsg'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Đóng'),
                ),
              ],
            ),
      );
    }

    try {
      final dateFormat = DateFormat('dd/MM/yyyy');
      // Tạo một workbook Excel mới.
      final excel = Excel.createExcel();
      const String sheetName = 'Chi tiêu';
      excel.delete('Sheet1'); // Xóa sheet mặc định 'Sheet1'
      final Sheet sheet = excel[sheetName]; // Lấy sheet 'Chi tiêu'

      // Thêm tiêu đề báo cáo chính.
      sheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('F1'));
      sheet.cell(CellIndex.indexByString('A1')).value = 'BÁO CÁO CHI TIÊU';
      sheet.cell(CellIndex.indexByString('A1')).cellStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        fontSize: 16,
      );

      // Thêm tiêu đề khoảng thời gian.
      sheet.merge(CellIndex.indexByString('A2'), CellIndex.indexByString('F2'));
      sheet.cell(CellIndex.indexByString('A2')).value =
          'Tháng ${DateFormat('MM/yyyy').format(expenses.first.date)}'; // Lấy tháng/năm từ khoản chi tiêu đầu tiên
      sheet.cell(CellIndex.indexByString('A2')).cellStyle = CellStyle(
        horizontalAlign: HorizontalAlign.Center,
        fontSize: 12,
      );

      // Tính toán tổng thu, tổng chi và cân đối.
      final totalIncome = expenses
          .where((expense) => expense.isIncome)
          .fold(0.0, (sum, expense) => sum + expense.amount);

      final totalExpense = expenses
          .where((expense) => !expense.isIncome)
          .fold(0.0, (sum, expense) => sum + expense.amount);

      final balance = totalIncome - totalExpense;

      // Định dạng tiền tệ kiểu Việt Nam.
      final NumberFormat currencyFormat = NumberFormat.currency(
        locale: 'vi_VN',
        symbol: '₫',
      );

      // Thêm thông tin tổng quan vào sheet Excel.
      sheet.cell(CellIndex.indexByString('A4')).value = 'Tổng thu:';
      sheet.cell(CellIndex.indexByString('B4')).value = currencyFormat.format(
        totalIncome,
      );

      sheet.cell(CellIndex.indexByString('A5')).value = 'Tổng chi:';
      sheet.cell(CellIndex.indexByString('B5')).value = currencyFormat.format(
        totalExpense,
      );

      sheet.cell(CellIndex.indexByString('A6')).value = 'Cân đối:';
      sheet.cell(CellIndex.indexByString('B6')).value = currencyFormat.format(
        balance,
      );
      // Áp dụng style in đậm cho dòng cân đối.
      sheet.cell(CellIndex.indexByString('A6')).cellStyle = CellStyle(
        bold: true,
      );
      sheet.cell(CellIndex.indexByString('B6')).cellStyle = CellStyle(
        bold: true,
      );

      // Định nghĩa style cho hàng tiêu đề của bảng chi tiết.
      final headerStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        backgroundColorHex: 'FF4472C4', // Màu xanh dương đậm
        fontColorHex: 'FFFFFFFF', // Chữ trắng
        fontSize: 12,
      );

      // Tạo header cho bảng chi tiết các khoản thu chi.
      final headers = ['STT', 'Ngày', 'Danh mục', 'Mô tả', 'Số tiền', 'Loại'];
      for (var i = 0; i < headers.length; i++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(
            columnIndex: i,
            rowIndex: 8,
          ), // Hàng 9 (index 8)
        );
        cell.value = headers[i];
        cell.cellStyle = headerStyle;
      }

      // Định nghĩa style cho các ô dữ liệu.
      final dataStyle = CellStyle(
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        fontSize: 11,
      );

      // Định nghĩa style riêng cho cột số tiền (căn phải).
      final amountStyle = CellStyle(
        horizontalAlign: HorizontalAlign.Right,
        verticalAlign: VerticalAlign.Center,
        fontSize: 11,
      );

      // Thêm dữ liệu chi tiết vào bảng Excel.
      for (var i = 0; i < expenses.length; i++) {
        final expense = expenses[i];
        // Tìm danh mục tương ứng với `categoryId` của chi tiêu.
        final category = categories.firstWhere(
          (cat) => cat.id == expense.categoryId,
          orElse:
              () => app_category.Category(
                id: 'not_found',
                name: 'Không xác định',
                icon: Icons.help_outline,
                color: Colors.grey,
                userId: '',
              ), // Trả về danh mục mặc định nếu không tìm thấy
        );

        // Điền dữ liệu vào từng ô và áp dụng style.
        // Cột STT
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 9 + i))
          ..value = i + 1
          ..cellStyle = dataStyle;

        // Cột Ngày
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 9 + i))
          ..value = dateFormat.format(expense.date)
          ..cellStyle = dataStyle;

        // Cột Danh mục
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 9 + i))
          ..value = category.name
          ..cellStyle = dataStyle;

        // Cột Mô tả
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 9 + i))
          ..value = expense.description
          ..cellStyle = dataStyle;

        // Cột Số tiền
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 9 + i))
          ..value =
              expense.amount
                  .toString() // Lưu dưới dạng chuỗi
          ..cellStyle = amountStyle;

        // Cột Loại (Thu nhập/Chi tiêu)
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 9 + i))
          ..value = expense.isIncome ? 'Thu nhập' : 'Chi tiêu'
          ..cellStyle = dataStyle;
      }

      // Lấy thư mục ứng dụng để lưu file tạm thời.
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName.xlsx';
      final file = File(filePath);

      // Mã hóa workbook Excel thành bytes.
      final fileBytes = excel.encode();
      if (fileBytes != null) {
        // Ghi bytes vào file.
        await file.writeAsBytes(fileBytes);
        // Chia sẻ file đã tạo thông qua hộp thoại chia sẻ của hệ thống.
        await Share.shareXFiles([
          XFile(filePath),
        ], text: 'Dữ liệu chi tiêu của bạn');
      } else {
        showErrorDialog('Không thể tạo dữ liệu file.');
      }
    } catch (e) {
      debugPrint('Lỗi khi xuất file Excel: $e');
      showErrorDialog(e.toString()); // Hiển thị lỗi ra dialog
    }
  }
}
