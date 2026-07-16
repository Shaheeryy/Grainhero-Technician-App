// import 'package:flutter/material.dart';
// import 'package:grainhero_technician_app/config/app_animations.dart';

// class AnimatedStaggeredItem extends StatefulWidget {
//   final Widget child;
//   final int index;
  
//   const AnimatedStaggeredItem({
//     super.key,
//     required this.child,
//     required this.index,
//   });

//   @override
//   State<AnimatedStaggeredItem> createState() => _AnimatedStaggeredItemState();
// }

// class _AnimatedStaggeredItemState extends State<AnimatedStaggeredItem> with SingleTickerProviderStateMixin {
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
//         curve: AppAnimations.curveDefault,
//       ),
//     );

//     _slideAnimation = Tween<Offset>(
//       begin: const Offset(0.0, 0.2),
//       end: Offset.zero,
//     ).animate(
//       CurvedAnimation(
//         parent: _controller,
//         curve: AppAnimations.curveEntrance,
//       ),
//     );

//     Future.delayed(Duration(milliseconds: widget.index * 50), () {
//       if (mounted) {
//         _controller.forward();
//       }
//     });
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
//         child: widget.child,
//       ),
//     );
//   }
// }
