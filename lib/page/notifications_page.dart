import 'package:caremate_application/page/admin_all_report.dart';
import 'package:caremate_application/page/details_job.dart';
import 'package:caremate_application/page/details_job_service.dart';
import 'package:caremate_application/page/drivers_page.dart';
import 'package:caremate_application/page/position_provider.dart';
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
  int? userRole;
  String? sid;
  String? pid;
  bool isUserDataLoading = true;
  @override
  void initState() {
    super.initState();
    loadUserIdentity();
  }

  Future<void> loadUserIdentity() async {
    try {
      // 1. ตรวจสอบบัญชีผู้ใช้
      final userDoc = await _firestore
          .collection('users')
          .doc(widget.uid)
          .get();

      if (!userDoc.exists) {
        debugPrint('ไม่พบบัญชีผู้ใช้');
        return;
      }

      final userData = userDoc.data()!;
      final role = (userData['role'] as num?)?.toInt();

      if (role == null) {
        debugPrint('ไม่พบ role ของผู้ใช้');
        return;
      }

      userRole = role;

      // 2. ถ้าเป็นผู้รับบริการ ให้ค้นหา sid
      if (role == 0) {
        final serviceQuery = await _firestore
            .collection('service')
            .where('service_uid', isEqualTo: widget.uid)
            .limit(1)
            .get();

        if (serviceQuery.docs.isNotEmpty) {
          sid = serviceQuery.docs.first.id;
        } else {
          debugPrint('ไม่พบ sid ของผู้รับบริการ');
        }
      }
      // 3. ถ้าเป็นผู้ให้บริการ ให้ค้นหา pid
      else if (role == 1) {
        final providerQuery = await _firestore
            .collection('provider')
            .where('provider_uid', isEqualTo: widget.uid)
            .limit(1)
            .get();

        if (providerQuery.docs.isNotEmpty) {
          pid = providerQuery.docs.first.id;
        } else {
          debugPrint('ไม่พบ pid ของผู้ให้บริการ');
        }
      }
      // 4. ถ้าเป็นแอดมิน ให้จัดการตาม role ของแอดมิน
      else {
        debugPrint('ผู้ใช้มี role อื่น: $role');
      }
    } catch (e) {
      debugPrint('โหลดข้อมูลบัญชีไม่สำเร็จ: $e');
    } finally {
      if (mounted) {
        setState(() {
          isUserDataLoading = false;
        });
      }
    }
  }

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
                  await _handleNotificationTap(
                    type: type,
                    jobId: jobId,
                    notificationId: doc.id,
                  );
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
                                    getNotificationMessage(type),
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
                              title,
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

  Future<void> _handleNotificationTap({
    required int type,
    required String jobId,
    required String notificationId,
  }) async {
    // 1. ทำเครื่องหมายว่าอ่านแล้ว
    await markAsRead(notificationId);

    if (!mounted) return;

    // 2. แยกหน้าตามประเภทการแจ้งเตือน
    switch (type) {
      case 0:
        // ผู้รับบริการ: มีผู้สมัครงานใหม่
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailsJobService(jobId: jobId),
          ),
        );
        break;

      case 1:
        final jobStatus = await getJobStatus(jobId);

        if (!context.mounted) return;

        if (jobStatus == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ไม่พบข้อมูลงาน กรุณาลองใหม่')),
          );
          break;
        }

        if (jobStatus == 9 || jobStatus == 10) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('งานนี้เสร็จสิ้นหรือถูกยกเลิกแล้ว')),
          );
          break;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PositionProvider(jobId: jobId),
          ),
        );
        break;

      case 2:
        final jobStatus = await getJobStatus(jobId);

        if (!context.mounted) return;

        if (jobStatus == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ไม่พบข้อมูลงาน กรุณาลองใหม่')),
          );
          break;
        }

        if (jobStatus != 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('งานนี้มีผู้ให้บริการแล้ว')),
          );
          break;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailsJob(jobId: jobId, pid: pid!),
          ),
        );
        break;

      case 3:
        final jobStatus = await getJobStatus(jobId);

        if (!context.mounted) return;

        if (jobStatus == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ไม่พบข้อมูลงาน กรุณาลองใหม่')),
          );
          break;
        }

        if (jobStatus == 9 || jobStatus == 10) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('งานนี้เสร็จสิ้นหรือถูกยกเลิกแล้ว')),
          );
          break;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailsJob(jobId: jobId, pid: pid!),
          ),
        );
        break;

      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailsJob(jobId: jobId, pid: pid!),
          ),
        );
        break;

      case 5:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AdminAllReport()),
        );
        break;

      case 6:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailsJobService(jobId: jobId),
          ),
        );
        break;

      case 7:
        // แจ้งเตือนงานล่วงหน้า
        // เปิดรายละเอียดงานตามบทบาทผู้ใช้
        break;

      default:
        debugPrint('ไม่รู้จัก notification_type: $type');
    }
  }

  Future<int?> getJobStatus(String jobId) async {
    try {
      final doc = await _firestore.collection('jobs').doc(jobId).get();

      if (!doc.exists) {
        debugPrint('ไม่พบงาน jobId: $jobId');
        return null;
      }

      final data = doc.data();
      return (data?['job_status'] as num?)?.toInt();
    } catch (e) {
      debugPrint('เกิดข้อผิดพลาดในการดึงสถานะงาน: $e');
      return null;
    }
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
        return 'ผู้รับบริการยกเลิกงาน';
      case 5:
        return 'มีการรายงาน';
      case 6:
        return 'ผู้ให้บริการยกเลิกงาน';
      case 7:
        return 'แจ้งเตือนงานล่วงหน้า 1 วัน';
      default:
        return 'คุณมีการแจ้งเตือนใหม่';
    }
  }
}
