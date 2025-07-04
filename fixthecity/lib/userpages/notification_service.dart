import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../main.dart';

class PushNotifications {
  static final firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // Request notification permission
  static Future<void> init() async {
    await firebaseMessaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: false,
      criticalAlert: true,
      provisional: false,
      sound: true,
    );

    // Get device token
    final token = await firebaseMessaging.getToken();
    print('FCM Token: $token');

    if (token != null) {
      await saveTokenToDatabase(token); // Save the FCM token to Firestore
    }

    // // Initialize local notifications
    // await localNotiInit();

    // Handle token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      await saveTokenToDatabase(newToken);
    });
  }

  // Save FCM token to Firestore
  static Future<void> saveTokenToDatabase(String token) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String uid = user.uid;

      // Reference to the user's document in Firestore
      DocumentReference userDoc = FirebaseFirestore.instance.collection('users').doc(uid);

      // Save or update the FCM token for the current user
      await userDoc.update({
        'fcmToken': token,
      }).catchError((e) async {
        // If document does not exist, create it with the token
        await userDoc.set({
          'fcmToken': token,
        }, SetOptions(merge: true));
      });
    }
  }

  // Initialize local notifications
  static Future<void> localNotiInit() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings(
      onDidReceiveLocalNotification: (id, title, body, payload) => null,
    );

    final LinuxInitializationSettings initializationSettingsLinux = LinuxInitializationSettings(defaultActionName: 'Open notification');

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      linux: initializationSettingsLinux,
    );

    // Request notification permissions for Android 13 or above
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()!
        .requestNotificationsPermission();

    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onNotificationTap,
      onDidReceiveBackgroundNotificationResponse: onNotificationTap,
    );
  }

  // Handle notification tap in the foreground
  static void onNotificationTap(NotificationResponse notificationResponse) {
    navigatorKey.currentState!.pushNamed("/message", arguments: notificationResponse);
  }

  // Show a simple notification
  static Future<void> showSimpleNotification({
    required String title,
    required String body,
    required String payload,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
      'your channel id', 'your channel name',
      channelDescription: 'your channel description',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails notificationDetails = NotificationDetails(android: androidNotificationDetails);

    await flutterLocalNotificationsPlugin.show(0, title, body, notificationDetails, payload: payload);
  }
}
