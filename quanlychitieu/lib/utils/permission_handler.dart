// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';

class PermissionUtils {
  /// Kiểm tra và yêu cầu quyền truy cập vào bộ sưu tập
  static Future<bool> requestGalleryPermission(BuildContext context) async {
    Permission permissionToRequest;

    if (Platform.isAndroid) {
      if (await _isAndroid13OrHigher()) {
        permissionToRequest = Permission.photos;
      } else {
        permissionToRequest = Permission.storage;
      }
    } else if (Platform.isIOS) {
      // iOS luôn sử dụng Permission.photos
      permissionToRequest = Permission.photos;
    } else {
      // Các nền tảng khác
      return true;
    }

    // Kiểm tra trạng thái quyền
    var status = await permissionToRequest.status;

    if (status.isDenied) {
      // Yêu cầu quyền nếu bị từ chối
      status = await permissionToRequest.request();
    }

    // Nếu quyền bị từ chối vĩnh viễn, hiển thị hộp thoại
    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        _showPermissionDeniedDialog(context);
      }
      return false;
    }

    return status.isGranted;
  }

  /// Hiển thị hộp thoại khi quyền bị từ chối vĩnh viễn
  static void _showPermissionDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (BuildContext context) => AlertDialog(
            title: const Text('Cần quyền truy cập'),
            content: const Text(
              'Ứng dụng cần quyền truy cập vào Bộ sưu tập để cho phép bạn chọn ảnh. '
              'Vui lòng cấp quyền trong Cài đặt.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Huỷ'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  openAppSettings();
                },
                child: const Text('Mở Cài đặt'),
              ),
            ],
          ),
    );
  }

  /// Kiểm tra và yêu cầu quyền truy cập vào camera
  static Future<bool> requestCameraPermission(BuildContext context) async {
    // Kiểm tra trạng thái quyền
    var status = await Permission.camera.status;

    if (status.isDenied) {
      // Yêu cầu quyền nếu bị từ chối
      status = await Permission.camera.request();
    }

    // Nếu quyền bị từ chối vĩnh viễn, hiển thị hộp thoại
    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        _showCameraPermissionDeniedDialog(context);
      }
      return false;
    }

    return status.isGranted;
  }

  /// Hiển thị hộp thoại khi quyền camera bị từ chối vĩnh viễn
  static void _showCameraPermissionDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (BuildContext context) => AlertDialog(
            title: const Text('Cần quyền truy cập Camera'),
            content: const Text(
              'Ứng dụng cần quyền truy cập vào Camera để cho phép bạn chụp ảnh. '
              'Vui lòng cấp quyền trong Cài đặt.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Huỷ'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  openAppSettings();
                },
                child: const Text('Mở Cài đặt'),
              ),
            ],
          ),
    );
  }

  /// Kiểm tra xem thiết bị có chạy Android 13+ hay không
  static Future<bool> _isAndroid13OrHigher() async {
    if (Platform.isAndroid) {
      // Android 13 là API level 33
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.version.sdkInt >= 33;
    }
    return false;
  }

  /// Yêu cầu cả quyền camera và bộ sưu tập
  static Future<Map<String, bool>> requestImagePickerPermissions(
    BuildContext context,
  ) async {
    final hasGalleryPermission = await requestGalleryPermission(context);
    final hasCameraPermission = await requestCameraPermission(context);

    return {'gallery': hasGalleryPermission, 'camera': hasCameraPermission};
  }
}
