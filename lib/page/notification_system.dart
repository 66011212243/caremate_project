import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationSystem {
  // Firebase Messaging
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // เริ่มต้นระบบ Notification
  Future<void> setupNotification(String userId) async {
    // 1. ขอ Permission จากผู้ใช้
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. ตรวจสอบว่าผู้ใช้อนุญาตหรือไม่
    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      // 3. ขอ FCM Token
      String? token = await _messaging.getToken();

      print('FCM Token: $token');

      // 4. ถ้าได้ Token ให้บันทึกลง Firestore
      if (token != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcm_token': token,
        });
      }
    } else {
      print('ผู้ใช้ไม่อนุญาต Notification');
    }

    // 5. กรณี Token เปลี่ยน ให้บันทึก Token ใหม่
    _messaging.onTokenRefresh.listen((newToken) async {
      print('New FCM Token: $newToken');

      await _firestore.collection('users').doc(userId).update({
        'fcm_token': newToken,
      });
    });
  }
}
