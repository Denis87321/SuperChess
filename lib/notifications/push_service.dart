import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../auth/auth_service.dart';
import '../auth/platform_api.dart';

/// Push notifications via Firebase Cloud Messaging.
///
/// Requires platform Firebase setup:
/// - Android: `android/app/google-services.json` (and Google Services Gradle plugin)
/// - iOS: `GoogleService-Info.plist` + APNs
///
/// If Firebase is not configured, [init] fails safely and no-ops.
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  bool get isReady => _ready;

  /// Initialize FCM + local notifications. Safe if Firebase is missing.
  Future<void> init(AuthService auth) async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings();
      await _local.initialize(
        const InitializationSettings(
          android: androidInit,
          iOS: iosInit,
        ),
      );

      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      FirebaseMessaging.onMessage.listen((message) {
        final n = message.notification;
        if (n == null) return;
        _local.show(
          n.hashCode,
          n.title,
          n.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'superchess_default',
              'SuperChess',
              importance: Importance.defaultImportance,
            ),
            iOS: DarwinNotificationDetails(),
          ),
        );
      });

      final token = await messaging.getToken();
      if (token != null && auth.isLoggedIn) {
        await _register(auth, token);
      }

      messaging.onTokenRefresh.listen((token) async {
        if (auth.isLoggedIn) {
          await _register(auth, token);
        }
      });

      auth.addListener(() async {
        if (!auth.isLoggedIn) return;
        final t = await messaging.getToken();
        if (t != null) await _register(auth, t);
      });

      _ready = true;
    } catch (e, st) {
      debugPrint(
        'PushService: Firebase not configured or init failed '
        '(need google-services.json / GoogleService-Info.plist): $e\n$st',
      );
      _ready = false;
    }
  }

  Future<void> _register(AuthService auth, String token) async {
    try {
      await PlatformApi(auth).registerDevice(token, _platformName());
    } catch (e) {
      debugPrint('PushService registerDevice failed: $e');
    }
  }

  static String _platformName() {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => 'ios',
      TargetPlatform.android => 'android',
      _ => 'unknown',
    };
  }
}
