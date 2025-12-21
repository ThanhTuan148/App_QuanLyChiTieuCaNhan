/// Service quản lý tất cả các tương tác với Firebase
/// Bao gồm: Authentication, Firestore Database
/// Xử lý các thao tác CRUD cho: User, Expense, Category, Budget, Reminder
// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/expense.dart';
import '../models/category.dart' as app_category;
import '../models/budget.dart' as app_budget;
import '../models/reminder.dart' as app_reminder;
import '../models/user.dart' as app_user;

class FirebaseService {
  /// Instance của Firebase Auth
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  /// Instance của Firestore Database
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // GoogleSignIn singleton (set clientId for web)
  final GoogleSignIn _googleSignIn = kIsWeb
      ? GoogleSignIn(clientId: 'YOUR_CLIENT_ID.apps.googleusercontent.com')
      : GoogleSignIn();

  /// Lấy ID của người dùng hiện tại
  String? get currentUserId => _auth.currentUser?.uid; 

  // --- AUTHENTICATION & USER PROFILE ---

  /// Đăng ký tài khoản mới với email và mật khẩu
  ///
  /// Parameters:
  /// - email: Email đăng ký
  /// - password: Mật khẩu
  /// - username: Tên người dùng
  ///
  /// Returns:
  /// - User object nếu đăng ký thành công
  /// - Throws exception nếu có lỗi
  Future<auth.User?> signUp(
    String email,
    String password,
    String username,
  ) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (userCredential.user != null) {
        await _updateUserInFirestore(userCredential.user!, username: username);
      }
      return userCredential.user;
    } catch (e) {
      debugPrint('Lỗi đăng ký: $e');
      rethrow;
    }
  }

  /// Đăng nhập với email và mật khẩu
  ///
  /// Parameters:
  /// - email: Email đăng nhập
  /// - password: Mật khẩu
  ///
  /// Returns:
  /// - User object nếu đăng nhập thành công
  /// - Throws exception nếu có lỗi
  Future<auth.User?> signIn(String email, String password) async {
    try {
      return (await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      )).user;
    } catch (e) {
      debugPrint('Lỗi đăng nhập: $e');
      rethrow;
    }
  }

  /// Đăng nhập bằng tài khoản Google
  ///
  /// Returns:
  /// - User object nếu đăng nhập thành công
  /// - null nếu người dùng hủy đăng nhập
  /// - Throws exception nếu có lỗi
  Future<auth.User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication; 
      final credential = auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user != null) {
        await _updateUserInFirestore(user);
      }
      return user;
    } catch (e) {
      debugPrint('Lỗi đăng nhập Google: $e');
      rethrow;
    }
  }

  /// Đăng xuất khỏi tài khoản hiện tại
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  /// Gửi email đặt lại mật khẩu
  ///
  /// Parameters:
  /// - email: Email cần đặt lại mật khẩu
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Lỗi gửi email đặt lại mật khẩu: $e');
      rethrow;
    }
  }

  /// Lấy stream thông tin người dùng
  ///
  /// Returns:
  /// - Stream<AppUser?> chứa thông tin người dùng
  Stream<app_user.AppUser?> getUserProfileStream() {
    if (currentUserId == null) return Stream.value(null);
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .snapshots()
        .map((doc) => doc.exists ? app_user.AppUser.fromFirestore(doc) : null);
  }

  /// Lấy thông tin người dùng một lần
  ///
  /// Returns:
  /// - AppUser? chứa thông tin người dùng
  Future<app_user.AppUser?> getUserProfileOnce() async {
    if (currentUserId == null) return null;
    final doc = await _firestore.collection('users').doc(currentUserId).get();
    return doc.exists ? app_user.AppUser.fromFirestore(doc) : null;
  }

  /// Cập nhật thông tin người dùng
  ///
  /// Parameters:
  /// - user: Đối tượng AppUser chứa thông tin cần cập nhật
  Future<void> updateUserProfile(app_user.AppUser user) async {
    if (currentUserId == null || currentUserId != user.id) return;
    await _firestore.collection('users').doc(user.id).update(user.toJson());
  }

  /// Cập nhật hoặc tạo mới thông tin người dùng trong Firestore
  ///
  /// Parameters:
  /// - user: Đối tượng User từ Firebase Auth
  /// - username: Tên người dùng (optional)
  Future<void> _updateUserInFirestore(
    auth.User user, {
    String? username,
  }) async {
    final docRef = _firestore.collection('users').doc(user.uid);
    final doc = await docRef.get();
    if (!doc.exists) {
      final newUser = app_user.AppUser(
        id: user.uid,
        username:
            username ??
            user.displayName ??
            user.email?.split('@').first ??
            'Người dùng mới',
        email: user.email!,
        createdAt: DateTime.now(),
        phone: user.phoneNumber,
        avatar: user.photoURL,
        defaultCategoriesAdded: false,
      );
      await docRef.set(newUser.toJson());
    }
  }

  // --- EXPENSES ---

  /// Lấy stream danh sách chi tiêu
  ///
  /// Returns:
  /// - Stream<List<Expense>> chứa danh sách chi tiêu
  Stream<List<Expense>> getExpensesStream() {
    if (currentUserId == null) return Stream.value([]);
    return _firestore
        .collection('expenses')
        .where('userId', isEqualTo: currentUserId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Expense.fromFirestore(doc)).toList(),
        );
  }

  /// Lưu hoặc cập nhật chi tiêu
  ///
  /// Parameters:
  /// - expense: Đối tượng Expense cần lưu
  Future<void> saveExpense(Expense expense) async {
    if (currentUserId == null) throw Exception('Người dùng chưa đăng nhập.');
    final collection = _firestore.collection('expenses');
    if (expense.id != null) {
      await collection.doc(expense.id).update(expense.toJson());
    } else {
      await collection.add(expense.toJson());
    }
  }

  /// Xóa chi tiêu
  ///
  /// Parameters:
  /// - expenseId: ID của chi tiêu cần xóa
  Future<void> deleteExpense(String expenseId) async {
    await _firestore.collection('expenses').doc(expenseId).delete();
  }

  // --- CATEGORIES ---

  /// Lấy stream danh sách danh mục
  ///
  /// Returns:
  /// - Stream<List<Category>> chứa danh sách danh mục
  Stream<List<app_category.Category>> getCategoriesStream() {
    if (currentUserId == null) return Stream.value([]);
    return _firestore
        .collection('categories')
        .where('userId', isEqualTo: currentUserId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => app_category.Category.fromFirestore(doc))
                  .toList(),
        );
  }

  /// Lưu hoặc cập nhật danh mục
  ///
  /// Parameters:
  /// - category: Đối tượng Category cần lưu
  ///
  /// Returns:
  /// - Category đã được lưu với ID mới (nếu là tạo mới)
  Future<app_category.Category> saveCategory(
    app_category.Category category,
  ) async {
    if (currentUserId == null) throw Exception('Người dùng chưa đăng nhập.');
    final collection = _firestore.collection('categories');
    if (category.id != null) {
      await collection.doc(category.id).update(category.toJson());
      return category;
    } else {
      final docRef = await collection.add(category.toJson());
      return app_category.Category(
        id: docRef.id,
        name: category.name,
        icon: category.icon,
        color: category.color,
        userId: category.userId,
      );
    }
  }

  /// Xóa danh mục
  ///
  /// Parameters:
  /// - categoryId: ID của danh mục cần xóa
  Future<void> deleteCategory(String categoryId) async {
    if (currentUserId == null) throw Exception('Người dùng chưa đăng nhập.');
    await _firestore.collection('categories').doc(categoryId).delete();
  }

  /// Lấy danh sách danh mục một lần
  ///
  /// Returns:
  /// - List<Category> chứa danh sách danh mục
  Future<List<app_category.Category>> getCategoriesOnce() async {
    if (currentUserId == null) return [];
    final snapshot =
        await _firestore
            .collection('categories')
            .where('userId', isEqualTo: currentUserId)
            .get();
    return snapshot.docs
        .map((doc) => app_category.Category.fromFirestore(doc))
        .toList();
  }

  // --- BUDGETS ---

  /// Lấy stream danh sách ngân sách theo tháng và năm
  ///
  /// Parameters:
  /// - month: Tháng cần lấy
  /// - year: Năm cần lấy
  ///
  /// Returns:
  /// - Stream<List<Budget>> chứa danh sách ngân sách
  Stream<List<app_budget.Budget>> getBudgetsStream(int month, int year) {
    if (currentUserId == null) return Stream.value([]);
    return _firestore
        .collection('budgets')
        .where('userId', isEqualTo: currentUserId)
        .where('month', isEqualTo: month)
        .where('year', isEqualTo: year)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => app_budget.Budget.fromFirestore(doc))
                  .toList(),
        );
  }

  /// Lưu hoặc cập nhật ngân sách
  ///
  /// Parameters:
  /// - budget: Đối tượng Budget cần lưu
  Future<void> saveBudget(app_budget.Budget budget) async {
    if (currentUserId == null) return;
    final collection = _firestore.collection('budgets');
    if (budget.id != null) {
      await collection.doc(budget.id).update(budget.toJson());
    } else {
      await collection.add(budget.toJson());
    }
  }

  /// Xóa ngân sách
  ///
  /// Parameters:
  /// - budgetId: ID của ngân sách cần xóa
  Future<void> deleteBudget(String budgetId) async {
    await _firestore.collection('budgets').doc(budgetId).delete();
  }

  // --- REMINDERS ---

  /// Lấy stream danh sách nhắc nhở
  ///
  /// Returns:
  /// - Stream<List<Reminder>> chứa danh sách nhắc nhở
  Stream<List<app_reminder.Reminder>> getRemindersStream() {
    if (currentUserId == null) return Stream.value([]);
    return _firestore
        .collection('reminders')
        .where('userId', isEqualTo: currentUserId)
        .orderBy('scheduledTime', descending: false)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => app_reminder.Reminder.fromFirestore(doc))
                  .toList(),
        );
  }

  /// Lưu hoặc cập nhật nhắc nhở
  ///
  /// Parameters:
  /// - reminder: Đối tượng Reminder cần lưu
  Future<void> saveReminder(app_reminder.Reminder reminder) async {
    if (currentUserId == null) throw Exception('Người dùng chưa đăng nhập.');
    final collection = _firestore.collection('reminders');
    if (reminder.id != null) {
      await collection.doc(reminder.id).update(reminder.toJson());
    } else {
      await collection.add(reminder.toJson());
    }
  }

  /// Xóa nhắc nhở
  ///
  /// Parameters:
  /// - reminderId: ID của nhắc nhở cần xóa
  Future<void> deleteReminder(String reminderId) async {
    await _firestore.collection('reminders').doc(reminderId).delete();
  }

  /// Lấy thông tin nhắc nhở theo ID
  ///
  /// Parameters:
  /// - reminderId: ID của nhắc nhở cần lấy
  ///
  /// Returns:
  /// - Reminder? chứa thông tin nhắc nhở
  Future<app_reminder.Reminder?> getReminderById(String reminderId) async {
    try {
      final doc =
          await _firestore.collection('reminders').doc(reminderId).get();
      return doc.exists ? app_reminder.Reminder.fromFirestore(doc) : null;
    } catch (e) {
      debugPrint('Lỗi khi lấy nhắc nhở theo ID $reminderId: $e');
      return null;
    }
  }
}
