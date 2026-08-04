import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/app_theme.dart';
import 'config/supabase_config.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/sign_up_deep_link_handler.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/accept_invite_screen.dart';
import 'screens/main/main_screen.dart';
import 'screens/grain_batches/grain_batch_detail_screen.dart';
import 'screens/alerts/alerts_screen.dart';

// Navigator key for navigation from notification taps
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    publishableKey: SupabaseConfig.supabaseAnonKey,
  );

  // Initialize Firebase
  await Firebase.initializeApp();

  // API Config debug print removed

  // Initialize push notifications
  final notificationService = NotificationService();
  notificationService.onNotificationTap = (data) {
    _handleNotificationNavigation(data);
  };
  // Delay init until after first frame so context is ready
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await notificationService.initialize();
  });

  runApp(const MyApp());
}

/// Navigate to correct screen when notification is tapped
void _handleNotificationNavigation(Map<String, dynamic> data) {
  final context = navigatorKey.currentContext;
  if (context == null) return;

  final category = data['category']?.toString() ?? '';
  final entityId = data['entity_id']?.toString() ?? '';

  debugPrint('🔔 [Nav] Notification tap: category=$category, id=$entityId');

  if (category == 'batch' && entityId.isNotEmpty) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => GrainBatchDetailScreen(batchId: entityId),
      ),
    );
  } else if (category == 'alert' || category == 'system') {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => const AlertsScreen(),
      ),
    );
  } else {
    // Default: go to main screen
    navigatorKey.currentState?.pushNamedAndRemoveUntil('/main', (r) => false);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthService())],
      child: MaterialApp(
        title: 'GrainHero Technician',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        navigatorKey: navigatorKey,
        home: SignUpDeepLinkHandler(fallback: const SplashScreen()),
        routes: {
          '/login': (ctx) => const LoginScreen(),
          '/signup': (ctx) => const AcceptInviteScreen(),
          '/main': (ctx) => const MainScreen(),
        },
      ),
    );
  }
}