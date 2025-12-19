/// Provider quản lý dữ liệu danh mục chi tiêu và thu nhập của người dùng.
/// Lắng nghe dữ liệu real-time từ Firebase và cung cấp các hàm CRUD.
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/category.dart';
import '../services/firebase_service.dart';
import 'auth_provider.dart';
import '../models/user.dart' as app_user;

/// `CategoryProvider` quản lý trạng thái và logic liên quan đến các danh mục.
/// Nó tích hợp với `FirebaseService` để đồng bộ dữ liệu và `AuthProvider` để theo dõi trạng thái người dùng.
class CategoryProvider with ChangeNotifier {
  /// Instance của `FirebaseService` để tương tác với Firebase Firestore.
  final FirebaseService _firebaseService = FirebaseService();

  /// Provider xác thực người dùng để lắng nghe trạng thái đăng nhập/đăng xuất.
  final AuthProvider authProvider;

  /// Danh sách các danh mục hiện có của người dùng.
  List<Category> _categories = [];

  /// Subscription để lắng nghe các thay đổi từ luồng dữ liệu danh mục Firebase.
  StreamSubscription<List<Category>>? _categorySubscription;

  /// Getter trả về danh sách các danh mục hiện tại.
  List<Category> get categories => _categories;

  /// Constructor của `CategoryProvider`.
  /// @param authProvider Provider xác thực người dùng.
  CategoryProvider(this.authProvider) {
    // Lắng nghe thay đổi từ AuthProvider để biết khi nào cần tải/dọn dẹp dữ liệu danh mục.
    authProvider.addListener(_onAuthChanged);
    // Gọi lần đầu để kiểm tra trạng thái đăng nhập hiện tại.
    _onAuthChanged();
  }

  /// Xử lý khi trạng thái xác thực của người dùng thay đổi.
  /// Nếu người dùng đăng nhập, bắt đầu lắng nghe luồng dữ liệu danh mục. Ngược lại, dọn dẹp dữ liệu.
  void _onAuthChanged() {
    if (authProvider.isLoggedIn && authProvider.currentUser != null) {
      _listenToCategories();
    } else {
      _categories = [];
      _categorySubscription?.cancel();
      notifyListeners();
    }
  }

  /// Lắng nghe luồng dữ liệu danh mục từ Firebase.
  /// Hủy stream cũ (nếu có) và tạo một stream mới.
  void _listenToCategories() {
    _categorySubscription?.cancel();
    _categorySubscription = _firebaseService.getCategoriesStream().listen((
      newCategories,
    ) {
      _categories = newCategories;
      notifyListeners(); // Thông báo cho UI cập nhật mỗi khi có dữ liệu mới.
    });
  }

  /// Thêm một danh mục mới vào Firebase.
  /// @param category Đối tượng danh mục cần thêm.
  /// @return Đối tượng danh mục đã được lưu (bao gồm ID).
  Future<Category> addCategory(Category category) async {
    return await _firebaseService.saveCategory(category);
  }

  /// Cập nhật một danh mục hiện có trong Firebase.
  /// @param category Đối tượng danh mục đã cập nhật.
  Future<void> updateCategory(Category category) async {
    await _firebaseService.saveCategory(category);
  }

  /// Xóa một danh mục khỏi Firebase.
  /// @param categoryId ID của danh mục cần xóa.
  Future<void> deleteCategory(String categoryId) async =>
      await _firebaseService.deleteCategory(categoryId);

  /// Tìm kiếm một danh mục theo ID.
  /// @param id ID của danh mục cần tìm.
  /// @return Đối tượng `Category` nếu tìm thấy, ngược lại trả về một danh mục 'Không xác định'.
  Category findById(String id) {
    try {
      return _categories.firstWhere((cat) => cat.id == id);
    } catch (e) {
      // Trả về một danh mục mặc định nếu không tìm thấy, hữu ích cho các trường hợp dữ liệu không khớp.
      return Category(
        id: 'not_found',
        name: 'Không xác định',
        icon: Icons.help,
        color: Colors.grey,
        userId: authProvider.currentUser?.id ?? '',
      );
    }
  }

  /// Giải phóng tài nguyên khi provider không còn được sử dụng.
  /// Hủy bỏ lắng nghe `AuthProvider` và subscription dữ liệu danh mục.
  @override
  void dispose() {
    authProvider.removeListener(_onAuthChanged);
    _categorySubscription?.cancel();
    super.dispose();
  }
}
