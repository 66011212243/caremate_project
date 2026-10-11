import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> notifyAllProviders({required String jobId}) async {
    final providers = await _firestore
        .collection('users')
        .where('role', isEqualTo: 1)
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
}
