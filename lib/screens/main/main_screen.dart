import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../dashboard/dashboard_screen.dart';
import '../sensors/sensors_screen.dart';
import '../actuators/actuators_screen.dart';
import '../profile/profile_screen.dart';
import '../silos/silos_screen.dart';
import '../../config/app_theme.dart';
import '../../widgets/common/app_toast.dart';
import 'widgets/bottom_navigation.dart';

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
      AppToast.show(context, 'Press back again to exit');
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
        // =====================================================
        // SCREEN CONTENT
        // =====================================================
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),

        // =====================================================
        // BOTTOM NAVIGATION BAR
        // =====================================================
        bottomNavigationBar: AppBottomNavigation(
          currentIndex: _currentIndex,
          destinations: _destinations,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
          },
        ),
      ),
    );
  }
}
