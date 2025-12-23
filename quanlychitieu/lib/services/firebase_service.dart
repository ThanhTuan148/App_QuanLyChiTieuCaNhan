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
  /// Firebase Auth instance
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  /// Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Google Sign-In instance (API mới từ google_sign_in 7.x)
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  /// Lấy ID user hiện tại
  String? get currentUserId => _auth.currentUser?.uid;

  // ---------------------------------------------------------------------------
  // AUTHENTICATION
  // ---------------------------------------------------------------------------

  /// Đăng ký bằng Email / Password
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
        await _updateUserInFirestore(
          userCredential.user!,
          username: username,
        );
      }

      return userCredential.user;
    } catch (e) {
      debugPrint('Lỗi đăng ký: $e');
      rethrow;
    }
  }

  /// Đăng nhập Email / Password
  Future<auth.User?> signIn(String email, String password) async {
    try {
      return (await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      ))
          .user;
    } catch (e) {
      debugPrint('Lỗi đăng nhập: $e');
      rethrow;
    }
  }

  /// 🔐 Đăng nhập bằng Google (ĐÚNG CHUẨN google_sign_in 7.x)
  // Future<auth.User?> signInWithGoogle() async {
  //   try {
  //     /// Khởi tạo Google Sign-In
  //     await _googleSignIn.initialize(
  //       clientId: kIsWeb
  //           ? 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com'
  //           : null,
  //     );
  //
  //     /// Authenticate (API mới – thay cho signIn())
  //     final GoogleSignInAccount? googleUser =
  //     await _googleSignIn.authenticate();
  //
  //     if (googleUser == null) return null;
  //
  //     final GoogleSignInAuthentication googleAuth =
  //     await googleUser.authentication;
  //
  //     final credential = auth.GoogleAuthProvider.credential(
  //       accessToken: googleAuth.accessToken,
  //       idToken: googleAuth.idToken,
  //     );
  //
  //     final userCredential =
  //     await _auth.signInWithCredential(credential);
  //
  //     final user = userCredential.user;
  //
  //     if (user != null) {
  //       await _updateUserInFirestore(user);
  //     }
  //
  //     return user;
  //   } catch (e) {
  //     debugPrint('Lỗi đăng nhập Google: $e');
  //     rethrow;
  //   }
  // }
  Future<auth.User?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Trên web, google_sign_in package không hỗ trợ đầy đủ
        // Firebase Auth trên web cần cấu hình đặc biệt
        // Tạm thời thông báo rằng tính năng này chưa hỗ trợ trên web
        throw UnimplementedError(
          'Google Sign-In trên web chưa được hỗ trợ đầy đủ trong phiên bản hiện tại. '
          'Vui lòng sử dụng đăng nhập bằng email/password hoặc chạy ứng dụng trên mobile.',
        );
      } else {
        // Trên mobile, sử dụng google_sign_in package
        await _googleSignIn.initialize();

        // Sử dụng authenticate() trên mobile
        final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();

        if (googleUser == null) return null;

        // Lấy thông tin authentication
        final GoogleSignInAuthentication googleAuth = googleUser.authentication;

        // Tạo credential từ Google authentication
        final credential = auth.GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );

        // Đăng nhập vào Firebase với credential
        final userCredential = await _auth.signInWithCredential(credential);

        final user = userCredential.user;

        if (user != null) {
          await _updateUserInFirestore(user);
        }

        return user;
      }
    } catch (e) {
      debugPrint('Lỗi đăng nhập Google: $e');
      rethrow;
    }
  }

  /// Đăng xuất
  Future<void> signOut() async {
    // Đăng xuất Google Sign-In (nếu có)
    // Bọc trong try-catch để tránh lỗi nếu plugin chưa được khởi tạo (đặc biệt trên web)
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      // Bỏ qua lỗi nếu Google Sign-In chưa được khởi tạo hoặc không có người dùng đăng nhập Google
      // Điều này xảy ra khi người dùng đăng nhập bằng email/password thay vì Google
      debugPrint('Lỗi khi đăng xuất Google Sign-In (có thể bỏ qua): $e');
    }
    
    // Luôn đăng xuất Firebase Auth
    await _auth.signOut();
  }

  /// Gửi email reset mật khẩu
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ---------------------------------------------------------------------------
  // USER PROFILE
  // ---------------------------------------------------------------------------

  Stream<app_user.AppUser?> getUserProfileStream() {
    if (currentUserId == null) return Stream.value(null);

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .snapshots()
        .map(
          (doc) =>
      doc.exists ? app_user.AppUser.fromFirestore(doc) : null,
    );
  }

  Future<app_user.AppUser?> getUserProfileOnce() async {
    if (currentUserId == null) return null;

    final doc =
    await _firestore.collection('users').doc(currentUserId).get();

    return doc.exists ? app_user.AppUser.fromFirestore(doc) : null;
  }

  Future<void> updateUserProfile(app_user.AppUser user) async {
    if (currentUserId != user.id) return;
    await _firestore.collection('users').doc(user.id).update(user.toJson());
  }

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

  // ---------------------------------------------------------------------------
  // EXPENSES
  // ---------------------------------------------------------------------------

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

  Future<void> saveExpense(Expense expense) async {
    if (currentUserId == null) throw Exception('Chưa đăng nhập');

    final collection = _firestore.collection('expenses');

    if (expense.id != null) {
      await collection.doc(expense.id).update(expense.toJson());
    } else {
      await collection.add(expense.toJson());
    }
  }

  Future<void> deleteExpense(String expenseId) async {
    await _firestore.collection('expenses').doc(expenseId).delete();
  }

  // ---------------------------------------------------------------------------
  // CATEGORIES
  // ---------------------------------------------------------------------------

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

  Future<app_category.Category> saveCategory(
      app_category.Category category,
      ) async {
    if (currentUserId == null) throw Exception('Chưa đăng nhập');

    final collection = _firestore.collection('categories');

    if (category.id != null) {
      await collection.doc(category.id).update(category.toJson());
      return category;
    } else {
      final docRef = await collection.add(category.toJson());
      return category.copyWith(id: docRef.id);
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    await _firestore.collection('categories').doc(categoryId).delete();
  }

  // ---------------------------------------------------------------------------
  // BUDGETS
  // ---------------------------------------------------------------------------

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

  Future<void> saveBudget(app_budget.Budget budget) async {
    if (currentUserId == null) return;

    final collection = _firestore.collection('budgets');

    if (budget.id != null) {
      await collection.doc(budget.id).update(budget.toJson());
    } else {
      await collection.add(budget.toJson());
    }
  }

  Future<void> deleteBudget(String budgetId) async {
    await _firestore.collection('budgets').doc(budgetId).delete();
  }

  // ---------------------------------------------------------------------------
  // REMINDERS
  // ---------------------------------------------------------------------------

  Stream<List<app_reminder.Reminder>> getRemindersStream() {
    if (currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('reminders')
        .where('userId', isEqualTo: currentUserId)
        .orderBy('scheduledTime')
        .snapshots()
        .map(
          (snapshot) =>
          snapshot.docs
              .map((doc) => app_reminder.Reminder.fromFirestore(doc))
              .toList(),
    );
  }

  Future<void> saveReminder(app_reminder.Reminder reminder) async {
    if (currentUserId == null) throw Exception('Chưa đăng nhập');

    final collection = _firestore.collection('reminders');

    if (reminder.id != null) {
      await collection.doc(reminder.id).update(reminder.toJson());
    } else {
      await collection.add(reminder.toJson());
    }
  }

  Future<void> deleteReminder(String reminderId) async {
    await _firestore.collection('reminders').doc(reminderId).delete();
  }
}
