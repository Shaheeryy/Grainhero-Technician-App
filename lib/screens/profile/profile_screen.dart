import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import '../../config/app_theme.dart';
import '../auth/login_screen.dart';
import 'change_password_screen.dart';
import 'about_app_screen.dart';
import '../logs/activity_logs_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _userService = UserService();
  final _imagePicker = ImagePicker();
  UserModel? _userProfile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = await _userService.getMyProfile();
      if (!mounted) return;
      setState(() {
        _userProfile = user;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() {
        _loading = true; // Show loading while uploading
      });
      
      final file = File(image.path);
      
      // 1. Upload Image
      final imageUrl = await _userService.uploadProfileImage(file);
      
      if (imageUrl.isNotEmpty) {
        // 2. Update Profile with new Avatar URL
        // Note: The backend's PATCH /auth/me should handle this.
        final updatedUser = await _userService.updateProfile(avatar: imageUrl);
        
        setState(() {
          _userProfile = updatedUser;
          _loading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated successfully'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } else {
         throw Exception('No image URL returned from upload');
      }

    } catch (e) {
      setState(() {
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile picture: $e')),
        );
      }
    }
  }

  void _showEditProfileSheet(BuildContext context, UserModel? currentUser) {
    // Ensure we have values or empty strings
    final nameController = TextEditingController(text: currentUser?.name ?? '');
    final phoneController = TextEditingController(text: currentUser?.phone ?? '');
    
    bool isSaving = false;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return Container(
              decoration: const BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Edit Profile',
                      style: TextStyle(
                        fontSize: 20, 
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: phoneController,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                setStateSheet(() {
                                  isSaving = true;
                                });
                                try {
                                  final updatedUser = await _userService
                                      .updateProfile(
                                        name: nameController.text.trim(),
                                        phone: phoneController.text.trim(),
                                      );
                                  if (mounted) {
                                    setState(() {
                                      _userProfile = updatedUser;
                                    });
                                  }
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Profile updated'),
                                        backgroundColor: AppTheme.successColor,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed:  ${e.toString()}'),
                                        backgroundColor: AppTheme.errorColor,
                                      ),
                                    );
                                  }
                                } finally {
                                  setStateSheet(() {
                                    isSaving = false;
                                  });
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Save Changes',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final authService = Provider.of<AuthService>(
                context,
                listen: false,
              );
              await authService.logout();

              if (!context.mounted) return;

              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : Consumer<AuthService>(
              builder: (context, authService, _) {
                // Prioritize local profile fetch, fall back to auth service user
                final user = _userProfile ?? authService.user;

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildHeader(user),
                      const SizedBox(height: AppTheme.spacingXL),
                      
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Account Info',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacingM),
                            _buildInfoCard(
                              context,
                              'Assigned Sites',
                              '${user?.assignedSites.length ?? 0} sites',
                              Icons.warehouse_outlined,
                            ),
                            const SizedBox(height: AppTheme.spacingS),
                            _buildInfoCard(
                              context,
                              'Role',
                              (user?.role.toUpperCase() ?? 'TECHNICIAN'),
                              Icons.badge_outlined,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppTheme.spacingXL),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Settings',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacingM),
                            _buildSettingsTile(
                              icon: Icons.edit_outlined,
                              title: 'Edit Profile',
                              onTap: () => _showEditProfileSheet(context, user),
                            ),
                            const SizedBox(height: AppTheme.spacingS),
                            _buildSettingsTile(
                              icon: Icons.lock_outline,
                              title: 'Change Password',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                                );
                              },
                            ),
                            const SizedBox(height: AppTheme.spacingS),
                            _buildSettingsTile(
                              icon: Icons.info_outline,
                              title: 'About App',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const AboutAppScreen()),
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacingS),
                            _buildSettingsTile(
                              icon: Icons.history,
                              title: 'Activity Logs',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const ActivityLogsScreen()),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppTheme.spacingXL),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
                        child: _buildSettingsTile(
                          icon: Icons.logout,
                          title: 'Logout',
                          textColor: AppTheme.errorColor,
                          iconColor: AppTheme.errorColor,
                          onTap: () => _showLogoutDialog(context),
                        ),
                      ),

                      const SizedBox(height: 100),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildHeader(UserModel? user) {
    return Container(
      width: double.infinity,
      color: AppTheme.surfaceColor,
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _pickImage,
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2), width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                    backgroundImage: user?.avatar != null && user!.avatar!.isNotEmpty
                        ? NetworkImage(user.avatar!)
                        : null,
                    child: (user?.avatar == null || user!.avatar!.isEmpty)
                        ? Text(
                            (user?.name.isNotEmpty == true ? user!.name.substring(0, 1).toUpperCase() : 'T'),
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          )
                        : null,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            (user?.name != null && user!.name.isNotEmpty) ? user.name : 'Technician',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          if (user?.email != null)
            Text(
              user!.email,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          if (user?.phone != null) ...[
            const SizedBox(height: 4),
            Text(
              user!.phone,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
  ) {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return Container(
      decoration: AppTheme.cardDecoration,
      margin: const EdgeInsets.only(bottom: 0),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? AppTheme.textSecondary).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: iconColor ?? AppTheme.textSecondary,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: textColor ?? AppTheme.textPrimary,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: (textColor ?? AppTheme.textSecondary).withValues(alpha: 0.5),
          size: 20,
        ),
        onTap: onTap,
      ),
    );
  }
}
