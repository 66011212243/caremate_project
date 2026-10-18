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
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _notificationSub;

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
      const InitializationSettings(android: android, iOS: ios),
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
        n.hashCode,
        n.title,
        n.body,
        const NotificationDetails(
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

  Future<void> listenFirestoreNotifications(String uid) async {
    await _notificationSub?.cancel();

    bool isFirstSnapshot = true;

    _notificationSub = _firestore
        .collection('notifications')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .listen((snapshot) async {
          print('กำลังฟังแจ้งเตือนของ uid: $uid');
          print('จำนวนเอกสารที่พบ: ${snapshot.docs.length}');
          print('จำนวนเอกสารที่เปลี่ยนแปลง: ${snapshot.docChanges.length}');
          // ข้ามข้อมูลทั้งหมดที่มีอยู่แล้วตอนเริ่มฟัง
          if (isFirstSnapshot) {
            isFirstSnapshot = false;
            return;
          }

          for (final change in snapshot.docChanges) {
            if (change.type != DocumentChangeType.added) continue;

            final data = change.doc.data();

            final title = data?['title'] as String? ?? 'CareMate';
            final type = data?['notification_type'];
            final jobId = data?['job_id']?.toString() ?? '';

            await _local.show(
              change.doc.id.hashCode & 0x7fffffff, // id
              title, // title
              _notificationBody(type), // body
              const NotificationDetails(
                android: AndroidNotificationDetails(
                  'high_importance_channel',
                  'การแจ้งเตือนสำคัญ',
                  channelDescription: 'การแจ้งเตือนจาก CareMate',
                  importance: Importance.high,
                  priority: Priority.high,
                ),
                iOS: DarwinNotificationDetails(),
              ),
              payload: jobId,
            );
          }
        });
  }

  String _notificationBody(dynamic type) {
    switch (type) {
      case 0:
        return 'มีผู้สมัครงานใหม่';
      case 1:
        return 'ผู้ให้บริการเริ่มงานแล้ว';
      case 2:
        return 'มีประกาศงานใหม่';
      case 3:
        return 'ผู้ให้บริการได้งานแล้ว';
      case 4:
        return 'ผู้รับบริการยกเลิกงาน';
      case 5:
        return 'มีการรายงาน';
      case 6:
        return 'ผู้ให้บริการยกเลิกงาน';
      case 7:
        return 'ผู้ให้บริการถูกระงับ';
      case 8:
        return 'ได้รับคำเตือนจากแอดมิน';
      case 9:
        return 'บัญชีถูกระงับการใช้งาน';
      default:
        return 'คุณมีการแจ้งเตือนใหม่';
    }
  }
}
