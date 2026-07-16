// import 'package:flutter/material.dart';
// import 'package:grainhero_technician_app/config/auth_theme.dart';
// import 'package:grainhero_technician_app/config/app_animations.dart';

// class AnimatedAuthCard extends StatefulWidget {
//   final Widget child;

//   const AnimatedAuthCard({super.key, required this.child});

//   @override
//   State<AnimatedAuthCard> createState() => _AnimatedAuthCardState();
// }

// class _AnimatedAuthCardState extends State<AnimatedAuthCard> with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _fadeAnimation;
//   late Animation<Offset> _slideAnimation;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       vsync: this,
//       duration: AppAnimations.slow,
//     );

//     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(
//         parent: _controller,
//         curve: const Interval(0.0, 1.0, curve: AppAnimations.curveEntrance),
//       ),
//     );

//     _slideAnimation = Tween<Offset>(
//       begin: const Offset(0.0, 0.1),
//       end: Offset.zero,
//     ).animate(
//       CurvedAnimation(
//         parent: _controller,
//         curve: const Interval(0.0, 1.0, curve: AppAnimations.curveEntrance),
//       ),
//     );

//     _controller.forward();
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SlideTransition(
//       position: _slideAnimation,
//       child: FadeTransition(
//         opacity: _fadeAnimation,
//         child: Container(
//           width: double.infinity,
//           decoration: const BoxDecoration(
//             color: AuthTheme.beigeBackground,
//             borderRadius: BorderRadius.only(
//               topLeft: Radius.circular(40),
//               topRight: Radius.circular(40),
//             ),
//           ),
//           child: widget.child,
//         ),
//       ),
//     );
//   }
// }
