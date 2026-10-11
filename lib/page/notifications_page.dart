import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class NotificationsPage extends StatefulWidget {
  final String uid;

  const NotificationsPage({super.key, required this.uid});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String formatDate(dynamic value) {
    if (value is Timestamp) {
      return DateFormat('d MMM yyyy HH:mm').format(value.toDate());
    }

    if (value is DateTime) {
      return DateFormat('d MMM yyyy HH:mm').format(value);
    }

    return 'กำลังบันทึกเวลา...';
  }

  Future<void> markAsRead(String documentId) async {
    try {
      await _firestore.collection('notifications').doc(documentId).update({
        'notification_status': 1,
      });
    } catch (e) {
      debugPrint('อัปเดตสถานะการอ่านไม่สำเร็จ: $e');
    }
  }

  IconData getNotificationIcon(int type) {
    switch (type) {
      case 0:
        return Icons.person_add_alt_1_outlined;
      case 1:
        return Icons.play_circle_outline;
      case 2:
        return Icons.work_outline;
      case 3:
        return Icons.check_circle_outline;
      case 4:
        return Icons.cancel_outlined;
      case 5:
        return Icons.report_problem_outlined;
      case 6:
        return Icons.event_busy_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Row(
          children: [
            Icon(Icons.notifications_outlined, color: Colors.black, size: 28),
            SizedBox(width: 10),
            Text(
              'การแจ้งเตือน',
              style: TextStyle(
                color: Colors.black,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestore
            .collection('notifications')
            .where('uid', isEqualTo: widget.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('ไม่สามารถโหลดการแจ้งเตือนได้'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          // เรียงรายการจากใหม่ไปเก่า
          docs.sort((a, b) {
            final aTime = a.data()['created_at'];
            final bTime = b.data()['created_at'];

            final aDate = aTime is Timestamp
                ? aTime.toDate()
                : DateTime.fromMillisecondsSinceEpoch(0);

            final bDate = bTime is Timestamp
                ? bTime.toDate()
                : DateTime.fromMillisecondsSinceEpoch(0);

            return bDate.compareTo(aDate);
          });

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 70,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'ยังไม่มีการแจ้งเตือน',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final notification = doc.data();

              final title = notification['title'] as String? ?? '';

              final type = notification['notification_type'] as int? ?? -1;

              final jobId = notification['job_id'] as String? ?? '';

              final status = notification['notification_status'] as int? ?? 0;

              final isRead = status == 1;

              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () async {
                  if (!isRead) {
                    await markAsRead(doc.id);
                  }

                  // TODO: ใช้ jobId นำทางไปหน้ารายละเอียดงาน
                  debugPrint('Notification job_id: $jobId');
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isRead
                          ? Colors.grey.shade200
                          : Colors.red.shade100,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: isRead
                              ? Colors.grey.shade100
                              : Colors.red.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          getNotificationIcon(type),
                          color: isRead ? Colors.grey : Colors.red,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: isRead
                                          ? FontWeight.w500
                                          : FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (!isRead)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.only(
                                      top: 7,
                                      left: 6,
                                    ),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 7),
                            Text(
                              getNotificationMessage(type),
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 15,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    formatDate(notification['created_at']),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String getNotificationMessage(int type) {
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
        return 'งานถูกยกเลิก';
      case 5:
        return 'มีการรายงาน';
      case 6:
        return 'มีการยกเลิกงาน';
      default:
        return 'คุณมีการแจ้งเตือนใหม่';
    }
  }
}
