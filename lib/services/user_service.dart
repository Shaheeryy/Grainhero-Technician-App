import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class UserService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get current user profile
  Future<UserModel> getMyProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    try {
      // No FK relationship exists between profiles/user_roles, so these
      // can't be a single embedded select — run in parallel instead.
      final results = await Future.wait([
        _supabase.from('profiles').select().eq('id', user.id).single(),
        _supabase.from('user_roles').select('role').eq('user_id', user.id).maybeSingle(),
      ]);
      final profileData = results[0]!;
      final roleData = results[1];

      profileData['role'] = roleData?['role'] ?? 'technician';
      profileData['id'] = user.id;

      return UserModel.fromJson(profileData);
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      throw Exception('Failed to load profile');
    }
  }

  /// Update user profile
  Future<UserModel> updateProfile({
    String? name,
    String? phone,
    String? avatar,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    // Map to Supabase column names
    if (name != null) updates['name'] = name;
    if (phone != null) updates['phone'] = phone;
    if (avatar != null) updates['avatar'] = avatar;

    try {
      await _supabase.from('profiles').update(updates).eq('id', user.id);
      return getMyProfile();
    } catch (e) {
      debugPrint('Error updating profile: $e');
      throw Exception('Failed to update profile');
    }
  }

  /// Upload Profile Image
  Future<String> uploadProfileImage(File imageFile) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    try {
      final fileExt = imageFile.path.split('.').last;
      final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      
      // Upload to 'avatars' bucket
      await _supabase.storage.from('avatars').upload(
            fileName,
            imageFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );
          
      final imageUrl = _supabase.storage.from('avatars').getPublicUrl(fileName);
      return imageUrl;
    } catch (e) {
      debugPrint('❌ Upload Failed: $e');
      throw Exception('Failed to upload image. Avatar bucket might not be configured yet.');
    }
  }
}
