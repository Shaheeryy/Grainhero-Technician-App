import 'package:flutter/material.dart';
import 'package:grainhero_technician_app/config/auth_theme.dart';

class AppBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;

  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: AuthTheme.primaryGreen.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28),
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            height: 82,
            backgroundColor: AuthTheme.surface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            indicatorColor: AuthTheme.primaryGreen.withValues(alpha: 0.16),
            indicatorShape: const StadiumBorder(),
            iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
              (states) {
                final bool selected = states.contains(WidgetState.selected);
                return IconThemeData(
                  color: selected ? AuthTheme.primaryGreen : AuthTheme.textPrimary,
                  size: selected ? 26 : 24,
                  weight: selected ? 600 : 400,
                );
              },
            ),
            labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
              (states) {
                final bool selected = states.contains(WidgetState.selected);
                return TextStyle(
                  color: selected ? AuthTheme.greenOverlay : AuthTheme.textPrimary,
                  fontSize: 12,
                  height: 1.25,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: selected ? 0.1 : 0,
                );
              },
            ),
            overlayColor: WidgetStateProperty.resolveWith<Color?>(
              (states) {
                if (states.contains(WidgetState.pressed)) {
                  return AuthTheme.primaryGreen.withValues(alpha: 0.10);
                }
                if (states.contains(WidgetState.hovered)) {
                  return AuthTheme.primaryGreen.withValues(alpha: 0.06);
                }
                return Colors.transparent;
              },
            ),
          ),
          child: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: onDestinationSelected,
            animationDuration: const Duration(milliseconds: 500),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            maintainBottomViewPadding: true,
            destinations: destinations,
          ),
        ),
      ),
    );
  }
}
