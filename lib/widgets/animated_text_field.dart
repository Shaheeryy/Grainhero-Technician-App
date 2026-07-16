// import 'package:flutter/material.dart';
// import 'package:grainhero_technician_app/config/auth_theme.dart';
// import 'package:grainhero_technician_app/config/app_animations.dart';

// class AnimatedTextField extends StatefulWidget {
//   final TextEditingController controller;
//   final IconData prefixIcon;
//   final String hintText;
//   final bool obscureText;
//   final Widget? suffixIcon;
//   final TextInputType? keyboardType;
//   final String? Function(String?)? validator;
//   final void Function(String)? onSubmitted;
//   final bool readOnly;

//   const AnimatedTextField({
//     super.key,
//     required this.controller,
//     required this.prefixIcon,
//     required this.hintText,
//     this.obscureText = false,
//     this.suffixIcon,
//     this.keyboardType,
//     this.validator,
//     this.onSubmitted,
//     this.readOnly = false,
//   });

//   @override
//   State<AnimatedTextField> createState() => _AnimatedTextFieldState();
// }

// class _AnimatedTextFieldState extends State<AnimatedTextField> {
//   bool _isHovered = false;
//   final FocusNode _focusNode = FocusNode();
//   bool _isFocused = false;

//   @override
//   void initState() {
//     super.initState();
//     _focusNode.addListener(() {
//       setState(() {
//         _isFocused = _focusNode.hasFocus;
//       });
//     });
//   }

//   @override
//   void dispose() {
//     _focusNode.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MouseRegion(
//       onEnter: (_) => setState(() => _isHovered = true),
//       onExit: (_) => setState(() => _isHovered = false),
//       child: AnimatedContainer(
//         duration: AppAnimations.fast,
//         curve: AppAnimations.curveDefault,
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(28),
//           boxShadow: [
//             if (_isFocused)
//               BoxShadow(
//                 color: AuthTheme.primaryGreen.withValues(alpha: 0.15),
//                 blurRadius: 10,
//                 offset: const Offset(0, 4),
//               ),
//           ],
//         ),
//         child: TextFormField(
//           controller: widget.controller,
//           focusNode: _focusNode,
//           obscureText: widget.obscureText,
//           keyboardType: widget.keyboardType,
//           validator: widget.validator,
//           readOnly: widget.readOnly,
//           onFieldSubmitted: widget.onSubmitted,
//           textInputAction: widget.onSubmitted != null ? TextInputAction.done : TextInputAction.next,
//           style: const TextStyle(
//             fontSize: 15,
//             color: AuthTheme.textPrimary,
//           ),
//           decoration: AuthTheme.getInputDecoration(
//             hintText: widget.hintText,
//             prefixIcon: widget.prefixIcon,
//             suffixIcon: widget.suffixIcon,
//           ),
//           ),
//         ),
//       );
    
//   }
// }
