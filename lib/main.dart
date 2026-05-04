import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'config/api_config.dart';
import 'services/auth_service.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/sign_up_deep_link_handler.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/sign_up_screen.dart';
import 'screens/main/main_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Print API configuration for debugging
  ApiConfig.printConfig();
  runApp(const MyApp());
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
        home: SignUpDeepLinkHandler(fallback: const SplashScreen()),
        routes: {
          '/login': (ctx) => const LoginScreen(),
          '/signup': (ctx) => const SignUpScreen(),
          '/main': (ctx) => const MainScreen(),
        },
      ),
    );
  }
}