import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
                resetOnError: true,
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  static const _tokenKey = 'auth_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _storageTimeout = Duration(seconds: 3);

  final FlutterSecureStorage _storage;

  Future<void> saveTokens({
    required String token,
    String? refreshToken,
  }) async {
    try {
      await _storage
          .write(key: _tokenKey, value: token)
          .timeout(_storageTimeout);
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _storage
            .write(key: _refreshTokenKey, value: refreshToken)
            .timeout(_storageTimeout);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SecureStorage saveTokens failed: $e');
      }
      await _safeDeleteAll();
      rethrow;
    }
  }

  Future<String?> getToken() async {
    try {
      return await _storage.read(key: _tokenKey).timeout(_storageTimeout);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SecureStorage getToken failed: $e');
      }
      await _safeDeleteAll();
      return null;
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      return await _storage
          .read(key: _refreshTokenKey)
          .timeout(_storageTimeout);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SecureStorage getRefreshToken failed: $e');
      }
      return null;
    }
  }

  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> clearTokens() async {
    try {
      await _storage.delete(key: _tokenKey).timeout(_storageTimeout);
      await _storage.delete(key: _refreshTokenKey).timeout(_storageTimeout);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SecureStorage clearTokens failed: $e');
      }
      await _safeDeleteAll();
    }
  }

  Future<void> _safeDeleteAll() async {
    try {
      await _storage.deleteAll().timeout(_storageTimeout);
    } catch (_) {}
  }
}
