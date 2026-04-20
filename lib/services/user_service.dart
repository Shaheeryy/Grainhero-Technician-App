import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user_model.dart';
import '../utils/secure_storage.dart';

class UserService {
  /// Get current user profile
  Future<UserModel> getMyProfile() async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse(ApiConfig.technicianProfile),
      headers: ApiConfig.getHeaders(token: token),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      debugPrint('👤 User Profile Data: $data'); // Debug log to check structure
      // Handle if the user object is nested under 'user' key
      final userJson = data['user'] ?? data;
      return UserModel.fromJson(userJson);
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized');
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to load profile');
    }
  }

  /// Update user profile
  Future<UserModel> updateProfile({
    String? name,
    String? phone,
    String? avatar,
  }) async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception('Not authenticated');

    final userData = await SecureStorage.getUserData();
    final userId = userData['userId'];
    if (userId == null) throw Exception('User ID not found');

    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (phone != null) body['phone'] = phone;
    if (avatar != null) body['avatar'] = avatar;

    debugPrint('📤 Updating Profile: $body');
    final response = await http.patch(
      Uri.parse(ApiConfig.updateProfileSelf),
      headers: ApiConfig.getHeaders(token: token),
      body: jsonEncode(body),
    );
    
    debugPrint('📥 Update Profile Response: ${response.statusCode}');
    debugPrint('📜 Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return UserModel.fromJson(data['user'] ?? data);
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized');
    } else if (response.statusCode == 403) {
      throw Exception('Cannot update other users');
    } else if (response.statusCode == 404) {
      throw Exception('User not found');
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to update profile');
    }
  }

  /// Change Password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception('Not authenticated');

    // Backend endpoint: PATCH /auth/change-password
    final response = await http.patch(
      Uri.parse(ApiConfig.changePassword),
      headers: ApiConfig.getHeaders(token: token),
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );

    debugPrint('📤 Change Password: ${response.statusCode}');
    debugPrint('📜 Response Body: ${response.body}');

    if (response.statusCode == 200) {
      return true;
    } else {
      // Check if backend returned HTML (endpoint not found on server)
      final contentType = response.headers['content-type'] ?? '';
      if (contentType.contains('text/html') ||
          response.body.trim().startsWith('<!DOCTYPE') ||
          response.body.trim().startsWith('<html')) {
        debugPrint('❌ Change Password endpoint returned HTML - route may not be deployed');
        throw Exception('Change password service unavailable. Please ensure the backend is updated.');
      }
      try {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? data['error'] ?? 'Failed to change password');
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Failed to change password');
      }
    }
  }

  /// Upload Profile Image
  Future<String> uploadProfileImage(File imageFile) async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse(ApiConfig.uploadProfilePic);
    final request = http.MultipartRequest('POST', uri);

    request.headers.addAll(ApiConfig.getHeaders(token: token));
    
    // Add file
    final stream = http.ByteStream(imageFile.openRead());
    final length = await imageFile.length();
    
    final multipartFile = http.MultipartFile(
      'avatar', // Field name expected by Multer (trying 'avatar')
      stream,
      length,
      filename: imageFile.path.split('/').last,
    );

    request.files.add(multipartFile);

    debugPrint('📤 Uploading Image to: $uri');
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      debugPrint('📸 Upload Response: ${response.body}');
      // Backend returns { "avatar": "..." }
      return data['avatar'] ?? data['imageUrl'] ?? data['url'] ?? data['file'] ?? ''; 
    } else {
      debugPrint('❌ Upload Failed: ${response.statusCode}');
      debugPrint('📜 Response Body: ${response.body}');
      throw Exception('Failed to upload image');
    }
  }
}
