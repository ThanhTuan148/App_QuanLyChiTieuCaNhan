// [Khong dùng tới - bỏ] lib/utils/excel_export_helper.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../models/expense.dart';
import '../models/category.dart';

class ExcelExportHelper {
  /// Xuất danh sách chi tiêu ra file Excel và chia sẻ
  static Future<void> exportExpensesToExcel(
    BuildContext context,
    List<Expense> expenses,
    List<Category> categories,
    String fileName,
  ) async {
    void errorCallback(String errorMsg) {
      if (!context.mounted) return;
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
      final excel = Excel.createExcel();
      excel.delete('Sheet1');
      final sheet = excel['Chi tiêu'];

      final headers = ['STT', 'Ngày', 'Danh mục', 'Mô tả', 'Số tiền', 'Loại'];
      for (var i = 0; i < headers.length; i++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
        );
        cell.value = headers[i];
        cell.cellStyle = CellStyle(
          bold: true,
          horizontalAlign: HorizontalAlign.Center,
          backgroundColorHex: 'FFD3D3D3',
        );
      }

      for (var i = 0; i < expenses.length; i++) {
        final expense = expenses[i];
        final category = categories.firstWhere(
          (cat) => cat.id == expense.categoryId,
          orElse:
              () => Category(
                id: 'not_found',
                name: 'Không xác định',
                icon: Icons.help_outline,
                color: Colors.grey,
                userId: '',
              ),
        );

        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i + 1))
            .value = i + 1;
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i + 1))
            .value = dateFormat.format(expense.date);
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: i + 1))
            .value = category.name;
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: i + 1))
            .value = expense.description;
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: i + 1))
            .value = expense.amount;
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: i + 1))
            .value = expense.isIncome ? 'Thu nhập' : 'Chi tiêu';
      }

      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName.xlsx';
      final file = File(filePath);

      final fileBytes = excel.encode();
      if (fileBytes != null) {
        await file.writeAsBytes(fileBytes);
        await Share.shareXFiles([
          XFile(filePath),
        ], text: 'Dữ liệu chi tiêu của bạn');
      }
    } catch (e) {
      errorCallback(e.toString());
    }
  }
}
