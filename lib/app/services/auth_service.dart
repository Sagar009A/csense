/// Authentication Service
/// Handles Firebase Auth with Email, Google, and Apple Sign-In
library;

import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../routes/app_routes.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'credit_service.dart';

class AuthService extends GetxService {
  static AuthService get to => Get.find();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  late final Future<void> _googleSignInInitialized;

  final Rx<User?> currentUser = Rx<User?>(null);
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  bool get isLoggedIn => currentUser.value != null;
  /// True if user signed in anonymously (guest). Premium purchase requires login/register.
  bool get isGuest => currentUser.value?.isAnonymous ?? false;
  String? get userEmail => currentUser.value?.email;
  String? get userId => currentUser.value?.uid;
  String? get displayName => currentUser.value?.displayName;

  @override
  void onInit() {
    super.onInit();
    _googleSignInInitialized = _googleSignIn.initialize();
    // Listen to auth state changes
    currentUser.bindStream(_auth.authStateChanges());
    
    // When user logs in, initialize their credits
    ever(currentUser, (User? user) {
      if (user != null) {
        _initializeUserCredits(user);
      }
    });
  }

  Future<void> _initializeUserCredits(User user) async {
    try {
      final creditService = Get.find<CreditService>();
      await creditService.initializeUserCredits(
        user.uid,
        user.email ?? '',
        isGuest: user.isAnonymous,
      );
    } catch (e) {
      debugPrint('Error initializing user credits: $e');
    }
  }

  // Email/Password Sign Up
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (displayName != null && credential.user != null) {
        await credential.user!.updateDisplayName(displayName);
      }

      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage.value = _getErrorMessage(e.code);
      return false;
    } catch (e) {
      errorMessage.value = 'An unexpected error occurred';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Email/Password Sign In
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage.value = _getErrorMessage(e.code);
      return false;
    } catch (e) {
      errorMessage.value = 'An unexpected error occurred';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Google Sign In
  Future<bool> signInWithGoogle() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      await _googleSignInInitialized;
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      if (googleAuth.idToken == null) {
        errorMessage.value = 'Google sign in failed';
        return false;
      }

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('Google sign in FirebaseAuth error: ${e.code}');
      if (e.code == 'account-exists-with-different-credential') {
        errorMessage.value =
            'An account already exists with this email using a different sign-in method';
      } else {
        errorMessage.value = _getErrorMessage(e.code);
      }
      return false;
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('cancel') || msg.contains('sign_in_canceled')) {
        return false;
      }
      debugPrint('Google sign in error: $e');
      errorMessage.value = 'Google sign in failed';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Apple Sign In
  Future<bool> signInWithApple() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Generate nonce for security
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      debugPrint('Apple Sign-In: requesting credential with nonce...');

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      debugPrint('Apple Sign-In: got credential');
      debugPrint('  identityToken null? ${appleCredential.identityToken == null}');
      debugPrint('  identityToken length: ${appleCredential.identityToken?.length ?? 0}');
      debugPrint('  authorizationCode null? ${appleCredential.authorizationCode == null}');
      debugPrint('  email: ${appleCredential.email}');
      debugPrint('  userIdentifier: ${appleCredential.userIdentifier}');

      // Validate identity token before sending to Firebase
      if (appleCredential.identityToken == null ||
          appleCredential.identityToken!.isEmpty) {
        debugPrint('Apple Sign-In: identityToken is null/empty!');
        errorMessage.value = 'Apple sign in failed — no identity token received';
        return false;
      }

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
        accessToken: appleCredential.authorizationCode,
      );

      debugPrint('Apple Sign-In: signing in with Firebase credential...');
      final userCredential = await _auth.signInWithCredential(oauthCredential);
      debugPrint('Apple Sign-In: Firebase auth success! uid=${userCredential.user?.uid}');

      // Update display name if available (Apple only returns name on first sign-in)
      if (appleCredential.givenName != null && userCredential.user != null) {
        final name =
            '${appleCredential.givenName} ${appleCredential.familyName ?? ''}'
                .trim();
        await userCredential.user!.updateDisplayName(name);
      }

      return true;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return false;
      debugPrint('Apple sign in auth error: $e');
      errorMessage.value = 'Apple sign in failed';
      return false;
    } on FirebaseAuthException catch (e) {
      debugPrint('Apple sign in FirebaseAuth error: ${e.code} — ${e.message}');
      if (e.code == 'account-exists-with-different-credential') {
        errorMessage.value =
            'An account already exists with this email using a different sign-in method';
      } else if (e.code == 'invalid-credential') {
        errorMessage.value =
            'Apple sign in failed — Firebase could not verify the credential. '
            'Please check Firebase Apple provider configuration.';
      } else {
        errorMessage.value = _getErrorMessage(e.code);
      }
      return false;
    } catch (e) {
      debugPrint('Apple sign in error: $e');
      errorMessage.value = 'Apple sign in failed';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Guest (Anonymous) Sign In - skip login/register, use app as guest. Premium requires login.
  Future<bool> signInAsGuest() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      await _auth.signInAnonymously();
      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage.value = _getErrorMessage(e.code);
      return false;
    } catch (e) {
      errorMessage.value = 'Could not continue as guest';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Password Reset
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage.value = _getErrorMessage(e.code);
      return false;
    } catch (e) {
      errorMessage.value = 'Failed to send reset email';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try { await _googleSignIn.signOut(); } catch (e) {
      debugPrint('Google sign out error: $e');
    }
    try { await _auth.signOut(); } catch (e) {
      debugPrint('Firebase sign out error: $e');
    }
  }

  /// Permanently delete the current user's Firebase Auth account.
  /// Automatically re-authenticates before deleting to avoid
  /// `requires-recent-login` errors.
  /// Returns true on success. Caller is responsible for clearing local data.
  Future<bool> deleteAccount() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final user = _auth.currentUser;
      if (user == null) return false;

      // Try deleting directly first
      try {
        await user.delete();
        return true;
      } on FirebaseAuthException catch (e) {
        if (e.code != 'requires-recent-login') {
          errorMessage.value = _getErrorMessage(e.code);
          return false;
        }
        // Need re-authentication — fall through
        debugPrint('Delete account: requires re-authentication');
      }

      // Re-authenticate based on provider
      final reauthed = await _reauthenticateUser(user);
      if (!reauthed) {
        if (errorMessage.value.isEmpty) {
          errorMessage.value = 'Re-authentication failed. Please try again.';
        }
        return false;
      }

      // Now delete after re-auth
      await user.delete();
      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage.value = _getErrorMessage(e.code);
      return false;
    } catch (e) {
      debugPrint('Delete account error: $e');
      errorMessage.value = 'Failed to delete account';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Re-authenticate the user based on their sign-in provider.
  Future<bool> _reauthenticateUser(User user) async {
    try {
      final providerIds = user.providerData.map((p) => p.providerId).toList();

      if (user.isAnonymous) {
        // Anonymous users don't need re-auth
        return true;
      } else if (providerIds.contains('google.com')) {
        return await _reauthWithGoogle(user);
      } else if (providerIds.contains('apple.com')) {
        return await _reauthWithApple(user);
      } else {
        // Email/password — can't re-auth without password, sign out first
        errorMessage.value = 'Please sign out and sign in again, then try deleting.';
        return false;
      }
    } catch (e) {
      debugPrint('Re-authentication error: $e');
      return false;
    }
  }

  Future<bool> _reauthWithGoogle(User user) async {
    try {
      await _googleSignInInitialized;
      final googleUser = await _googleSignIn.authenticate();
      final googleAuth = googleUser.authentication;
      if (googleAuth.idToken == null) return false;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      await user.reauthenticateWithCredential(credential);
      return true;
    } catch (e) {
      debugPrint('Google re-auth error: $e');
      errorMessage.value = 'Google re-authentication failed';
      return false;
    }
  }

  Future<bool> _reauthWithApple(User user) async {
    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      if (appleCredential.identityToken == null ||
          appleCredential.identityToken!.isEmpty) {
        return false;
      }

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
        accessToken: appleCredential.authorizationCode,
      );
      await user.reauthenticateWithCredential(oauthCredential);
      return true;
    } catch (e) {
      debugPrint('Apple re-auth error: $e');
      errorMessage.value = 'Apple re-authentication failed';
      return false;
    }
  }

  /// Opens purchase screen directly. Login is NOT required per Apple Guideline 5.1.1.
  void openPurchaseScreenIfAllowed() {
    Get.toNamed(AppRoutes.purchase);
  }

  // Helper: Generate random nonce for Apple Sign In
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  // Helper: SHA256 hash for Apple Sign In nonce
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Helper: Get user-friendly error messages
  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'invalid-email':
        return 'Invalid email address';
      case 'weak-password':
        return 'Password is too weak';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'network-request-failed':
        return 'Network error. Check your connection';
      default:
        return 'Authentication failed';
    }
  }
}
