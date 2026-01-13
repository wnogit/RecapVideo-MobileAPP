import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Token Storage Service - Uses SharedPreferences for reliability
/// with FlutterSecureStorage as backup for sensitive data
class TokenStorageService {
  static const _secureStorage = FlutterSecureStorage();
  
  // Keys
  static const String _accessTokenKey = 'auth_access_token';
  static const String _refreshTokenKey = 'auth_refresh_token';
  static const String _userIdKey = 'auth_user_id';
  
  /// Save access token - uses SharedPreferences for reliability
  Future<void> saveAccessToken(String token) async {
    debugPrint('💾 Saving access token (${token.length} chars)');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, token);
    
    // Also save to secure storage as backup
    try {
      await _secureStorage.write(key: _accessTokenKey, value: token);
    } catch (e) {
      debugPrint('⚠️ Secure storage backup failed: $e');
    }
  }
  
  /// Get access token
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_accessTokenKey);
    debugPrint('📖 Reading access token: ${token != null ? "found (${token.length} chars)" : "null"}');
    
    // If not in SharedPreferences, try secure storage (migration)
    if (token == null || token.isEmpty) {
      try {
        final secureToken = await _secureStorage.read(key: _accessTokenKey);
        if (secureToken != null && secureToken.isNotEmpty) {
          debugPrint('📖 Found token in secure storage, migrating...');
          await saveAccessToken(secureToken); // Migrate to SharedPreferences
          return secureToken;
        }
      } catch (e) {
        debugPrint('⚠️ Secure storage read failed: $e');
      }
    }
    
    return token;
  }
  
  /// Save refresh token
  Future<void> saveRefreshToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_refreshTokenKey, token);
  }
  
  /// Get refresh token
  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }
  
  /// Save user ID
  Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
  }
  
  /// Get user ID
  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }
  
  /// Save all auth data
  Future<void> saveAuthData({
    required String accessToken,
    String? refreshToken,
    String? userId,
  }) async {
    debugPrint('💾 Saving all auth data...');
    await saveAccessToken(accessToken);
    if (refreshToken != null) {
      await saveRefreshToken(refreshToken);
    }
    if (userId != null) {
      await saveUserId(userId);
    }
    debugPrint('✅ Auth data saved successfully');
  }
  
  /// Clear all stored data
  Future<void> clearAll() async {
    debugPrint('🗑️ Clearing all auth data...');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userIdKey);
    
    // Also clear secure storage
    try {
      await _secureStorage.deleteAll();
    } catch (e) {
      debugPrint('⚠️ Secure storage clear failed: $e');
    }
    debugPrint('✅ Auth data cleared');
  }
  
  /// Check if user is logged in (has access token)
  Future<bool> hasAccessToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}

