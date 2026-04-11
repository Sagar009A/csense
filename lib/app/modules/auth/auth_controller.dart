/// Auth Controller
/// Manages authentication state and navigation
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../routes/app_routes.dart';

class AuthController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final RxBool showPassword = false.obs;
  final RxBool showConfirmPassword = false.obs;
  final RxBool isLogin = true.obs;

  bool get isLoading => _authService.isLoading.value;
  String get errorMessage => _authService.errorMessage.value;

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() {
    showPassword.value = !showPassword.value;
  }

  void toggleConfirmPasswordVisibility() {
    showConfirmPassword.value = !showConfirmPassword.value;
  }

  void toggleAuthMode() {
    isLogin.value = !isLogin.value;
    _clearFields();
  }

  void _clearFields() {
    emailController.clear();
    passwordController.clear();
    nameController.clear();
    confirmPasswordController.clear();
    _authService.errorMessage.value = '';
  }

  // Email Sign In
  Future<void> signInWithEmail() async {
    if (!_validateEmailForm()) return;

    final success = await _authService.signInWithEmail(
      email: emailController.text.trim(),
      password: passwordController.text,
    );

    if (success) {
      _navigateToHome();
    }
  }

  // Email Sign Up
  Future<void> signUpWithEmail() async {
    if (!_validateSignUpForm()) return;

    final success = await _authService.signUpWithEmail(
      email: emailController.text.trim(),
      password: passwordController.text,
      displayName: nameController.text.trim(),
    );

    if (success) {
      _navigateToHome();
    }
  }

  // Google Sign In
  Future<void> signInWithGoogle() async {
    final success = await _authService.signInWithGoogle();
    if (success) {
      _navigateToHome();
    } else if (_authService.errorMessage.value.isNotEmpty) {
      _showSignInFailedSnackbar(_authService.errorMessage.value);
    }
  }

  // Apple Sign In
  Future<void> signInWithApple() async {
    final success = await _authService.signInWithApple();
    if (success) {
      _navigateToHome();
    } else if (_authService.errorMessage.value.isNotEmpty) {
      _showSignInFailedSnackbar(_authService.errorMessage.value);
    }
  }

  void _showSignInFailedSnackbar(String message) {
    Get.snackbar(
      'Sign In Failed',
      '$message. You can continue as Guest below.',
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppColors.warningLight.withAlpha(220),
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(12),
      icon: const Icon(Icons.info_outline, color: Colors.white),
    );
  }

  /// Skip login/register and continue as guest. Premium purchase will require login later.
  Future<void> continueAsGuest() async {
    final success = await _authService.signInAsGuest();
    if (success) {
      _navigateToHome();
    }
  }

  // Forgot Password
  Future<void> sendPasswordResetEmail() async {
    if (emailController.text.trim().isEmpty) {
      _authService.errorMessage.value = 'Please enter your email';
      return;
    }

    final success = await _authService.sendPasswordResetEmail(
      emailController.text.trim(),
    );

    if (success) {
      Get.snackbar(
        'Success',
        'Password reset email sent',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withAlpha(200),
        colorText: Colors.white,
      );
    }
  }

  bool _validateEmailForm() {
    if (emailController.text.trim().isEmpty) {
      _authService.errorMessage.value = 'Please enter your email';
      return false;
    }
    if (!_isValidEmail(emailController.text.trim())) {
      _authService.errorMessage.value = 'Please enter a valid email address';
      return false;
    }
    if (passwordController.text.isEmpty) {
      _authService.errorMessage.value = 'Please enter your password';
      return false;
    }
    return true;
  }

  // Email validation regex
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  bool _validateSignUpForm() {
    if (nameController.text.trim().isEmpty) {
      _authService.errorMessage.value = 'Please enter your name';
      return false;
    }
    if (nameController.text.trim().length < 2) {
      _authService.errorMessage.value = 'Name must be at least 2 characters';
      return false;
    }
    if (emailController.text.trim().isEmpty) {
      _authService.errorMessage.value = 'Please enter your email';
      return false;
    }
    if (!_isValidEmail(emailController.text.trim())) {
      _authService.errorMessage.value = 'Please enter a valid email address';
      return false;
    }
    if (passwordController.text.length < 6) {
      _authService.errorMessage.value = 'Password must be at least 6 characters';
      return false;
    }
    if (!_isStrongPassword(passwordController.text)) {
      _authService.errorMessage.value = 'Password must contain letters and numbers';
      return false;
    }
    if (passwordController.text != confirmPasswordController.text) {
      _authService.errorMessage.value = 'Passwords do not match';
      return false;
    }
    return true;
  }

  // Password strength validation
  bool _isStrongPassword(String password) {
    // At least one letter and one number
    final hasLetter = password.contains(RegExp(r'[a-zA-Z]'));
    final hasNumber = password.contains(RegExp(r'[0-9]'));
    return hasLetter && hasNumber;
  }

  void _navigateToHome() {
    Get.offAllNamed(AppRoutes.home);
  }
}
