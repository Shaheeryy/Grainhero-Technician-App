import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();

  static const _keyToken = 'jwt_token';
  static const _keyUserId = 'user_id';
  static const _keyUserName = 'user_name';
  static const _keyUserPhone = 'user_phone';

  // Save JWT token
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  // Get JWT token
  static Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  // Purge legacy token
  static Future<void> purgeLegacyToken() async {
    final hasToken = await _storage.containsKey(key: _keyToken);
    if (hasToken) {
      await clearAll();
    }
  }

  // Save user data
  static Future<void> saveUserData({
    required String userId,
    required String userName,
    required String userPhone,
  }) async {
    await _storage.write(key: _keyUserId, value: userId);
    await _storage.write(key: _keyUserName, value: userName);
    await _storage.write(key: _keyUserPhone, value: userPhone);
  }

  // Get user data
  static Future<Map<String, String?>> getUserData() async {
    final userId = await _storage.read(key: _keyUserId);
    final userName = await _storage.read(key: _keyUserName);
    final userPhone = await _storage.read(key: _keyUserPhone);

    return {'userId': userId, 'userName': userName, 'userPhone': userPhone};
  }

  // Clear all data (logout)
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  // Check if authenticated
  static Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
