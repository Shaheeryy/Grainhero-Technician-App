import 'package:flutter/material.dart';
import '../../../../config/grainhero_colors.dart';

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
        color: GrainHeroColors.brandDark,
        // borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        // borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            height: 82,
            backgroundColor: GrainHeroColors.brandDark,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            indicatorColor: GrainHeroColors.primaryDark.withValues(alpha: 0.35),
            indicatorShape: const StadiumBorder(),
            iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
              final bool selected = states.contains(WidgetState.selected);
              return IconThemeData(
                color: selected ? GrainHeroColors.primary : GrainHeroColors.onDarkMuted,
                size: selected ? 26 : 24,
                weight: selected ? 600 : 400,
              );
            }),
            labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
              final bool selected = states.contains(WidgetState.selected);
              return TextStyle(
                color: selected ? GrainHeroColors.primary : GrainHeroColors.onDarkMuted,
                fontSize: 12,
                height: 1.25,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: selected ? 0.1 : 0,
              );
            }),
            overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
              if (states.contains(WidgetState.pressed)) {
                return GrainHeroColors.primary.withValues(alpha: 0.10);
              }
              if (states.contains(WidgetState.hovered)) {
                return GrainHeroColors.primary.withValues(alpha: 0.06);
              }
              return Colors.transparent;
            }),
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
