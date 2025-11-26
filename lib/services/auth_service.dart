import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';

/// Authentication service that handles password and biometric authentication
class AuthService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  static const String _passwordHashKey = 'user_password_hash';
  static const String _firstTimeKey = 'is_first_time';
  static const String _biometricsEnabledKey = 'biometrics_enabled';

  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Check if this is the first time launching the app (no password set)
  Future<bool> isFirstTime() async {
    try {
      final isFirstTime = await _storage.read(key: _firstTimeKey);
      return isFirstTime == null || isFirstTime == 'true';
    } catch (e) {
      return true; // Default to first time if there's an error
    }
  }

  /// Create and store the user's password
  Future<bool> createPassword(String password) async {
    try {
      if (password.isEmpty) return false;

      final passwordHash = _hashPassword(password);
      await _storage.write(key: _passwordHashKey, value: passwordHash);
      await _storage.write(key: _firstTimeKey, value: 'false');

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Verify the provided password against stored hash
  Future<bool> verifyPassword(String password) async {
    try {
      final storedHash = await _storage.read(key: _passwordHashKey);
      if (storedHash == null) return false;

      final passwordHash = _hashPassword(password);
      return passwordHash == storedHash;
    } catch (e) {
      return false;
    }
  }

  /// Check if biometric authentication is available on the device
  Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Check if biometric authentication is enabled by the user
  Future<bool> isBiometricEnabled() async {
    try {
      final enabled = await _storage.read(key: _biometricsEnabledKey);
      return enabled == 'true';
    } catch (e) {
      return false;
    }
  }

  /// Enable or disable biometric authentication
  Future<bool> setBiometricEnabled(bool enabled) async {
    try {
      await _storage.write(
          key: _biometricsEnabledKey, value: enabled.toString());
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Authenticate using biometrics
  Future<bool> authenticateWithBiometrics({
    String reason = 'Please authenticate to access your locker',
  }) async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) return false;

      final isEnabled = await isBiometricEnabled();
      if (!isEnabled) return false;

      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: reason,
        authMessages: [
          const AndroidAuthMessages(
            signInTitle: 'Biometric authentication required',
            cancelButton: 'No thanks',
          ),
          const IOSAuthMessages(
            cancelButton: 'No thanks',
          ),
        ],
      );

      return isAuthenticated;
    } on PlatformException catch (e) {
      // Handle specific biometric errors
      if (e.code == 'NotAvailable') {
        return false;
      } else if (e.code == 'NotEnrolled') {
        return false;
      } else if (e.code == 'LockedOut' || e.code == 'PermanentlyLockedOut') {
        return false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Setup biometric authentication (should be called after password is set)
  Future<bool> setupBiometricAuthentication() async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) return false;

      final biometrics = await getAvailableBiometrics();
      if (biometrics.isEmpty) return false;

      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Set up biometric authentication',
        authMessages: [
          const AndroidAuthMessages(
            signInTitle: 'Set up biometric authentication',
            cancelButton: 'Cancel setup',
          ),
          const IOSAuthMessages(
            cancelButton: 'Cancel setup',
          ),
        ],
      );

      if (isAuthenticated) {
        await setBiometricEnabled(true);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Reset all authentication data (for testing or reset functionality)
  Future<bool> resetAuth() async {
    try {
      await _storage.delete(key: _passwordHashKey);
      await _storage.delete(key: _firstTimeKey);
      await _storage.delete(key: _biometricsEnabledKey);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Hash password using SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Get biometric type display name
  String getBiometricDisplayName(List<BiometricType> biometrics) {
    if (biometrics.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    } else if (biometrics.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (biometrics.contains(BiometricType.iris)) {
      return 'Iris';
    } else if (biometrics.contains(BiometricType.strong) ||
        biometrics.contains(BiometricType.weak)) {
      return 'Biometric';
    }
    return 'Biometric';
  }
}
