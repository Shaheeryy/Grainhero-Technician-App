import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import '../../config/grainhero_colors.dart';
import '../../widgets/common/app_toast.dart';
import '../auth/login_screen.dart';
import 'about_app_screen.dart';
import 'edit_profile_modal.dart';
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
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (image == null) return;

      setState(() {
        _loading = true; // Show loading while uploading
      });

      final file = File(image.path);

      // 1. Upload Image
      final imageUrl = await _userService.uploadProfileImage(file);

      if (imageUrl.isNotEmpty) {
        // 2. Update Profile with new Avatar URL
        final updatedUser = await _userService.updateProfile(avatar: imageUrl);

        setState(() {
          _userProfile = updatedUser;
          _loading = false;
        });

        if (mounted) {
          // Refresh the shared AuthService user so other screens (e.g. the
          // dashboard header) pick up the new avatar immediately.
          await Provider.of<AuthService>(context, listen: false).refreshUser();
        }

        if (mounted) {
          AppToast.show(context, 'Profile picture updated successfully');
        }
      } else {
        throw Exception('No image URL returned from upload');
      }
    } catch (e) {
      setState(() {
        _loading = false;
      });
      if (mounted) {
        AppToast.show(context, 'Failed to update profile picture: $e', isError: true);
      }
    }
  }

  Future<void> _showEditProfileSheet(BuildContext context, UserModel? currentUser) async {
    final result = await showEditProfileModal(
      context: context,
      initialName: currentUser?.name ?? '',
      initialEmail: currentUser?.email ?? '',
    );

    if (result == null || !mounted) return;

    setState(() {
      _loading = true;
    });

    try {
      final updatedUser = await _userService.updateProfile(
        name: result.name,
      );
      if (mounted && context.mounted) {
        setState(() {
          _userProfile = updatedUser;
          _loading = false;
        });
        await Provider.of<AuthService>(context, listen: false).refreshUser();
        if (mounted && context.mounted) {
          AppToast.show(context, 'Profile updated successfully');
        }
      }
    } catch (e) {
      if (mounted && context.mounted) {
        setState(() {
          _loading = false;
        });
        AppToast.show(context, 'Failed: ${e.toString()}', isError: true);
      }
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: GrainHeroColors.surface,
          surfaceTintColor: Colors.transparent,
          icon: const SizedBox(
            width: 48,
            height: 48,
            child: Icon(
              Icons.logout_rounded,
              color: GrainHeroColors.error,
              size: 32,
            ),
          ),
          iconPadding: const EdgeInsets.fromLTRB(24, 20, 24, 6),
          title: const Text(
            'Logout?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: GrainHeroColors.bodyText,
              fontWeight: FontWeight.bold,
            ),
          ),
          titlePadding: const EdgeInsets.symmetric(horizontal: 24),
          content: const Text(
            'Are you sure you want to logout from GrainHero?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: GrainHeroColors.bodyText,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: GrainHeroColors.primaryDark),
              ),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

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
              style: FilledButton.styleFrom(
                backgroundColor: GrainHeroColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  void _goBack() {
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GrainHeroColors.pageBackground,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: GrainHeroColors.primary),
            )
          : Consumer<AuthService>(
              builder: (context, authService, _) {
                // Prioritize local profile fetch, fall back to auth service user
                final user = _userProfile ?? authService.user;

                return ListView(
                  padding: EdgeInsets.zero,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // =====================================================
                    // Profile Header Section
                    // Displays header background, back button, title, avatar, user details
                    // =====================================================
                    _ProfileHeader(
                      user: user,
                      onBackPressed: _goBack,
                      onEditPicturePressed: _pickImage,
                    ),

                    const SizedBox(height: 20),

                    // =====================================================
                    // Account Summary Card
                    // Displays Assigned Sites and User Role
                    // =====================================================
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _AccountSummaryCard(user: user),
                    ),

                    const SizedBox(height: 32),

                    // =====================================================
                    // Settings Section
                    // Menu list containing options like Edit Profile, Change Password, etc.
                    // =====================================================
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _SettingsSection(
                        onEditProfilePressed: () => _showEditProfileSheet(context, user),
                        onAboutAppPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AboutAppScreen()),
                          );
                        },
                        onActivityLogsPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ActivityLogsScreen()),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 30),

                    // =====================================================
                    // Logout Action Button
                    // Prompts confirmation dialog to logout user
                    // =====================================================
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _LogoutButton(
                        onPressed: () => _showLogoutDialog(context),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                );
              },
            ),
    );
  }
}

// ============================================================
// PROFILE HEADER WIDGET
// ============================================================

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.user,
    required this.onBackPressed,
    required this.onEditPicturePressed,
  });

  final UserModel? user;
  final VoidCallback onBackPressed;
  final VoidCallback onEditPicturePressed;

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.paddingOf(context).top;

    final String name = (user?.name != null && user!.name.isNotEmpty)
        ? user!.name
        : 'Technician';
    final String email = user?.email ?? '';
    final String phone = user?.phone ?? '';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, statusBarHeight + 8, 16, 22),
      decoration: BoxDecoration(
        color: GrainHeroColors.dark,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(42),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Navigation Row
          Row(
            children: [
              IconButton(
                onPressed: onBackPressed,
                tooltip: 'Back',
                style: IconButton.styleFrom(
                  fixedSize: const Size(44, 44),
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  shape: const CircleBorder(),
                ),
                icon: const Icon(Icons.arrow_back_rounded, size: 23),
              ),

              const Expanded(
                child: Text(
                  'Profile',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                ),
              ),

              const SizedBox(width: 44, height: 44),
            ],
          ),

          const SizedBox(height: 12),

          // Avatar Image & Edit Trigger
          _ProfileAvatar(
            avatarUrl: user?.avatar,
            name: name,
            onEditPressed: onEditPicturePressed,
          ),

          const SizedBox(height: 12),

          // User Name
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              height: 1.25,
              fontWeight: FontWeight.w700,
            ),
          ),

          if (email.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              email,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],

          if (phone.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              phone,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.58),
                fontSize: 11,
                height: 1.4,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// PROFILE AVATAR WIDGET
// ============================================================

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.avatarUrl,
    required this.name,
    required this.onEditPressed,
  });

  final String? avatarUrl;
  final String name;
  final VoidCallback onEditPressed;

  @override
  Widget build(BuildContext context) {
    final bool hasAvatar = avatarUrl != null && avatarUrl!.isNotEmpty;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 92,
          height: 92,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: GrainHeroColors.dark,
            border: Border.all(color: GrainHeroColors.primary, width: 4),
            boxShadow: [
              BoxShadow(
                color: GrainHeroColors.primary.withValues(alpha: 0.28),
                spreadRadius: 2,
                blurRadius: 14,
              ),
            ],
          ),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: GrainHeroColors.surfaceContainer,
            ),
            clipBehavior: Clip.antiAlias,
            child: hasAvatar
                ? Image.network(
                    avatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(),
                  )
                : _buildFallbackIcon(),
          ),
        ),

        Positioned(
          right: -2,
          bottom: 1,
          child: Material(
            color: GrainHeroColors.primary,
            shape: const CircleBorder(),
            elevation: 5,
            child: InkWell(
              onTap: onEditPressed,
              customBorder: const CircleBorder(),
              child: const SizedBox(
                width: 32,
                height: 32,
                child: Icon(
                  Icons.edit_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackIcon() {
    final String initial = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'T';
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: GrainHeroColors.primary,
        ),
      ),
    );
  }
}

// ============================================================
// ACCOUNT SUMMARY CARD WIDGET
// ============================================================

class _AccountSummaryCard extends StatelessWidget {
  const _AccountSummaryCard({required this.user});

  final UserModel? user;

  @override
  Widget build(BuildContext context) {
    final int sitesCount = user?.assignedSites.length ?? 0;
    final String role = user?.role.toUpperCase() ?? 'TECHNICIAN';

    return Material(
      color: GrainHeroColors.surface,
      elevation: 2,
      shadowColor: GrainHeroColors.primary.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(40),
        side: BorderSide(color: GrainHeroColors.bodyText.withValues(alpha: 0.12)),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _AccountSummaryItem(
                icon: Icons.domain_rounded,
                label: 'ASSIGNED SITES',
                value: '$sitesCount sites',
              ),
            ),

            VerticalDivider(
              width: 1,
              thickness: 1,
              color: GrainHeroColors.bodyText.withValues(alpha: 0.15),
            ),

            Expanded(
              child: _AccountSummaryItem(
                icon: Icons.badge_outlined,
                label: 'ROLE',
                value: role,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountSummaryItem extends StatelessWidget {
  const _AccountSummaryItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      child: Column(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, color: GrainHeroColors.primaryDark, size: 22),
          ),

          const SizedBox(height: 10),

          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: GrainHeroColors.bodyText.withValues(alpha: 0.6),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),

          const SizedBox(height: 4),

          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: GrainHeroColors.bodyText,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SETTINGS SECTION WIDGET
// ============================================================

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.onEditProfilePressed,
    required this.onAboutAppPressed,
    required this.onActivityLogsPressed,
  });

  final VoidCallback onEditProfilePressed;
  final VoidCallback onAboutAppPressed;
  final VoidCallback onActivityLogsPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Text(
            'Settings',
            style: TextStyle(
              color: GrainHeroColors.dark,
              fontSize: 22,
              height: 1.3,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
        ),

        const SizedBox(height: 14),

        Card(
          margin: EdgeInsets.zero,
          color: GrainHeroColors.surface,
          elevation: 2,
          shadowColor: GrainHeroColors.primary.withValues(alpha: 0.10),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
            side: BorderSide(color: GrainHeroColors.bodyText.withValues(alpha: 0.12)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _SettingsItem(
                icon: Icons.manage_accounts_outlined,
                title: 'Edit Profile',
                onPressed: onEditProfilePressed,
              ),

              const _SettingsDivider(),

              _SettingsItem(
                icon: Icons.info_outline_rounded,
                title: 'About App',
                onPressed: onAboutAppPressed,
              ),

              const _SettingsDivider(),

              _SettingsItem(
                icon: Icons.history_rounded,
                title: 'Activity Logs',
                onPressed: onActivityLogsPressed,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: Icon(icon, color: GrainHeroColors.primaryDark, size: 22),
            ),

            const SizedBox(width: 15),

            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: GrainHeroColors.bodyText,
                  fontSize: 16,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            Icon(
              Icons.chevron_right_rounded,
              color: GrainHeroColors.bodyText.withValues(alpha: 0.4),
              size: 21,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: GrainHeroColors.bodyText.withValues(alpha: 0.12),
    );
  }
}

// ============================================================
// LOGOUT BUTTON WIDGET
// ============================================================

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: GrainHeroColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: GrainHeroColors.bodyText.withValues(alpha: 0.12)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
          child: Row(
            children: [
              const SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  Icons.logout_rounded,
                  color: GrainHeroColors.error,
                  size: 22,
                ),
              ),

              const SizedBox(width: 14),

              const Expanded(
                child: Text(
                  'Logout',
                  style: TextStyle(
                    color: GrainHeroColors.bodyText,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              Icon(
                Icons.chevron_right_rounded,
                color: GrainHeroColors.bodyText.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

