import 'package:flutter/material.dart';

class AppAnimations {
  // Durations
  static const fast = Duration(milliseconds: 150);
  static const medium = Duration(milliseconds: 300);
  static const slow = Duration(milliseconds: 500);
  static const transition = Duration(milliseconds: 250);
  
  // Curves
  static const curveDefault = Curves.easeInOut;
  static const curveEntrance = Curves.easeOutCubic;
}
