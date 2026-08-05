import 'dart:ui';
import 'package:flutter/material.dart';
import '../../config/auth_theme.dart';

/// Shows the redesigned Edit Profile dialog modal.
/// Preserves contract and return types of [EditProfileResult].
Future<EditProfileResult?> showEditProfileModal({
  required BuildContext context,
  required String initialName,
  required String initialEmail,
}) {
  return showGeneralDialog<EditProfileResult>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Dismiss edit profile',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 340),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return EditProfileModal(
        initialName: initialName,
        initialEmail: initialEmail,
        routeAnimation: animation,
      );
    },
    transitionBuilder: (dialogContext, animation, secondaryAnimation, child) =>
        child,
  );
}

/// Result model holding updated profile data.
class EditProfileResult {
  const EditProfileResult({required this.name, required this.email});

  final String name;
  final String email;
}

/// Dynamic, glassmorphism modal dialog widget for editing user profile information.
class EditProfileModal extends StatefulWidget {
  const EditProfileModal({
    super.key,
    required this.initialName,
    required this.initialEmail,
    required this.routeAnimation,
  });

  final String initialName;
  final String initialEmail;
  final Animation<double> routeAnimation;

  @override
  State<EditProfileModal> createState() => _EditProfileModalState();
}

class _EditProfileModalState extends State<EditProfileModal> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  bool _nameTouched = false;
  bool _emailTouched = false;
  bool _dismissPromptOpen = false;

  bool get _hasChanges =>
      _nameController.text.trim() != widget.initialName.trim() ||
      _emailController.text.trim() != widget.initialEmail.trim();

  String? get _nameError {
    final String name = _nameController.text.trim();
    if (name.isEmpty) return 'Enter your full name.';
    if (name.length < 2) return 'Name must contain at least 2 characters.';
    return null;
  }

  String? get _emailError {
    final String email = _emailController.text.trim();
    if (email.isEmpty) return 'Enter your email address.';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  bool get _isValid => _nameError == null && _emailError == null;
  bool get _canSave => _hasChanges && _isValid;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  void _handleNameChanged(String value) {
    setState(() => _nameTouched = true);
  }

  void _handleEmailChanged(String value) {
    setState(() => _emailTouched = true);
  }

  void _saveChanges() {
    setState(() {
      _nameTouched = true;
      _emailTouched = true;
    });
    if (!_canSave) return;

    _popModal(
      EditProfileResult(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
      ),
    );
  }

  Future<void> _requestDismiss() async {
    if (!_hasChanges) {
      Navigator.of(context).pop();
      return;
    }
    if (_dismissPromptOpen) return;
    _dismissPromptOpen = true;

    final bool discard =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AuthTheme.surface,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
            ),
            icon: const Icon(
              Icons.warning_amber_rounded,
              size: 38,
              color: Color(0xFF9A4A14),
            ),
            iconPadding: const EdgeInsets.fromLTRB(24, 28, 24, 10),
            title: const Text(
              'Discard changes?',
              style: TextStyle(
                fontFamily: 'Lexend',
                color: AuthTheme.textSecondary,
                fontSize: 21,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: const Text(
              'Your profile changes have not been saved.',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                color: AuthTheme.textPrimary,
                fontSize: 14,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  foregroundColor: AuthTheme.primaryDark,
                ),
                child: const Text('Keep editing'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: AuthTheme.error,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Discard'),
              ),
            ],
          ),
        ) ??
        false;

    if (!mounted) return;
    _dismissPromptOpen = false;
    if (discard) _popModal();
  }

  void _popModal([EditProfileResult? result]) {
    Navigator.of(context).pop(result);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    // Background blur backdrop tapping to dismiss modal safely
    final Widget backdrop = GestureDetector(
      key: const ValueKey('edit-profile-backdrop'),
      behavior: HitTestBehavior.opaque,
      onTap: _requestDismiss,
      child: RepaintBoundary(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: ColoredBox(color: Colors.black.withValues(alpha: 0.26)),
        ),
      ),
    );

    return AnimatedBuilder(
      animation: widget.routeAnimation,
      child: backdrop,
      builder: (context, child) {
        final Curve transitionCurve =
            widget.routeAnimation.status == AnimationStatus.reverse
                ? Curves.easeInCubic
                : Curves.easeOutCubic;
        final double progress = transitionCurve.transform(
          widget.routeAnimation.value,
        );

        return Material(
          color: Colors.transparent,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Opacity(opacity: progress, child: child),
              Opacity(
                opacity: progress,
                child: Transform.translate(
                  offset: Offset(0, 18 * (1 - progress)),
                  child: Transform.scale(
                    scale: 0.96 + (0.04 * progress),
                    alignment: Alignment.center,
                    child: SafeArea(
                      child: AnimatedPadding(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        padding: EdgeInsets.fromLTRB(
                          20,
                          20,
                          20,
                          keyboardInset + 20,
                        ),
                        child: Center(
                          child: SingleChildScrollView(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 520),
                              child: Material(
                                color: AuthTheme.surface,
                                surfaceTintColor: Colors.transparent,
                                elevation: 12,
                                shadowColor: Colors.black.withValues(alpha: 0.22),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(36),
                                  side: const BorderSide(
                                    color: AuthTheme.borderLight,
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    28,
                                    26,
                                    26,
                                    28,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // =====================================================
                                      // Header Section
                                      // Displays icon, title, and descriptive subtitle
                                      // =====================================================
                                      _EditProfileHeader(),
                                      const SizedBox(height: 24),

                                      // =====================================================
                                      // Form Fields Section
                                      // Full Name and Email Input Fields
                                      // =====================================================
                                      const Text(
                                        'Full name',
                                        style: TextStyle(
                                          fontFamily: 'Lexend',
                                          color: AuthTheme.textPrimary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextField(
                                        key: const ValueKey(
                                          'edit-profile-name-field',
                                        ),
                                        controller: _nameController,
                                        onChanged: _handleNameChanged,
                                        style: const TextStyle(
                                          fontFamily: 'Plus Jakarta Sans',
                                          color: AuthTheme.textPrimary,
                                          fontSize: 16,
                                          height: 1.25,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        textCapitalization:
                                            TextCapitalization.words,
                                        textInputAction: TextInputAction.next,
                                        autofillHints: const [
                                          AutofillHints.name,
                                        ],
                                        decoration: _fieldDecoration(
                                          hint: 'Enter your full name',
                                          icon: Icons.person_outline_rounded,
                                          errorText:
                                              _nameTouched ? _nameError : null,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Email address',
                                        style: TextStyle(
                                          fontFamily: 'Lexend',
                                          color: AuthTheme.textPrimary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextField(
                                        key: const ValueKey(
                                          'edit-profile-email-field',
                                        ),
                                        controller: _emailController,
                                        onChanged: _handleEmailChanged,
                                        style: const TextStyle(
                                          fontFamily: 'Plus Jakarta Sans',
                                          color: AuthTheme.textPrimary,
                                          fontSize: 16,
                                          height: 1.25,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        textInputAction: TextInputAction.done,
                                        autofillHints: const [
                                          AutofillHints.email,
                                        ],
                                        onSubmitted: (_) => _saveChanges(),
                                        decoration: _fieldDecoration(
                                          hint: 'Enter your email address',
                                          icon: Icons.alternate_email_rounded,
                                          errorText:
                                              _emailTouched ? _emailError : null,
                                        ),
                                      ),
                                      const SizedBox(height: 14),

                                      // Dynamic status helper message
                                      AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 180,
                                        ),
                                        child: Text(
                                          _canSave
                                              ? 'Your changes are ready to save.'
                                              : _hasChanges
                                                  ? 'Correct the highlighted field to continue.'
                                                  : 'Change either field to Save changes.',
                                          key: ValueKey(
                                            '$_hasChanges-$_isValid',
                                          ),
                                          style: TextStyle(
                                            fontFamily: 'Plus Jakarta Sans',
                                            color: _canSave
                                                ? AuthTheme.primaryDark
                                                : AuthTheme.textHint,
                                            fontSize: 12,
                                            height: 1.35,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 24),

                                      // =====================================================
                                      // Action Buttons Section
                                      // Return / Cancel and Save Action Buttons
                                      // =====================================================
                                      LayoutBuilder(
                                        builder: (context, constraints) {
                                          final Widget returnButton =
                                              _buildReturnButton();
                                          final Widget saveButton =
                                              _buildSaveButton();

                                          if (constraints.maxWidth < 300) {
                                            return Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                saveButton,
                                                const SizedBox(height: 10),
                                                returnButton,
                                              ],
                                            );
                                          }

                                          return Row(
                                            children: [
                                              Expanded(child: returnButton),
                                              const SizedBox(width: 12),
                                              Expanded(child: saveButton),
                                            ],
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReturnButton() {
    return OutlinedButton.icon(
      key: const ValueKey('edit-profile-return-button'),
      onPressed: _requestDismiss,
      style: OutlinedButton.styleFrom(
        foregroundColor: AuthTheme.textPrimary,
        minimumSize: const Size.fromHeight(54),
        padding: const EdgeInsets.only(left: 6, right: 14),
        side: const BorderSide(color: AuthTheme.borderLight),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      icon: const Icon(
        Icons.arrow_back_rounded,
        color: AuthTheme.primaryDark,
        size: 19,
      ),
      label: const Text('Return', maxLines: 1, softWrap: false),
    );
  }

  Widget _buildSaveButton() {
    return FilledButton.icon(
      key: const ValueKey('edit-profile-save-button'),
      onPressed: _canSave ? _saveChanges : null,
      style: FilledButton.styleFrom(
        backgroundColor: AuthTheme.primaryDark,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AuthTheme.borderLight.withValues(alpha: 0.4),
        disabledForegroundColor: AuthTheme.textHint,
        minimumSize: const Size.fromHeight(54),
        padding: const EdgeInsets.only(left: 6, right: 14),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
      icon: const Icon(Icons.check_rounded, size: 19),
      label: const Text('Save', maxLines: 1, softWrap: false),
    );
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    String? errorText,
  }) {
    final OutlineInputBorder border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(26),
      borderSide: const BorderSide(
        color: AuthTheme.borderLight,
      ),
    );

    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontFamily: 'Plus Jakarta Sans',
        color: AuthTheme.textHint,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Icon(icon, size: 22),
      prefixIconColor: AuthTheme.primaryDark,
      prefixIconConstraints: const BoxConstraints(minWidth: 54, minHeight: 58),
      filled: true,
      fillColor: AuthTheme.surfaceContainer,
      constraints: const BoxConstraints(minHeight: 58),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(
          color: AuthTheme.primaryGreen,
          width: 2,
        ),
      ),
      errorText: errorText,
      errorStyle: const TextStyle(
        fontFamily: 'Plus Jakarta Sans',
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
      ),
      errorBorder: border.copyWith(
        borderSide: const BorderSide(color: AuthTheme.error),
      ),
      focusedErrorBorder: border.copyWith(
        borderSide: const BorderSide(color: AuthTheme.error, width: 2),
      ),
    );
  }
}

/// Reusable Header Component for Edit Profile Modal
class _EditProfileHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AuthTheme.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.manage_accounts_rounded,
            color: AuthTheme.primaryDark,
            size: 27,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit profile',
                style: TextStyle(
                  fontFamily: 'Lexend',
                  color: AuthTheme.textSecondary,
                  fontSize: 24,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Update the details shown on your profile.',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  color: AuthTheme.textHint,
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
