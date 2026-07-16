// import 'package:flutter/material.dart';
// import 'package:grainhero_technician_app/config/auth_theme.dart';
// import 'package:grainhero_technician_app/config/app_animations.dart';

// class AnimatedPrimaryButton extends StatefulWidget {
//   final VoidCallback? onPressed;
//   final bool isLoading;
//   final Widget child;
  
//   const AnimatedPrimaryButton({
//     super.key,
//     required this.onPressed,
//     this.isLoading = false,
//     required this.child,
//   });

//   @override
//   State<AnimatedPrimaryButton> createState() => _AnimatedPrimaryButtonState();
// }

// class _AnimatedPrimaryButtonState extends State<AnimatedPrimaryButton> {
//   bool _isHovered = false;
//   bool _isPressed = false;

//   @override
//   Widget build(BuildContext context) {
//     final scale = _isPressed ? 0.98 : (_isHovered ? 1.02 : 1.0);

//     return MouseRegion(
//       onEnter: (_) => setState(() => _isHovered = true),
//       onExit: (_) => setState(() => _isHovered = false),
//       child: GestureDetector(
//         onTapDown: (_) => setState(() => _isPressed = true),
//         onTapUp: (_) => setState(() => _isPressed = false),
//         onTapCancel: () => setState(() => _isPressed = false),
//         child: AnimatedScale(
//           scale: scale,
//           duration: AppAnimations.fast,
//           curve: AppAnimations.curveDefault,
//           child: SizedBox(
//             height: 52,
//             child: ElevatedButton(
//               onPressed: widget.onPressed,
//               style: AuthTheme.primaryButtonStyle.copyWith(
//                 elevation: WidgetStateProperty.resolveWith((states) {
//                   if (states.contains(WidgetState.hovered)) return 6;
//                   if (states.contains(WidgetState.pressed)) return 2;
//                   return 0;
//                 }),
//               ),
//               child: AnimatedSwitcher(
//                 duration: AppAnimations.fast,
//                 child: widget.isLoading
//                     ? const SizedBox(
//                         key: ValueKey('loading'),
//                         height: 22,
//                         width: 22,
//                         child: CircularProgressIndicator(
//                           strokeWidth: 2.5,
//                           valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                         ),
//                       )
//                     : Container(
//                         key: const ValueKey('content'),
//                         child: DefaultTextStyle(
//                           style: const TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                             letterSpacing: 0.5,
//                           ),
//                           child: widget.child,
//                         ),
//                       ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
