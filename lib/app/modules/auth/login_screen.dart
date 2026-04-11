/// Login Screen
/// Beautiful authentication screen with Email, Google, and Apple Sign-In
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';
import 'auth_controller.dart';

class LoginScreen extends GetView<AuthController> {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(
      () => PopScope(
        canPop: controller.isLogin.value,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          controller.toggleAuthMode();
        },
        child: Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF1A1A2E),
                        const Color(0xFF16213E),
                        const Color(0xFF0F3460),
                      ]
                    : [
                        AppColors.primaryLight.withValues(alpha: 0.1),
                        AppColors.secondaryLight.withValues(alpha: 0.05),
                        Colors.white,
                      ],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Obx(
                  () => controller.isLogin.value
                      ? _buildLoginForm(isDark)
                      : _buildSignUpForm(isDark),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 40.h),

        // Logo and Title
        Center(
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(AppAssets.appLogo, height: 100.h),
              ),
              SizedBox(height: 20.h),
              Text(
                'Stock Scanner AI',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Sign in to continue',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
                ),
              ),
              SizedBox(height: 16.h),
              // Skip / Continue as Guest – prominent secondary button
              SizedBox(height: 8.h),
              Obx(
                () {
                  final loading = Get.find<AuthService>().isLoading.value;
                  return SizedBox(
                    width: double.infinity,
                    height: 48.h,
                    child: OutlinedButton.icon(
                      onPressed: loading ? null : controller.continueAsGuest,
                      icon: loading
                          ? SizedBox(
                              width: 18.w,
                              height: 18.w,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: isDark
                                    ? Colors.white54
                                    : AppColors.primaryLight,
                              ),
                            )
                          : Icon(
                              Icons.person_outline_rounded,
                              size: 20.w,
                              color: isDark
                                  ? Colors.white70
                                  : AppColors.primaryLight,
                            ),
                      label: Text(
                        'Continue as Guest',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white70
                              : AppColors.primaryLight,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: isDark
                              ? Colors.white24
                              : AppColors.primaryLight.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        SizedBox(height: 32.h),

        _buildTextField(
          controller: controller.emailController,
          label: 'Email',
          hint: 'Enter your email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          isDark: isDark,
        ),

        SizedBox(height: 16.h),

        // Password Field
        Obx(
          () => _buildTextField(
            controller: controller.passwordController,
            label: 'Password',
            hint: 'Enter your password',
            icon: Icons.lock_outline,
            isPassword: true,
            showPassword: controller.showPassword.value,
            onTogglePassword: controller.togglePasswordVisibility,
            isDark: isDark,
          ),
        ),

        // Forgot Password
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: controller.sendPasswordResetEmail,
            child: Text(
              'Forgot Password?',
              style: TextStyle(
                color: AppColors.primaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        // Error Message
        Obx(() {
          final error = Get.find<AuthService>().errorMessage.value;
          if (error.isEmpty) return const SizedBox.shrink();
          return Container(
            padding: EdgeInsets.all(12.r),
            margin: EdgeInsets.only(bottom: 16.h),
            decoration: BoxDecoration(
              color: AppColors.errorLight.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: AppColors.errorLight.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: AppColors.errorLight,
                  size: 20.w,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    error,
                    style: TextStyle(
                      color: AppColors.errorLight,
                      fontSize: 13.sp,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),

        // Sign In Button
        Obx(
          () => _buildPrimaryButton(
            label: 'Sign In',
            onPressed: controller.signInWithEmail,
            isLoading: Get.find<AuthService>().isLoading.value,
          ),
        ),

        SizedBox(height: 24.h),

        // Divider
        Row(
          children: [
            Expanded(
              child: Divider(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Text(
                'OR',
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
              ),
            ),
          ],
        ),

        SizedBox(height: 24.h),

        // Social Sign In Buttons
        Obx(() {
          final loading = Get.find<AuthService>().isLoading.value;
          return _buildSocialButton(
            label: 'Continue with Google',
            icon: 'G',
            color: Colors.white,
            textColor: Colors.black87,
            onPressed: loading ? null : controller.signInWithGoogle,
            isDark: isDark,
          );
        }),

        if (Platform.isIOS) ...[
          SizedBox(height: 12.h),
          Obx(() {
            final loading = Get.find<AuthService>().isLoading.value;
            return _buildSocialButton(
              label: 'Continue with Apple',
              icon: '',
              isApple: true,
              color: isDark ? Colors.white : Colors.black,
              textColor: isDark ? Colors.black : Colors.white,
              onPressed: loading ? null : controller.signInWithApple,
              isDark: isDark,
            );
          }),
        ],

        SizedBox(height: 32.h),

        // Sign Up Link
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Don't have an account? ",
                style: TextStyle(
                  color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
                ),
              ),
              GestureDetector(
                onTap: controller.toggleAuthMode,
                child: Text(
                  'Sign Up',
                  style: TextStyle(
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 32.h),
      ],
    );
  }

  Widget _buildSignUpForm(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 40.h),

        // Back Button
        IconButton(
          onPressed: controller.toggleAuthMode,
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? Colors.white : AppColors.textPrimaryLight,
          ),
        ),

        SizedBox(height: 20.h),

        // Title
        Text(
          'Create Account',
          style: TextStyle(
            fontSize: 28.sp,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimaryLight,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'Sign up to get started',
          style: TextStyle(
            fontSize: 16.sp,
            color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
          ),
        ),

        SizedBox(height: 32.h),

        // Name Field
        _buildTextField(
          controller: controller.nameController,
          label: 'Full Name',
          hint: 'Enter your full name',
          icon: Icons.person_outline,
          isDark: isDark,
        ),

        SizedBox(height: 16.h),

        // Email Field
        _buildTextField(
          controller: controller.emailController,
          label: 'Email',
          hint: 'Enter your email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          isDark: isDark,
        ),

        SizedBox(height: 16.h),

        // Password Field
        Obx(
          () => _buildTextField(
            controller: controller.passwordController,
            label: 'Password',
            hint: 'Create a password',
            icon: Icons.lock_outline,
            isPassword: true,
            showPassword: controller.showPassword.value,
            onTogglePassword: controller.togglePasswordVisibility,
            isDark: isDark,
          ),
        ),

        SizedBox(height: 16.h),

        // Confirm Password Field
        Obx(
          () => _buildTextField(
            controller: controller.confirmPasswordController,
            label: 'Confirm Password',
            hint: 'Confirm your password',
            icon: Icons.lock_outline,
            isPassword: true,
            showPassword: controller.showConfirmPassword.value,
            onTogglePassword: controller.toggleConfirmPasswordVisibility,
            isDark: isDark,
          ),
        ),

        SizedBox(height: 24.h),

        // Error Message
        Obx(() {
          final error = Get.find<AuthService>().errorMessage.value;
          if (error.isEmpty) return const SizedBox.shrink();
          return Container(
            padding: EdgeInsets.all(12.r),
            margin: EdgeInsets.only(bottom: 16.h),
            decoration: BoxDecoration(
              color: AppColors.errorLight.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: AppColors.errorLight.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: AppColors.errorLight,
                  size: 20.w,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    error,
                    style: TextStyle(
                      color: AppColors.errorLight,
                      fontSize: 13.sp,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),

        // Sign Up Button
        Obx(
          () => _buildPrimaryButton(
            label: 'Create Account',
            onPressed: controller.signUpWithEmail,
            isLoading: Get.find<AuthService>().isLoading.value,
          ),
        ),

        SizedBox(height: 24.h),

        // Sign In Link
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Already have an account? ',
                style: TextStyle(
                  color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
                ),
              ),
              GestureDetector(
                onTap: controller.toggleAuthMode,
                child: Text(
                  'Sign In',
                  style: TextStyle(
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 32.h),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    bool showPassword = false,
    VoidCallback? onTogglePassword,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppColors.textPrimaryLight,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isDark ? Colors.white24 : Colors.grey.shade300,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: isPassword && !showPassword,
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: isDark ? Colors.white38 : Colors.grey,
              ),
              prefixIcon: Icon(
                icon,
                color: isDark ? Colors.white54 : Colors.grey,
              ),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        showPassword ? Icons.visibility_off : Icons.visibility,
                        color: isDark ? Colors.white54 : Colors.grey,
                      ),
                      onPressed: onTogglePassword,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 14.h,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54.h,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? SizedBox(
                width: 24.w,
                height: 24.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                label,
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  Widget _buildSocialButton({
    required String label,
    required String icon,
    required Color color,
    required Color textColor,
    required VoidCallback? onPressed,
    required bool isDark,
    bool isApple = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54.h,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: color,
          side: BorderSide(
            color: isDark ? Colors.white24 : Colors.grey.shade300,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 17.sp,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
