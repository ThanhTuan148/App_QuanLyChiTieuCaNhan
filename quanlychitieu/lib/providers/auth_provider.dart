/// Provider quản lý trạng thái xác thực của người dùng và thông tin hồ sơ.
/// Cung cấp các phương thức đăng ký, đăng nhập, đăng xuất, cập nhật hồ sơ và tích hợp với Firebase Auth/Firestore.
// [HOÀN CHỈNH] lib/providers/auth_provider.dart

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/firebase_service.dart';

/// `AuthProvider` quản lý trạng thái đăng nhập và thông tin người dùng hiện tại.
/// Nó lắng nghe các thay đổi trạng thái xác thực từ Firebase Auth và đồng bộ thông tin hồ sơ từ Firestore.
class AuthProvider with ChangeNotifier {
  /// Instance của `FirebaseService` để tương tác với Firebase Auth và Firestore.
  final FirebaseService _firebaseService = FirebaseService();

  /// Đối tượng người dùng Firebase hiện tại (từ `firebase_auth`).
  auth.User? _firebaseUser;

  /// Đối tượng người dùng ứng dụng tùy chỉnh (từ Firestore).
  AppUser? _appUser;

  /// Subscription để lắng nghe các thay đổi hồ sơ người dùng từ Firestore.
  StreamSubscription? _userProfileSubscription;

  /// Subscription để lắng nghe các thay đổi trạng thái xác thực từ Firebase Auth.
  StreamSubscription? _authStateSubscription;

  /// Getter trả về đối tượng người dùng Firebase hiện tại.
  auth.User? get firebaseUser => _firebaseUser;

  /// Getter trả về đối tượng người dùng ứng dụng tùy chỉnh hiện tại.
  AppUser? get currentUser => _appUser;

  /// Getter kiểm tra người dùng đã đăng nhập hay chưa.
  bool get isLoggedIn => _firebaseUser != null;

  /// Constructor của `AuthProvider`.
  /// Bắt đầu lắng nghe trạng thái xác thực Firebase khi khởi tạo.
  AuthProvider() {
    _authStateSubscription = auth.FirebaseAuth.instance
        .authStateChanges()
        .listen(_onAuthStateChanged);
  }

  /// Xử lý khi trạng thái xác thực của Firebase thay đổi.
  /// Cập nhật `_firebaseUser`, hủy subscription hồ sơ cũ (nếu có).
  /// Nếu người dùng đăng nhập, bắt đầu lắng nghe thông tin hồ sơ từ Firestore. Ngược lại, dọn dẹp dữ liệu hồ sơ.
  /// Cuối cùng, thông báo cho các listener để cập nhật UI.
  void _onAuthStateChanged(auth.User? user) {
    _firebaseUser = user;
    _userProfileSubscription
        ?.cancel(); // Hủy subscription cũ để tránh trùng lặp/memory leak.

    if (user != null) {
      // Nếu user đăng nhập, bắt đầu lắng nghe thông tin profile của họ từ Firestore.
      _userProfileSubscription = _firebaseService.getUserProfileStream().listen(
        (appUser) {
          _appUser = appUser;
          notifyListeners(); // Thông báo khi thông tin hồ sơ được cập nhật.
        },
      );
    } else {
      // Nếu user đăng xuất, dọn dẹp dữ liệu hồ sơ ứng dụng.
      _appUser = null;
    }
    notifyListeners(); // Thông báo cho UI cập nhật trạng thái đăng nhập.
  }

  // --- Các hàm hành động xác thực ---

  /// Đăng nhập người dùng bằng email và mật khẩu.
  /// @param email Email của người dùng.
  /// @param password Mật khẩu của người dùng.
  /// Không cần try-catch ở đây, để UI tự bắt và hiển thị lỗi.
  Future<void> login(String email, String password) async {
    await _firebaseService.signIn(email, password);
  }

  /// Đăng ký người dùng mới với email, mật khẩu và tên người dùng.
  /// @param email Email của người dùng.
  /// @param password Mật khẩu của người dùng.
  /// @param username Tên người dùng.
  Future<void> signup(String email, String password, String username) async {
    await _firebaseService.signUp(email, password, username);
  }

  /// Đăng xuất người dùng khỏi phiên hiện tại.
  Future<void> logout() async {
    await _firebaseService.signOut();
  }

  /// Cập nhật thông tin hồ sơ người dùng trong Firestore.
  /// @param updatedUser Đối tượng `AppUser` đã cập nhật.
  Future<void> updateUserProfile(AppUser updatedUser) async {
    // Chỉ cập nhật nếu user hiện tại tồn tại.
    if (currentUser != null) {
      await _firebaseService.updateUserProfile(updatedUser);
      // Stream sẽ tự động cập nhật `_appUser`, không cần notifyListeners() trực tiếp ở đây.
    }
  }

  /// Gửi email đặt lại mật khẩu đến địa chỉ email đã cung cấp.
  /// @param email Email nhận email đặt lại mật khẩu.
  Future<void> sendPasswordResetEmail(String email) async {
    await _firebaseService.sendPasswordResetEmail(email);
  }

  /// Đăng nhập người dùng bằng tài khoản Google.
  Future<void> signInWithGoogle() async {
    await _firebaseService.signInWithGoogle();
  }

  /// Giải phóng tài nguyên khi provider không còn được sử dụng.
  /// Hủy bỏ các subscription để tránh rò rỉ bộ nhớ.
  @override
  void dispose() {
    _userProfileSubscription?.cancel();
    _authStateSubscription?.cancel();
    super.dispose();
  }
}
