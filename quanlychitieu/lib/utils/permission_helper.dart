/// Utility class để quản lý các quyền truy cập của ứng dụng
/// Sử dụng package permission_handler để xử lý các quyền hệ thống
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class PermissionHelper {
  /// Yêu cầu quyền truy cập bộ nhớ từ người dùng
  ///
  /// Quy trình:
  /// 1. Kiểm tra trạng thái quyền storage hiện tại
  /// 2. Nếu chưa được cấp phép, yêu cầu quyền storage
  /// 3. Đối với Android 10 (API level 29) trở lên:
  ///    - Yêu cầu thêm quyền manageExternalStorage để quản lý tất cả file
  ///
  /// Returns:
  /// - true: Nếu tất cả quyền cần thiết được cấp phép
  /// - false: Nếu bất kỳ quyền nào bị từ chối
  static Future<bool> requestStoragePermission() async {
    // Kiểm tra và yêu cầu quyền truy cập bộ nhớ cơ bản
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }

    // Xử lý đặc biệt cho Android 10 trở lên
    // Cần thêm quyền manageExternalStorage để quản lý tất cả file
    if (status.isGranted) {
      if (Platform.isAndroid) {
        var manageStatus = await Permission.manageExternalStorage.status;
        if (!manageStatus.isGranted) {
          manageStatus = await Permission.manageExternalStorage.request();
        }
        return manageStatus.isGranted;
      }
    }

    return status.isGranted;
  }
}
