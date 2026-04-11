/// Security Service
/// Comprehensive security checks to prevent app tampering and hacking
library;

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class SecurityService extends GetxService {
  static SecurityService get to => Get.find();

  final RxBool isDeviceCompromised = false.obs;
  final RxBool isAppTampered = false.obs;
  final RxBool isDebuggerAttached = false.obs;
  final RxBool isEmulator = false.obs;
  
  Future<SecurityService> init() async {
    await _performSecurityChecks();
    return this;
  }
  
  Future<void> _performSecurityChecks() async {
    await Future.wait([
      _checkRootJailbreak(),
      _checkDebugMode(),
      _checkEmulator(),
      _checkHookingFrameworks(),
    ]);
  }
  
  /// Check for root (Android) or jailbreak (iOS)
  Future<void> _checkRootJailbreak() async {
    try {
      if (Platform.isAndroid) {
        final rootPaths = [
          '/system/app/Superuser.apk',
          '/sbin/su',
          '/system/bin/su',
          '/system/xbin/su',
          '/data/local/xbin/su',
          '/data/local/bin/su',
          '/system/sd/xbin/su',
          '/system/bin/failsafe/su',
          '/data/local/su',
          '/su/bin/su',
          '/system/xbin/daemonsu',
          '/system/etc/init.d/99teleroot',
          '/magisk',
          '/sbin/.magisk',
          '/data/adb/magisk',
        ];
        
        for (final path in rootPaths) {
          if (await File(path).exists()) {
            isDeviceCompromised.value = true;
            debugPrint('SecurityService: Root indicator found at $path');
            return;
          }
        }
        
      } else if (Platform.isIOS) {
        final jailbreakPaths = [
          '/Applications/Cydia.app',
          '/Library/MobileSubstrate/MobileSubstrate.dylib',
          '/bin/bash',
          '/usr/sbin/sshd',
          '/etc/apt',
          '/private/var/lib/apt/',
          '/private/var/lib/cydia',
          '/private/var/stash',
          '/usr/bin/ssh',
          '/var/checkra1n.dmg',
          '/Applications/blackra1n.app',
        ];
        
        for (final path in jailbreakPaths) {
          if (await File(path).exists()) {
            isDeviceCompromised.value = true;
            debugPrint('SecurityService: Jailbreak indicator found at $path');
            return;
          }
        }
        
        // Check if app can write outside sandbox
        try {
          final file = File('/private/jailbreak_test.txt');
          await file.writeAsString('test');
          await file.delete();
          isDeviceCompromised.value = true;
          debugPrint('SecurityService: Can write outside sandbox - jailbroken');
          return;
        } catch (e) {
          // Expected - can't write outside sandbox
        }
      }
    } catch (e) {
      debugPrint('SecurityService: Error checking root/jailbreak: $e');
    }
  }
  
  /// Check if debugger is attached
  Future<void> _checkDebugMode() async {
    // Check for debug mode
    if (kDebugMode) {
      isDebuggerAttached.value = true;
      debugPrint('SecurityService: Debug mode detected');
    }
    
    // Check for profile mode
    if (kProfileMode) {
      debugPrint('SecurityService: Profile mode detected');
    }
  }
  
  /// Check if running on emulator
  Future<void> _checkEmulator() async {
    try {
      if (Platform.isAndroid) {
        // Common emulator indicators
        final emulatorIndicators = [
          '/dev/socket/qemud',
          '/dev/qemu_pipe',
          '/system/bin/qemu-props',
          '/dev/goldfish_pipe',
        ];
        
        for (final path in emulatorIndicators) {
          if (await File(path).exists()) {
            isEmulator.value = true;
            debugPrint('SecurityService: Emulator detected');
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('SecurityService: Error checking emulator: $e');
    }
  }
  
  /// Check for hooking frameworks (Frida, Xposed, etc.)
  Future<void> _checkHookingFrameworks() async {
    try {
      if (Platform.isAndroid) {
        // Check for Frida
        final fridaIndicators = [
          '/data/local/tmp/frida-server',
          '/data/local/tmp/re.frida.server',
        ];
        
        for (final path in fridaIndicators) {
          if (await File(path).exists()) {
            isAppTampered.value = true;
            debugPrint('SecurityService: Frida detected');
            return;
          }
        }
        
        // Check for Xposed
        final xposedPaths = [
          '/system/framework/XposedBridge.jar',
          '/data/data/de.robv.android.xposed.installer',
        ];
        
        for (final path in xposedPaths) {
          if (await File(path).exists()) {
            isAppTampered.value = true;
            debugPrint('SecurityService: Xposed detected');
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('SecurityService: Error checking hooking frameworks: $e');
    }
  }
  
  /// Check if the app is secure to run
  bool isSecure() {
    // In release mode, block compromised devices
    if (kReleaseMode) {
      return !isDeviceCompromised.value && !isAppTampered.value;
    }
    // In debug/profile mode, allow for development
    return true;
  }
  
  /// Generate a secure hash for data verification
  String generateHash(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  /// Verify data integrity
  bool verifyHash(String data, String expectedHash) {
    return generateHash(data) == expectedHash;
  }
  
  /// Encrypt sensitive data (basic obfuscation)
  String encryptData(String data, String key) {
    final keyBytes = utf8.encode(key);
    final dataBytes = utf8.encode(data);
    
    final encrypted = List<int>.generate(
      dataBytes.length,
      (i) => dataBytes[i] ^ keyBytes[i % keyBytes.length],
    );
    
    return base64.encode(encrypted);
  }
  
  /// Decrypt sensitive data
  String decryptData(String encryptedData, String key) {
    try {
      final keyBytes = utf8.encode(key);
      final dataBytes = base64.decode(encryptedData);
      
      final decrypted = List<int>.generate(
        dataBytes.length,
        (i) => dataBytes[i] ^ keyBytes[i % keyBytes.length],
      );
      
      return utf8.decode(decrypted);
    } catch (e) {
      return '';
    }
  }
  
  /// Log security event (would send to analytics in production)
  void logSecurityEvent(String event, Map<String, dynamic> data) {
    debugPrint('SecurityEvent: $event - $data');
    // In production, send to analytics/logging service
  }
}
