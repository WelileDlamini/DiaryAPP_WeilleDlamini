import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccessCodeService {
  static const String _accessCodeKey = 'access_code';
  static const String _accessCodeEnabledKey = 'access_code_enabled';
  static const String _loginStateKey = 'login_state';

  /// Check if an access code has been configured
  static Future<bool> hasAccessCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessCodeKey) != null;
  }

  /// Check if the access code is currently enabled
  static Future<bool> isAccessCodeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_accessCodeEnabledKey) ?? false;
  }

  /// Set up a new access code
  static Future<bool> setAccessCode(String code) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hashedCode = _hashCode(code);

      await prefs.setString(_accessCodeKey, hashedCode);
      await prefs.setBool(_accessCodeEnabledKey, true);

      return true;
    } catch (e) {
      print('Error setting access code: $e');
      return false;
    }
  }

  /// Verify an access code
  static Future<bool> verifyAccessCode(String code) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedHashedCode = prefs.getString(_accessCodeKey);

      if (storedHashedCode == null) {
        return false;
      }

      final hashedInputCode = _hashCode(code);
      return hashedInputCode == storedHashedCode;
    } catch (e) {
      print('Error verifying access code: $e');
      return false;
    }
  }

  /// Enable or disable the access code
  static Future<void> setAccessCodeEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_accessCodeEnabledKey, enabled);
  }

  /// Completely remove the access code
  static Future<void> removeAccessCode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessCodeKey);
    await prefs.remove(_accessCodeEnabledKey);
    await prefs.remove(_loginStateKey);
  }

  /// Mark that the user has already authenticated in this session
  static Future<void> setLoginState(bool loggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loginStateKey, loggedIn);
  }

  /// Check if the user has already authenticated in this session
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_loginStateKey) ?? false;
  }

  /// Clear the login state (for sign out)
  static Future<void> clearLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loginStateKey);
  }

  /// Hash the access code using SHA-256 for secure storage
  static String _hashCode(String code) {
    final bytes = utf8.encode(code);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Check if the app should show the PIN screen on launch
  static Future<bool> shouldShowPinScreen() async {
    // Show PIN only if:
    // 1. An access code has been configured
    // 2. The access code is enabled
    // 3. The user has not authenticated in this session
    final hasCode = await hasAccessCode();
    final isEnabled = await isAccessCodeEnabled();
    final isLoggedIn = await AccessCodeService.isLoggedIn();

    return hasCode && isEnabled && !isLoggedIn;
  }
}