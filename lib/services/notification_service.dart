import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─── Background message handler (must be top-level function) ────────────────
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('🔔 [FCM Background] ${message.notification?.title}: ${message.notification?.body}');
}

/// Manages all push notification functionality for the GrainHero Technician App.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final SupabaseClient _supabase = Supabase.instance.client;

  // Callback for when a notification is tapped — set from main.dart
  Function(Map<String, dynamic>)? onNotificationTap;

  // ─── Android notification channel ─────────────────────────────────────────
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'grainhero_high_importance',
    'GrainHero Alerts',
    description: 'Critical grain storage alerts and maintenance notifications',
    importance: Importance.max,
    playSound: true,
  );

  // ─── Initialize ───────────────────────────────────────────────────────────
  Future<void> initialize() async {
    // 1. Request permission
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('🔔 [FCM] Notifications permission denied by user.');
      return;
    }
    debugPrint('🔔 [FCM] Permission: ${settings.authorizationStatus}');

    // 2. Setup local notifications (for showing while app is foreground)
    await _setupLocalNotifications();

    // 3. Register background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 4. Foreground message handler
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 5. Notification tap when app is in background (but open)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // 6. Notification tap when app was terminated
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    // 7. Get token and register with backend
    await registerToken();

    // 8. Listen for token refresh
    _fcm.onTokenRefresh.listen((newToken) async {
      debugPrint('🔔 [FCM] Token refreshed — re-registering...');
      await _registerTokenWithBackend(newToken);
    });
  }

  // ─── Setup Local Notifications plugin ─────────────────────────────────────
  Future<void> _setupLocalNotifications() async {
    // Create Android channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _localNotifications.initialize(
      settings: const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (details) {
        // Tapped on local notification
        if (details.payload != null) {
          try {
            final data = jsonDecode(details.payload!);
            onNotificationTap?.call(data);
          } catch (_) {}
        }
      },
    );
  }

  // ─── Show local notification while app is in foreground ───────────────────
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    debugPrint('🔔 [FCM Foreground] ${notification.title}: ${notification.body}');

    await _localNotifications.show(
      id: message.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFFD4A017), // GrainHero gold
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  // ─── Handle notification tap navigation ───────────────────────────────────
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('🔔 [FCM] Notification tapped: ${message.data}');
    onNotificationTap?.call(message.data);
  }

  // ─── Get & Register FCM Token with backend ────────────────────────────────
  Future<void> registerToken() async {
    try {
      String? token;

      if (Platform.isIOS) {
        // iOS requires APNs token first
        await _fcm.getAPNSToken();
      }

      token = await _fcm.getToken();
      if (token == null) {
        debugPrint('🔔 [FCM] Could not get token.');
        return;
      }

      debugPrint('🔔 [FCM] Token: ${token.substring(0, 20)}...');
      await _registerTokenWithBackend(token);
    } catch (e) {
      debugPrint('🔔 [FCM] Token registration error: $e');
    }
  }

  Future<void> _registerTokenWithBackend(String token) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        debugPrint('🔔 [FCM] Not logged in, skipping token registration.');
        return;
      }

      // Supabase profiles update for fcm_tokens array
      // First fetch existing tokens
      final data = await _supabase.from('profiles').select('fcm_tokens').eq('id', user.id).single();
      List<dynamic> tokens = data['fcm_tokens'] ?? [];
      
      if (!tokens.contains(token)) {
        tokens.add(token);
        await _supabase.from('profiles').update({'fcm_tokens': tokens}).eq('id', user.id);
        debugPrint('🔔 [FCM] Token registered with backend ✅');
      }
    } catch (e) {
      debugPrint('🔔 [FCM] Backend registration error: $e');
    }
  }

  // ─── Unregister token on logout ───────────────────────────────────────────
  Future<void> unregisterToken() async {
    try {
      final token = await _fcm.getToken();
      if (token == null) return;

      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final data = await _supabase.from('profiles').select('fcm_tokens').eq('id', user.id).single();
      List<dynamic> tokens = data['fcm_tokens'] ?? [];
      
      if (tokens.contains(token)) {
        tokens.remove(token);
        await _supabase.from('profiles').update({'fcm_tokens': tokens}).eq('id', user.id);
      }

      await _fcm.deleteToken();
      debugPrint('🔔 [FCM] Token unregistered on logout ✅');
    } catch (e) {
      debugPrint('🔔 [FCM] Unregister token error: $e');
    }
  }
}
