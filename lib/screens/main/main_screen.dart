import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../dashboard/dashboard_screen.dart';
import '../grain_batches/grain_batches_screen.dart';
import '../sensors/sensors_screen.dart';
import '../actuators/actuators_screen.dart';
import '../alerts/alerts_screen.dart';
import '../profile/profile_screen.dart';
import '../qr_scanner/qr_scanner_screen.dart';
import '../silos/silos_screen.dart';
import '../../config/app_theme.dart';
import '../../config/auth_theme.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  DateTime? _lastBackPress;

  final List<Widget> _screens = [
    DashboardScreen(),
    const SilosScreen(),
    const ActuatorsScreen(),
    const SensorsScreen(),
    const ProfileScreen(),
  ];

  // M3 Navigation Destinations
  final List<NavigationDestination> _destinations = const [
    NavigationDestination(
      tooltip: 'Home',
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
      label: 'Home',
    ),
    NavigationDestination(
      tooltip: 'Silos',
      icon: Icon(Icons.domain_outlined),
      selectedIcon: Icon(Icons.domain),
      label: 'Silos',
    ),
    NavigationDestination(
      tooltip: 'Actuators',
      icon: Icon(Icons.settings_input_component_outlined),
      selectedIcon: Icon(Icons.settings_input_component),
      label: 'Actuators',
    ),
    NavigationDestination(
      tooltip: 'Sensors',
      icon: Icon(Icons.sensors_outlined),
      selectedIcon: Icon(Icons.sensors),
      label: 'Sensors',
    ),
    NavigationDestination(
      tooltip: 'Profile',
      icon: Icon(Icons.person_outline_rounded),
      selectedIcon: Icon(Icons.person_rounded),
      label: 'Profile',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Handle back button: dismiss keyboard first, then require double-tap to exit.
  Future<bool> _onWillPop() async {
    // First, try to dismiss the keyboard if it's open
    final currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      currentFocus.unfocus();
      return false;
    }

    // If not on the home tab, go to home first
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return false;
    }

    // Double-tap back to exit
    final now = DateTime.now();
    if (_lastBackPress == null ||
        now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
      _lastBackPress = now;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Press back again to exit'),
          backgroundColor: AppTheme.surfaceColor,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
        ),
      );
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: _buildBottomNavBar(),
      ),
    );
  }

  Widget _buildBottomNavBar() {
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
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() => _currentIndex = index);
            },
            animationDuration: const Duration(milliseconds: 500),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            maintainBottomViewPadding: true,
            destinations: _destinations,
          ),
        ),
      ),
    );
  }
}
