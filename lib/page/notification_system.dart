import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationSystem {
  static final NotificationSystem _instance = NotificationSystem._internal();
  factory NotificationSystem() => _instance;
  NotificationSystem._internal();

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<String>? _tokenSub;
  StreamSubscription<RemoteMessage>? _fgSub;
  StreamSubscription<RemoteMessage>? _openedSub;

  Future<void> setupNotification(String userId) async {
    try {
      await initLocalNotification();
      await listenForeground();

      // 1. ขอ Permission
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // 2. ตรวจสอบว่าอนุญาตหรือไม่
      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // 3. ขอ token
        final token = await _messaging.getToken();
        print('FCM Token: $token');

        // 4. บันทึกลง Firestore
        if (token != null) {
          await _firestore.collection('users').doc(userId).set({
            'fcm_token': token,
          }, SetOptions(merge: true));
        }
      } else {
        print('ผู้ใช้ไม่อนุญาต Notification');
      }

      // 5. ฟัง token refresh (ยกเลิกตัวเก่าก่อน)
      await _tokenSub?.cancel();
      _tokenSub = _messaging.onTokenRefresh.listen((newToken) async {
        print('New FCM Token: $newToken');
        try {
          await _firestore.collection('users').doc(userId).set({
            'fcm_token': newToken,
          }, SetOptions(merge: true));
        } catch (e) {
          print('บันทึก token ใหม่ไม่สำเร็จ: $e');
        }
      });

      // 6. กดแจ้งเตือนตอนแอปอยู่ background
      await _openedSub?.cancel();
      _openedSub = FirebaseMessaging.onMessageOpenedApp.listen((message) {
        // TODO: นำทางไปหน้างาน เช่น message.data['jobId']
      });

      // 7. กดแจ้งเตือนตอนแอปถูกปิดสนิท
      final initial = await _messaging.getInitialMessage();
      if (initial != null) {
        // TODO: นำทางไปหน้างาน
      }
    } catch (e) {
      print('setupNotification error: $e');
    }
  }

  // เรียกตอน Logout
  Future<void> removeToken(String userId) async {
    try {
      await _tokenSub?.cancel();
      _tokenSub = null;
      await _fgSub?.cancel();
      _fgSub = null;
      await _openedSub?.cancel();
      _openedSub = null;
      await _firestore.collection('users').doc(userId).update({
        'fcm_token': FieldValue.delete(),
      });
      await _messaging.deleteToken();
    } catch (e) {
      print('removeToken error: $e');
    }
  }

  Future<void> initLocalNotification() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();

    await _local.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );

    // สร้างช่องแจ้งเตือน Android
    const channel = AndroidNotificationChannel(
      'high_importance_channel',
      'การแจ้งเตือนสำคัญ',
      importance: Importance.high,
    );
    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  Future<void> listenForeground() async {
    await _fgSub?.cancel();
    _fgSub = FirebaseMessaging.onMessage.listen((message) {
      final n = message.notification;
      if (n == null) return;

      _local.show(
        id: n.hashCode,
        title: n.title,
        body: n.body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'การแจ้งเตือนสำคัญ',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    });
  }
}
