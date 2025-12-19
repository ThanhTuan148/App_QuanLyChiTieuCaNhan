/// Provider quản lý việc xuất dữ liệu chi tiêu ra các định dạng file (Excel).
/// Cung cấp chức năng lọc, sắp xếp và định dạng dữ liệu cho báo cáo.
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';

import '../models/expense.dart';
import '../models/category.dart';
import '../models/date_range.dart';
import 'expense_provider.dart';
import 'category_provider.dart';
import 'auth_provider.dart';

/// Enum định nghĩa các loại định dạng file có thể xuất.
enum ExportType { excel }

/// `ExportProvider` quản lý logic xuất dữ liệu chi tiêu.
/// Tích hợp với `ExpenseProvider`, `CategoryProvider` và `AuthProvider` để lấy dữ liệu cần thiết.
class ExportProvider with ChangeNotifier {
  /// Provider quản lý dữ liệu chi tiêu.
  final ExpenseProvider expenseProvider;

  /// Provider quản lý dữ liệu danh mục.
  final CategoryProvider categoryProvider;

  /// Provider quản lý thông tin xác thực người dùng (để có thể lấy userId).
  final AuthProvider authProvider;

  /// Định dạng ngày tháng cho hiển thị (ví dụ: dd/MM/yyyy).
  final DateFormat dateFormat = DateFormat('dd/MM/yyyy');

  /// Định dạng ngày tháng cho tên file (ví dụ: yyyy-MM-dd_HH-mm-ss).
  final DateFormat fileNameDateFormat = DateFormat('yyyy-MM-dd_HH-mm-ss');

  /// Định dạng tiền tệ theo chuẩn Việt Nam (ví dụ: 100.000 ₫).
  final NumberFormat currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
  );

  /// Constructor của `ExportProvider`.
  /// Yêu cầu các provider cần thiết để truy cập dữ liệu.
  ExportProvider({
    required this.expenseProvider,
    required this.categoryProvider,
    required this.authProvider,
  });

  /// Xuất dữ liệu chi tiêu thành file PDF hoặc Excel.
  /// @param exportType Loại file muốn xuất (PDF hoặc Excel).
  /// @param dateRange Khoảng thời gian muốn xuất dữ liệu.
  /// @param includeIncome Bao gồm thu nhập trong báo cáo (mặc định là true).
  /// @param includeExpense Bao gồm chi tiêu trong báo cáo (mặc định là true).
  /// @return Đường dẫn file đã xuất hoặc null nếu có lỗi.
  Future<String?> exportExpenses(
    ExportType exportType,
    DateRange dateRange, {
    bool includeIncome = true,
    bool includeExpense = true,
  }) async {
    try {
      // Lấy dữ liệu chi tiêu theo khoảng thời gian được chọn.
      final expenses = expenseProvider.getExpensesByDateRange(dateRange);

      // Lọc dữ liệu chi tiêu dựa trên lựa chọn bao gồm thu nhập/chi tiêu.
      final filteredExpenses =
          expenses
              .where(
                (expense) =>
                    (includeIncome && expense.isIncome) ||
                    (includeExpense && !expense.isIncome),
              )
              .toList();

      // Sắp xếp các khoản chi tiêu theo ngày giảm dần (mới nhất trước).
      filteredExpenses.sort((a, b) => b.date.compareTo(a.date));

      // Gọi hàm xuất tương ứng với loại file đã chọn.
      switch (exportType) {
        case ExportType.excel:
          return await _exportToExcel(filteredExpenses, dateRange);
      }
    } catch (e) {
      debugPrint('Lỗi khi xuất dữ liệu: $e');
      return null;
    }
  }

  /// Xuất dữ liệu chi tiêu ra file Excel.
  /// @param expenses Danh sách các khoản chi tiêu đã được lọc và sắp xếp.
  /// @param dateRange Khoảng thời gian của dữ liệu.
  /// @return Đường dẫn file Excel đã tạo hoặc null nếu có lỗi.
  Future<String?> _exportToExcel(
    List<Expense> expenses,
    DateRange dateRange,
  ) async {
    try {
      // Tạo một workbook Excel mới.
      final excel = Excel.createExcel();

      // Xóa sheet mặc định 'Sheet1'.
      excel.delete('Sheet1');

      // Tạo một sheet mới với tên 'Chi tiêu'.
      final sheet = excel['Chi tiêu'];

      // Thiết lập tiêu đề báo cáo và khoảng thời gian.
      sheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('F1'));
      sheet.cell(CellIndex.indexByString('A1')).value = 'BÁO CÁO CHI TIÊU';
      sheet.cell(CellIndex.indexByString('A1')).cellStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        fontSize: 16,
      );

      sheet.merge(CellIndex.indexByString('A2'), CellIndex.indexByString('F2'));
      sheet.cell(CellIndex.indexByString('A2')).value =
          'Khoảng thời gian: ${dateRange.displayText}';
      sheet.cell(CellIndex.indexByString('A2')).cellStyle = CellStyle(
        horizontalAlign: HorizontalAlign.Center,
        fontSize: 12,
      );

      // Tính toán và thêm thông tin tổng quan (Tổng thu, Tổng chi, Cân đối).
      final totalIncome = expenses
          .where((expense) => expense.isIncome)
          .fold(0.0, (sum, expense) => sum + expense.amount);

      final totalExpense = expenses
          .where((expense) => !expense.isIncome)
          .fold(0.0, (sum, expense) => sum + expense.amount);

      final balance = totalIncome - totalExpense;

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
      sheet.cell(CellIndex.indexByString('A6')).cellStyle = CellStyle(
        bold: true,
      );
      sheet.cell(CellIndex.indexByString('B6')).cellStyle = CellStyle(
        bold: true,
      );

      // Thêm hàng tiêu đề cho bảng chi tiết các khoản thu chi.
      final headers = ['STT', 'Ngày', 'Danh mục', 'Mô tả', 'Số tiền', 'Loại'];
      for (var i = 0; i < headers.length; i++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 8))
            .value = headers[i];
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 8))
            .cellStyle = CellStyle(
          bold: true,
          horizontalAlign: HorizontalAlign.Center,
        );
      }

      // Điền dữ liệu chi tiết vào bảng Excel.
      for (var i = 0; i < expenses.length; i++) {
        final expense = expenses[i];
        final category = categoryProvider.findById(expense.categoryId);

        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 9 + i))
            .value = (i + 1);
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 9 + i))
            .value = dateFormat.format(expense.date);
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 9 + i))
            .value = category.name;
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 9 + i))
            .value = expense.description;
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 9 + i))
            .value = expense.amount.toString();
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 9 + i))
            .value = (expense.isIncome ? 'Thu nhập' : 'Chi tiêu');

        // Áp dụng màu sắc cho cột 'Loại' (mặc dù hiện tại không có màu trực tiếp).
        if (expense.isIncome) {
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 9 + i))
              .cellStyle = CellStyle();
          // Tô màu xanh lá cho thu nhập (ghi chú: cần thư viện màu nếu muốn tô màu).
        } else {
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 9 + i))
              .cellStyle = CellStyle();
          // Tô màu đỏ cho chi tiêu (ghi chú: cần thư viện màu nếu muốn tô màu).
        }
      }

      // Lưu file Excel vào thư mục Downloads công khai trên thiết bị.
      final downloadsPath = Directory('/storage/emulated/0/Download');
      if (!await downloadsPath.exists()) {
        await downloadsPath.create(recursive: true);
      }

      // Tạo tên file với timestamp để tránh trùng lặp.
      final timestamp = fileNameDateFormat.format(DateTime.now());
      final fileName = 'QuanLyChiTieu_$timestamp.xlsx';
      final file = File('${downloadsPath.path}/$fileName');

      final fileBytes = excel.encode();
      if (fileBytes != null) {
        await file.writeAsBytes(fileBytes);
        return file.path;
      }

      return null;
    } catch (e) {
      debugPrint('Lỗi khi xuất Excel: $e');
      return null;
    }
  }
}
