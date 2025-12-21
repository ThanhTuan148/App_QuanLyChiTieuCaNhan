/// Màn hình đăng nhập với design mới - Green theme
// lib/screens/login_screen.dart

// ignore_for_file: curly_braces_in_flow_control_structures, use_build_context_synchronously

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/glass_card.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;
    setState(() => _isLoading = true);
    try {
      await context.read<AuthProvider>().login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đăng nhập thất bại: Sai tài khoản hoặc mật khẩu!'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showForgotPasswordDialog() {
    final emailResetController = TextEditingController();
    final dialogFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Đặt lại mật khẩu', style: GoogleFonts.poppins()),
        content: Form(
          key: dialogFormKey,
          child: TextFormField(
            controller: emailResetController,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Nhập email đã đăng ký',
              labelStyle: GoogleFonts.poppins(),
            ),
            style: GoogleFonts.poppins(),
            validator: (value) =>
                (value == null || value.isEmpty || !value.contains('@'))
                    ? 'Vui lòng nhập email hợp lệ'
                    : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Hủy', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () async {
              if (dialogFormKey.currentState!.validate()) {
                final email = emailResetController.text.trim();
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Đang gửi email...', style: GoogleFonts.poppins())),
                );
                try {
                  await context.read<AuthProvider>().sendPasswordResetEmail(email);
                  if (mounted)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Đã gửi link. Vui lòng kiểm tra hộp thư!', style: GoogleFonts.poppins()),
                        backgroundColor: Colors.green,
                      ),
                    );
                } catch (e) {
                  if (mounted)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lỗi: ${e.toString()}', style: GoogleFonts.poppins()),
                        backgroundColor: Colors.red,
                      ),
                    );
                }
              }
            },
            child: Text('Gửi', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0B140E) : const Color(0xFFF4F9F5),
        ),
        child: Stack(
          children: [
            // Background blur circles
            Positioned(
              top: -80,
              left: -80,
              child: Container(
                width: 256,
                height: 256,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF4CAF50).withOpacity(isDark ? 0.1 : 0.2),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.33,
              right: -80,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF10B981).withOpacity(isDark ? 0.1 : 0.2),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              left: MediaQuery.of(context).size.width * 0.25,
              child: Container(
                width: 288,
                height: 288,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF81C784).withOpacity(isDark ? 0.1 : 0.2),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
            // Main content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Logo/Icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF4CAF50),
                              isDark ? const Color(0xFF81C784) : const Color(0xFFC8E6C9),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4CAF50).withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Transform.rotate(
                          angle: 0.05,
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Welcome text
                      Text(
                        'Welcome Back!',
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFFECFDF5) : const Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Manage your expenses with ease & joy.',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Login form card
                      GlassCard(
                        padding: const EdgeInsets.all(32),
                        borderRadius: 24,
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Email field
                              Text(
                                'EMAIL ADDRESS',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.2,
                                  color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: GoogleFonts.poppins(
                                  color: isDark ? const Color(0xFFECFDF5) : const Color(0xFF1F2937),
                                ),
                                decoration: InputDecoration(
                                  hintText: 'hello@example.com',
                                  hintStyle: GoogleFonts.poppins(
                                    color: isDark ? const Color(0xFF9CA3AF).withOpacity(0.5) : const Color(0xFF9CA3AF),
                                  ),
                                  prefixIcon: Icon(
                                    Icons.email_rounded,
                                    color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF9CA3AF),
                                  ),
                                  filled: true,
                                  fillColor: isDark ? const Color(0xFF0B140E) : const Color(0xFFF3F4F6),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                ),
                                validator: (value) =>
                                    (value == null || value.isEmpty || !value.contains('@'))
                                        ? 'Vui lòng nhập email hợp lệ'
                                        : null,
                              ),
                              const SizedBox(height: 24),
                              // Password field
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'PASSWORD',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.2,
                                      color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _showForgotPasswordDialog,
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      'Forgot?',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF4CAF50),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: !_isPasswordVisible,
                                style: GoogleFonts.poppins(
                                  color: isDark ? const Color(0xFFECFDF5) : const Color(0xFF1F2937),
                                ),
                                decoration: InputDecoration(
                                  hintText: '••••••••',
                                  hintStyle: GoogleFonts.poppins(
                                    color: isDark ? const Color(0xFF9CA3AF).withOpacity(0.5) : const Color(0xFF9CA3AF),
                                  ),
                                  prefixIcon: Icon(
                                    Icons.lock_rounded,
                                    color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF9CA3AF),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                      color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF9CA3AF),
                                    ),
                                    onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                                  ),
                                  filled: true,
                                  fillColor: isDark ? const Color(0xFF0B140E) : const Color(0xFFF3F4F6),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                ),
                                validator: (value) =>
                                    (value == null || value.length < 6)
                                        ? 'Mật khẩu phải có ít nhất 6 ký tự'
                                        : null,
                              ),
                              const SizedBox(height: 32),
                              // Sign in button
                              ElevatedButton(
                                onPressed: _isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4CAF50),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 4,
                                  shadowColor: const Color(0xFF4CAF50).withOpacity(0.3),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Sign In',
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(Icons.arrow_forward_rounded, size: 20),
                                        ],
                                      ),
                              ),
                              const SizedBox(height: 24),
                              // Divider
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: isDark ? const Color(0xFF4CAF50).withOpacity(0.2) : const Color(0xFFE5E7EB),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      'Or continue with',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF9CA3AF),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: isDark ? const Color(0xFF4CAF50).withOpacity(0.2) : const Color(0xFFE5E7EB),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              // Social login buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _isLoading
                                          ? null
                                          : () async {
                                              setState(() => _isLoading = true);
                                              try {
                                                await context.read<AuthProvider>().signInWithGoogle();
                                              } catch (e) {
                                                if (mounted)
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('Đăng nhập Google thất bại: $e', style: GoogleFonts.poppins()),
                                                    ),
                                                  );
                                              } finally {
                                                if (mounted) setState(() => _isLoading = false);
                                              }
                                            },
                                      icon: Image.asset(
                                        'assets/images/google_logo.png',
                                        height: 20,
                                        width: 20,
                                        errorBuilder: (context, error, stackTrace) =>
                                            const Icon(Icons.g_mobiledata, size: 20),
                                      ),
                                      label: Text(
                                        'Google',
                                        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        side: BorderSide(
                                          color: isDark ? const Color(0xFF4CAF50).withOpacity(0.2) : const Color(0xFFE5E7EB),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        backgroundColor: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Sign up link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                            ),
                          ),
                          TextButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (ctx) => const RegisterScreen()),
                                    );
                                  },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Sign up',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF4CAF50),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Theme toggle button
            Positioned(
              bottom: 24,
              right: 24,
              child: FloatingActionButton(
                mini: true,
                onPressed: () => themeProvider.toggleDarkMode(),
                backgroundColor: isDark ? const Color(0xFF1E2824) : Colors.white,
                child: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  color: isDark ? const Color(0xFFECFDF5) : const Color(0xFF1F2937),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
