import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// A modern status badge widget with refined styling
/// Supports both status and severity modes with appropriate colors
class StatusBadge extends StatelessWidget {
  final String status;
  final String? label;
  final bool isSeverity;
  final bool isCompact;

  const StatusBadge({
    super.key,
    required this.status,
    this.label,
    this.isSeverity = false,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayLabel = label ?? status;
    final color = isSeverity 
        ? AppTheme.getSeverityColor(status)
        : AppTheme.getStatusColor(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 12,
        vertical: isCompact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(isCompact ? 6 : 8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isCompact ? 6 : 8,
            height: isCompact ? 6 : 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: isCompact ? 4 : 6),
          Text(
            isCompact ? displayLabel : displayLabel.toUpperCase(),
            style: TextStyle(
              fontSize: isCompact ? 10 : 11,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: isCompact ? 0 : 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Status dot indicator for minimal display
class StatusDot extends StatelessWidget {
  final String status;
  final double size;
  final bool isSeverity;
  final bool animated;

  const StatusDot({
    super.key,
    required this.status,
    this.size = 10,
    this.isSeverity = false,
    this.animated = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSeverity
        ? AppTheme.getSeverityColor(status)
        : AppTheme.getStatusColor(status);

    if (animated && (status.toLowerCase() == 'active' || status.toLowerCase() == 'running')) {
      return _AnimatedStatusDot(color: color, size: size);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

class _AnimatedStatusDot extends StatefulWidget {
  final Color color;
  final double size;

  const _AnimatedStatusDot({
    required this.color,
    required this.size,
  });

  @override
  State<_AnimatedStatusDot> createState() => _AnimatedStatusDotState();
}

class _AnimatedStatusDotState extends State<_AnimatedStatusDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.4 * _animation.value),
                blurRadius: 4 + (4 * _animation.value),
                spreadRadius: 1 + (2 * _animation.value),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Status chip for inline display with optional icon
class StatusChip extends StatelessWidget {
  final String status;
  final IconData? icon;
  final String? label;
  final bool isSeverity;

  const StatusChip({
    super.key,
    required this.status,
    this.icon,
    this.label,
    this.isSeverity = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayLabel = label ?? status;
    final color = isSeverity
        ? AppTheme.getSeverityColor(status)
        : AppTheme.getStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            displayLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
