import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';
import 'user_session.dart';
import 'app_nav.dart';
import 'home_pages.dart';

/// Service to handle Firebase Cloud Messaging (Steps 7, 8, 9, 12)
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final List<void Function()> _notificationListeners = [];
  
  // Local Notifications Plugin
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // High Importance Channel for Android
  final AndroidNotificationChannel _channel = const AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description: 'This channel is used for important weight notifications.', // description
    importance: Importance.high,
    playSound: true,
  );

  static void addListener(void Function() listener) {
    if (!_instance._notificationListeners.contains(listener)) {
      _instance._notificationListeners.add(listener);
    }
  }

  static void removeListener(void Function() listener) {
    _instance._notificationListeners.remove(listener);
  }

  static void _notifyListeners() {
    for (var listener in _instance._notificationListeners) {
      listener();
    }
  }

  Future<void> initialize() async {
    print("🔔 NotificationService: initialize() CALLED");

    try {
      // 1. Initialize Local Notifications
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher'); // Using your launcher icon
      
      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
      );

      await _localNotifications.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {
          print("🔔 Clicked Local Notification: ${details.payload}");
          // JUMP TO NOTIFICATIONS PAGE
          rootNavigatorKey.currentState?.push(
            MaterialPageRoute(builder: (_) => const NotificationsTab()),
          );
        },
      );

      // 2. Create the Android High Importance channel
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);

      // 3. Set up the foreground message listener (Step 12)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print("🔔 FCM: Notification received: ${message.notification?.title}");
        
        _showLocalNotification(message);
        
        _notifyListeners();
      });

      // 4. Handle notification clicks when app is in BACKGROUND
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print("🔔 Clicked Background Notification: ${message.data}");
        // JUMP TO NOTIFICATIONS PAGE
        rootNavigatorKey.currentState?.push(
            MaterialPageRoute(builder: (_) => const NotificationsTab()),
        );
      });

      // 5. Check if app was opened FROM a terminated state by a notification
      RemoteMessage? initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
          print("🔔 App opened from TERMINATED state via notification!");
          // Wait a bit for the app to settle then jump
          Future.delayed(const Duration(seconds: 1), () {
             rootNavigatorKey.currentState?.push(
                MaterialPageRoute(builder: (_) => const NotificationsTab()),
             );
          });
      }

      // 6. Request Notification Permission
      print("🔔 NotificationService: Requesting permission...");
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      print("🔔 NotificationService: Permission status: ${settings.authorizationStatus}");

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Step 8: Get Device Token
        print("🔔 NotificationService: Fetching FCM Token...");
        String? fcmToken = await _fcm.getToken();
        
        if (fcmToken != null) {
          print("🔔 NotificationService: Got Token: ${fcmToken.substring(0, 10)}...");
          _syncToken(fcmToken);
        }

        _fcm.onTokenRefresh.listen((newToken) {
          print("🔔 NotificationService: Token Refreshed!");
          _syncToken(newToken);
        });
      }

      // Handle when app is opened from a notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print("🔔 NotificationService: App opened via notification!");
      });

    } catch (e) {
      print("❌ NotificationService ERROR: $e");
    }
  }

  // Show a local notification for foreground messages
  Future<void> _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      _localNotifications.show(
        id: notification.hashCode,
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
            playSound: true,
          ),
        ),
      );
    }
  }

  /// Sync the FCM token with our backend whenever it changes or on app start
  Future<void> _syncToken(String fcmToken) async {
    print("📣 FCM Sync: Starting process for token: ${fcmToken.substring(0, 5)}...");
    
    final sessionToken = UserSession().token;
    print("📣 FCM Sync: Current Session Token is: ${sessionToken == null ? 'NULL' : (sessionToken.isEmpty ? 'EMPTY' : 'VALID')}");

    if (sessionToken == null || sessionToken.isEmpty) {
      print("📣 FCM Sync: CANCELLED - User is not logged in yet.");
      return;
    }

    print("📣 FCM Sync: ALL CLEAR! Sending to Laravel...");

    try {
      final response = await ApiService.updateFCMToken(sessionToken, fcmToken);
      if (response['success'] == true) {
        print("✅ FCM SUCCESS: Token saved for ${UserSession().email}!");
      } else {
        print("❌ FCM FAILED: Server said: ${response['message']}");
      }
    } catch (e) {
      print("❌ FCM EXCEPTION Error: $e");
    }
  }
}
