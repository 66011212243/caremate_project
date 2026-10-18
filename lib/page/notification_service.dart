import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> notifyAllProviders({required String jobId}) async {
    final providers = await _firestore
        .collection('users')
        .where('role', isEqualTo: 1)
        .where('status_account', isEqualTo: 1)
        .get();

    if (providers.docs.isEmpty) {
      print('ไม่พบผู้ให้บริการ');
      return;
    }

    final batch = _firestore.batch();

    for (final provider in providers.docs) {
      final notificationRef = _firestore.collection('notifications').doc();

      batch.set(notificationRef, {
        'title': 'มีงานใหม่',
        'notification_type': 2,
        'job_id': jobId,
        'uid': provider.id,
        'notification_status': 0,
        'created_at': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();

    print(
      'สร้างการแจ้งเตือนให้ Provider '
      '${providers.docs.length} คนแล้ว',
    );
  }

  Future<void> notifyProviderJobAccepted({
    required String jobId,
    required String providerId,
  }) async {
    try {
      // 1. ดึงข้อมูลงานจาก
      final providerDoc = await _firestore
          .collection('provider')
          .doc(providerId)
          .get();

      if (!providerDoc.exists) {
        print('ไม่พบผู้ให้บริการ');
        return;
      }

      final providerData = providerDoc.data()!;
      final poviderUid = providerData['provider_uid'];

      if (poviderUid == null || poviderUid.toString().isEmpty) {
        print('ไม่พบ provider_uid ');
        return;
      }

      // 3. สร้าง Notification แจ้งเตือนผู้รับบริการ
      await _firestore.collection('notifications').add({
        'uid': poviderUid.toString(),
        'title': 'ผู้รับบริการเลือกคุณให้รับงานนี้แล้ว',
        'notification_type': 3,
        'job_id': jobId,
        'notification_status': 0,
        'created_at': FieldValue.serverTimestamp(),
      });

      print('สร้างการแจ้งเตือนสำเร็จ');
    } catch (e) {
      print('เกิดข้อผิดพลาดในการแจ้งเตือน: $e');
    }
  }

  Future<void> notifyProviderJobCancelledByService({
    required String jobId,
    required String providerId,
  }) async {
    try {
      // 1. ค้นหาข้อมูลผู้ให้บริการด้วย providerId
      final providerDoc = await _firestore
          .collection('provider')
          .doc(providerId)
          .get();

      if (!providerDoc.exists) {
        print('ไม่พบข้อมูลผู้ให้บริการ: $providerId');
        return;
      }

      // 2. ดึง provider_uid
      final providerData = providerDoc.data();
      if (providerData == null) {
        print('ไม่พบข้อมูลผู้ให้บริการ');
        return;
      }

      final providerUid = providerData['provider_uid'];

      if (providerUid == null || providerUid.toString().isEmpty) {
        print('ไม่พบ provider_uid');
        return;
      }

      // 3. สร้าง Notification แจ้งผู้ให้บริการ
      await _firestore.collection('notifications').add({
        'uid': providerUid.toString(),
        'title': 'ผู้รับบริการยกเลิกงานที่คุณได้รับ',
        'notification_type': 4,
        'job_id': jobId,
        'notification_status': 0,
        'created_at': FieldValue.serverTimestamp(),
      });

      print('สร้างการแจ้งเตือนสำเร็จสำหรับ providerId: $providerId');
    } catch (e) {
      print('เกิดข้อผิดพลาดในการแจ้งเตือน: $e');
    }
  }

  Future<void> notifyProviderWarning({
    required String jobId,
    required String userId,
  }) async {
    try {
      // 3. สร้าง Notification แจ้งผู้ให้บริการ
      await _firestore.collection('notifications').add({
        'uid': userId,
        'title': 'คุณได้รับการตักเตือนจากผู้ดูแลระบบ',
        'notification_type': 8,
        'job_id': jobId,
        'notification_status': 0,
        'created_at': FieldValue.serverTimestamp(),
      });

      print('สร้างการแจ้งเตือนสำเร็จสำหรับ userId: userId');
    } catch (e) {
      print('เกิดข้อผิดพลาดในการแจ้งเตือน: $e');
    }
  }

  Future<void> notifyProviderAccountSuspended({required String userId}) async {
    try {
      // 3. สร้าง Notification แจ้งผู้ให้บริการ
      await _firestore.collection('notifications').add({
        'uid': userId,
        'title': 'บัญชีของคุณถูกระงับการใช้งานชั่วคราว',
        'notification_type': 9,
        'job_id': null,
        'notification_status': 0,
        'created_at': FieldValue.serverTimestamp(),
      });

      print('สร้างการแจ้งเตือนสำเร็จสำหรับ userId: userId');
    } catch (e) {
      print('เกิดข้อผิดพลาดในการแจ้งเตือน: $e');
    }
  }

  ////////////////////////////////////////////////
  //          ผู้รับบริการ
  ////////////////////////////////////////////////
  Future<void> notifyService({required String jobId}) async {
    try {
      // 1. ดึงข้อมูลงานจาก jobs
      final jobDoc = await _firestore.collection('jobs').doc(jobId).get();

      if (!jobDoc.exists) {
        print('ไม่พบงาน');
        return;
      }

      final jobData = jobDoc.data()!;
      final serviceId = jobData['service_id'];

      if (serviceId == null || serviceId.toString().isEmpty) {
        print('ไม่พบ service_id ของงาน');
        return;
      }

      // 2. ใช้ service_id ไปค้นหาเจ้าของงานใน service
      final serviceDoc = await _firestore
          .collection('service')
          .doc(serviceId.toString())
          .get();

      if (!serviceDoc.exists) {
        print('ไม่พบข้อมูล service');
        return;
      }

      final serviceData = serviceDoc.data()!;
      final serviceUid = serviceData['service_uid'];

      if (serviceUid == null || serviceUid.toString().isEmpty) {
        print('ไม่พบ service_uid');
        return;
      }

      // 3. สร้าง Notification แจ้งเตือนผู้รับบริการ
      await _firestore.collection('notifications').add({
        'uid': serviceUid.toString(),
        'title': 'มีผู้ให้บริการสนใจรับงานของคุณ',
        'notification_type': 0,
        'job_id': jobId,
        'notification_status': 0,
        'created_at': FieldValue.serverTimestamp(),
      });

      print('สร้างการแจ้งเตือนสำเร็จ');
    } catch (e) {
      print('เกิดข้อผิดพลาดในการแจ้งเตือน: $e');
    }
  }

  Future<void> notifyServiceProviderStartedJob({required String jobId}) async {
    try {
      // 1. ดึงข้อมูลงานจาก jobs
      final jobDoc = await _firestore.collection('jobs').doc(jobId).get();

      if (!jobDoc.exists) {
        print('ไม่พบงาน');
        return;
      }

      final jobData = jobDoc.data()!;
      final serviceId = jobData['service_id'];

      if (serviceId == null || serviceId.toString().isEmpty) {
        print('ไม่พบ service_id ของงาน');
        return;
      }

      // 2. ใช้ service_id ไปค้นหาเจ้าของงานใน service
      final serviceDoc = await _firestore
          .collection('service')
          .doc(serviceId.toString())
          .get();

      if (!serviceDoc.exists) {
        print('ไม่พบข้อมูล service');
        return;
      }

      final serviceData = serviceDoc.data()!;
      final serviceUid = serviceData['service_uid'];

      if (serviceUid == null || serviceUid.toString().isEmpty) {
        print('ไม่พบ service_uid');
        return;
      }

      // 3. สร้าง Notification แจ้งเตือนผู้รับบริการ
      await _firestore.collection('notifications').add({
        'uid': serviceUid.toString(),
        'title': 'ผู้ให้บริการเริ่มเดินทางไปรับคุณแล้ว',
        'notification_type': 1,
        'job_id': jobId,
        'notification_status': 0,
        'created_at': FieldValue.serverTimestamp(),
      });

      print('สร้างการแจ้งเตือนสำเร็จ');
    } catch (e) {
      print('เกิดข้อผิดพลาดในการแจ้งเตือน: $e');
    }
  }

  Future<void> notifyServiceProviderCancelledJob({
    required String jobId,
  }) async {
    try {
      // 1. ดึงข้อมูลงานจาก jobs
      final jobDoc = await _firestore.collection('jobs').doc(jobId).get();

      if (!jobDoc.exists) {
        print('ไม่พบงาน');
        return;
      }

      final jobData = jobDoc.data()!;
      final serviceId = jobData['service_id'];

      if (serviceId == null || serviceId.toString().isEmpty) {
        print('ไม่พบ service_id ของงาน');
        return;
      }

      // 2. ใช้ service_id ไปค้นหาเจ้าของงานใน service
      final serviceDoc = await _firestore
          .collection('service')
          .doc(serviceId.toString())
          .get();

      if (!serviceDoc.exists) {
        print('ไม่พบข้อมูล service');
        return;
      }

      final serviceData = serviceDoc.data()!;
      final serviceUid = serviceData['service_uid'];

      if (serviceUid == null || serviceUid.toString().isEmpty) {
        print('ไม่พบ service_uid');
        return;
      }

      // 3. สร้าง Notification แจ้งเตือนผู้รับบริการ
      await _firestore.collection('notifications').add({
        'uid': serviceUid.toString(),
        'title': 'ผู้ให้บริการยกเลิกงานของคุณ',
        'notification_type': 6,
        'job_id': jobId,
        'notification_status': 0,
        'created_at': FieldValue.serverTimestamp(),
      });

      print('สร้างการแจ้งเตือนสำเร็จ');
    } catch (e) {
      print('เกิดข้อผิดพลาดในการแจ้งเตือน: $e');
    }
  }

  Future<void> notifyReceiverProviderSuspended({
    required String jobId,
    required String userId,
  }) async {
    try {
      // 3. สร้าง Notification แจ้งผู้ให้บริการ
      await _firestore.collection('notifications').add({
        'uid': userId,
        'title': 'ผู้ให้บริการถูกระงับ กรุณาเลือกผู้ให้บริการใหม่',
        'notification_type': 7,
        'job_id': jobId,
        'notification_status': 0,
        'created_at': FieldValue.serverTimestamp(),
      });

      print('สร้างการแจ้งเตือนสำเร็จสำหรับ userId: userId');
    } catch (e) {
      print('เกิดข้อผิดพลาดในการแจ้งเตือน: $e');
    }
  }

  // Future<void> notifyJobReminderOneDayBefore({
  //   required String jobId,
  // }) async {
  //   try {
  //     // 1. ดึงข้อมูลงานจาก jobs
  //     final jobDoc = await _firestore.collection('jobs').doc(jobId).get();

  //     if (!jobDoc.exists) {
  //       print('ไม่พบงาน');
  //       return;
  //     }

  //     final jobData = jobDoc.data()!;
  //     final serviceId = jobData['service_id'];

  //     if (serviceId == null || serviceId.toString().isEmpty) {
  //       print('ไม่พบ service_id ของงาน');
  //       return;
  //     }

  //     // 2. ใช้ service_id ไปค้นหาเจ้าของงานใน service
  //     final serviceDoc = await _firestore
  //         .collection('service')
  //         .doc(serviceId.toString())
  //         .get();

  //     if (!serviceDoc.exists) {
  //       print('ไม่พบข้อมูล service');
  //       return;
  //     }

  //     final serviceData = serviceDoc.data()!;
  //     final serviceUid = serviceData['service_uid'];

  //     if (serviceUid == null || serviceUid.toString().isEmpty) {
  //       print('ไม่พบ service_uid');
  //       return;
  //     }

  //     // 3. สร้าง Notification แจ้งเตือนผู้รับบริการ
  //     await _firestore.collection('notifications').add({
  //       'uid': serviceUid.toString(),
  //       'title': 'ผู้ให้บริการยกเลิกงานของคุณ',
  //       'notification_type': 0,
  //       'job_id': jobId,
  //       'notification_status': 0,
  //       'created_at': FieldValue.serverTimestamp(),
  //     });

  //     print('สร้างการแจ้งเตือนสำเร็จ');
  //   } catch (e) {
  //     print('เกิดข้อผิดพลาดในการแจ้งเตือน: $e');
  //   }
  // }

  ////////////////////////////////////////////////
  //          แอดมิน
  ////////////////////////////////////////////////

  Future<void> notifyAdminsNewReport({required String jobId}) async {
    try {
      // 1. ค้นหาแอดมินทั้งหมด (role = 2)
      final adminSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 2)
          .get();

      if (adminSnapshot.docs.isEmpty) {
        debugPrint('ไม่พบแอดมินในระบบ');
        return;
      }

      // 2. สร้างการแจ้งเตือนให้แอดมินทุกคน
      final batch = _firestore.batch();

      for (final adminDoc in adminSnapshot.docs) {
        final adminUid = adminDoc.id;

        final notificationRef = _firestore.collection('notifications').doc();

        batch.set(notificationRef, {
          'uid': adminUid,
          'title': 'มีรายงานผู้ให้บริการใหม่',
          'notification_type': 5,
          'job_id': jobId,
          'notification_status': 0,
          'created_at': FieldValue.serverTimestamp(),
        });
      }

      // 3. บันทึกการแจ้งเตือนทั้งหมด
      await batch.commit();

      debugPrint(
        'ส่งการแจ้งเตือนแอดมินสำเร็จ '
        '${adminSnapshot.docs.length} คน',
      );
    } catch (e) {
      debugPrint('แจ้งเตือนแอดมินไม่สำเร็จ: $e');
    }
  }
}
