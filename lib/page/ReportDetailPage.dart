import 'package:caremate_application/page/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ReportDetailPage extends StatelessWidget {
  final String reportsId; // ส่ง reportId มาจากหน้าก่อนหน้า

  ReportDetailPage({super.key, required this.reportsId});

  bool isBanAccount = false;
  bool isWarning = false;

  // ฟังก์ชันดึงข้อมูลรายละเอียดรายงาน และข้อมูล Provider / User ที่ถูกรายงาน
  Future<Map<String, dynamic>> fetchReportDetails() async {
    final db = FirebaseFirestore.instance;

    // 1. ดึงข้อมูลจากคอลเลกชัน reports
    final reportDoc = await db.collection('reports').doc(reportsId).get();
    if (!reportDoc.exists) {
      throw Exception('ไม่พบข้อมูลการรายงาน');
    }

    final reportData = reportDoc.data()!;
    final description = reportData['description'] ?? 'ไม่มีรายละเอียด';
    final status_report = reportData['status_re'];
    final job_id = reportData['job_id'];

    // ดึง ID ของ Provider ที่ถูกรายงาน (หรือ reporter_id ของผู้รายงาน)
    final reportedProviderId =
        (reportData['reported_provider_id'])?.toString() ?? '';
    '';

    String driverName = 'ไม่ระบุชื่อ';
    String phoneNo = 'ไม่ระบุเบอร์โทรศัพท์';
    String vehicleRegistration = 'ไม่ระบุทะเบียนรถ';
    String profileUrl = '';
    int? reportsNum;
    String userId = '';
    int? status_acc;

    // 2. ดึงข้อมูล provider
    if (reportedProviderId.isNotEmpty) {
      final providerDoc = await db
          .collection('provider')
          .doc(reportedProviderId)
          .get();

      if (providerDoc.exists) {
        final providerData = providerDoc.data()!;
        phoneNo =
            providerData['phoneNo']?.toString() ??
            providerData['phone']?.toString() ??
            'ไม่ระบุเบอร์โทรศัพท์';

        // --- ดึง URL รูปโปรไฟล์จาก provider ---
        profileUrl = providerData['profile']?.toString() ?? '';
        reportsNum = providerData['reports_num'];
        userId = providerData['provider_uid'];

        final providerUid =
            (providerData['provider_uid'] ?? providerData['uid'])?.toString() ??
            '';

        // 3. ดึงข้อมูลจากคอลเลกชัน users (ดึงชื่อจากที่นี่)
        if (providerUid.isNotEmpty) {
          // ลองหาโดยใช้ providerUid เป็น Document ID
          DocumentSnapshot userDoc = await db
              .collection('users')
              .doc(providerUid)
              .get();

          // ถ้าหาไม่เจอ ลองค้นผ่าน field 'uid' ใน users
          if (!userDoc.exists) {
            final userQuery = await db
                .collection('users')
                .where('uid', isEqualTo: providerUid)
                .limit(1)
                .get();

            if (userQuery.docs.isNotEmpty) {
              userDoc = userQuery.docs.first;
            }
          }

          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;

            // --- ดึงชื่อจาก users ---
            driverName = userData['realname']?.toString() ?? 'ไม่ระบุชื่อ';
            status_acc = userData['status_account'];
          }
        }
      }
    }

    return {
      'description': description,
      'driverName': driverName,
      'statusAccount': status_acc,
      'phoneNo': phoneNo,
      'profile': profileUrl,
      'vehicle_Registration': vehicleRegistration,
      'reportedProviderId': reportedProviderId,
      'reportsNum': reportsNum,
      'statusReport': status_report,
      'job_id': job_id,
      'userId': userId,
    };
  }

  // ฟังก์ชันสำหรับการแบนบัญชีผู้ใช้

  Future<void> _banAccount(BuildContext context, String providerId) async {
    try {
      final db = FirebaseFirestore.instance;

      // 1. ตรวจสอบข้อมูลผู้ให้บริการ
      final providerDoc = await db.collection('provider').doc(providerId).get();

      if (!providerDoc.exists) {
        throw Exception('ไม่พบข้อมูลผู้ให้บริการ');
      }

      final providerUid = providerDoc.data()?['provider_uid']?.toString();

      if (providerUid == null || providerUid.isEmpty) {
        throw Exception('ไม่พบ provider_uid ของผู้ให้บริการ');
      }

      // 2. ดึงใบสมัครที่มีสถานะ 0 และ 1
      final applications = await db
          .collection('all_drivers')
          .where('provider_id', isEqualTo: providerId)
          .where('status_drivers', whereIn: [0, 1])
          .get();

      int deletedApplications = 0;
      int cancelledJobs = 0;
      int protectedJobs = 0;

      // 3. จัดการใบสมัครและงานก่อนระงับบัญชี
      for (final application in applications.docs) {
        final data = application.data();
        final status = data['status_drivers'];
        final jobId = data['job_id']?.toString();

        // สถานะ 0: ลบใบสมัครที่รอพิจารณา
        if (status == 0) {
          await application.reference.delete();
          deletedApplications++;
          continue;
        }

        // จัดการเฉพาะสถานะ 1
        if (status != 1) continue;

        if (jobId == null || jobId.isEmpty) {
          // ไม่มี job_id จึงไม่เปลี่ยนสถานะใบสมัคร
          protectedJobs++;
          continue;
        }

        final jobRef = db.collection('jobs').doc(jobId);
        final jobDoc = await jobRef.get();

        if (!jobDoc.exists) {
          // ไม่พบงาน เก็บใบสมัครไว้เพื่อตรวจสอบภายหลัง
          protectedJobs++;
          continue;
        }

        final jobData = jobDoc.data()!;

        // 4. งานที่เหลือเวลาไม่เกิน 2 ชั่วโมง
        // หรือเริ่มงานแล้ว จะไม่ยกเลิก
        if (isWithinTwoHours(jobData)) {
          protectedJobs++;
          continue;
        }

        // 5. คืนงานเฉพาะงานที่ยังมีสถานะ 1
        if (jobData['job_status'] == 1) {
          await jobRef.update({'job_status': 0});

          await application.reference.update({'status_drivers': 6});
          // 3. ส่งแจ้งเตือนไปยังผู้รับบริการ ตรงนี้
          final serviceId = jobData['service_id']?.toString();

          if (serviceId != null && serviceId.isNotEmpty) {
            final serviceDoc = await db
                .collection('service')
                .doc(serviceId)
                .get();

            final receiverUid = serviceDoc.data()?['service_uid']?.toString();

            if (receiverUid != null && receiverUid.isNotEmpty) {
              await NotificationService().notifyReceiverProviderSuspended(
                jobId: jobId,
                userId: receiverUid,
              );
            }
          }

          cancelledJobs++;
        } else {
          // สถานะงานไม่ตรงตามที่คาดไว้ จึงไม่เปลี่ยนข้อมูล
          protectedJobs++;
        }
      }

      // 6. ระงับบัญชีหลังจัดการรายการเสร็จ
      await db.collection('users').doc(providerUid).update({
        'status_account': 4,
        'suspended_at': FieldValue.serverTimestamp(),
      });
      await NotificationService().notifyProviderAccountSuspended(
        userId: providerUid,
      );

      // 7. แจ้งผลลัพธ์
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ระงับบัญชีเรียบร้อยแล้ว\n'
              'ลบใบสมัครที่รอพิจารณา $deletedApplications รายการ\n'
              'คืนงาน $cancelledJobs รายการ\n'
              'เก็บงานไว้ตรวจสอบ $protectedJobs รายการ',
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการระงับบัญชี: $e')),
        );
      }
    }
  }

  bool isWithinTwoHours(Map<String, dynamic> jobData) {
    final dateValue = jobData['date']?.toString();
    final timeValue = jobData['start_time']?.toString();

    if (dateValue == null || timeValue == null) {
      return true; // ข้อมูลไม่ครบ ให้ป้องกันการคืนงานไว้ก่อน
    }

    try {
      // วันที่รูปแบบ dd/MM/yyyy เช่น 18/10/2026
      final dateParts = dateValue.split('/');
      final timeParts = timeValue.split(':');

      if (dateParts.length != 3 || timeParts.length < 2) {
        return true;
      }

      final day = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final year = int.parse(dateParts[2]);

      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      final startDateTime = DateTime(year, month, day, hour, minute);

      final remaining = startDateTime.difference(DateTime.now());

      // เหลือเวลา 0-120 นาที หรือเริ่มงานไปแล้ว
      return remaining <= const Duration(hours: 2);
    } catch (e) {
      print('แปลงวันเวลาไม่สำเร็จ: $e');
      return true;
    }
  }

  Future<void> providerWarning(
    BuildContext context,
    String jobId,
    String userId,
  ) async {
    try {
      await NotificationService().notifyProviderWarning(
        jobId: jobId,
        userId: userId,
      );

      // 4. แจ้งผลลัพธ์
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ตักเตือนและอัปเดตสถานะรายงานเรียบร้อยแล้ว'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการแบนบัญชี: $e')),
        );
      }
    }
  }

  Future<void> confirmReportReviewed(
    BuildContext context,
    String reportId,
  ) async {
    // ป้องกันกรณีไม่มี ID รายงาน
    if (reportId.isEmpty) return;

    // แสดงหน้าต่างยืนยัน
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.fact_check_outlined,
                color: Color(0xFF1976D2),
                size: 28,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ยืนยันผลการตรวจสอบ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: const Text(
            'คุณตรวจสอบรายงานนี้เรียบร้อยแล้วใช่หรือไม่?\n\n'
            'เมื่อยืนยัน รายงานจะเปลี่ยนสถานะเป็น "ตรวจสอบแล้ว"',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('ยืนยัน'),
            ),
          ],
        );
      },
    );

    if (confirm != true || !context.mounted) return;

    try {
      final reportRef = FirebaseFirestore.instance
          .collection('reports')
          .doc(reportId);

      // ตรวจสอบว่ารายงานมีอยู่จริงและยังรอตรวจสอบ
      final reportSnap = await reportRef.get();

      if (!reportSnap.exists) {
        throw Exception('ไม่พบข้อมูลรายงาน');
      }

      final reportData = reportSnap.data()!;

      if (reportData['status_re'] != 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('รายงานนี้ได้รับการตรวจสอบแล้ว')),
        );
        return;
      }

      // อัปเดตเฉพาะสถานะของรายงานนี้
      await reportRef.update({'status_re': 1});

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('บันทึกผลการตรวจสอบเรียบร้อยแล้ว'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('บันทึกผลการตรวจสอบไม่สำเร็จ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Padding(
          padding: EdgeInsets.only(left: 0),
          child: Text(
            "รายละเอียดการรายงาน",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 255, 0, 0),
      ),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: fetchReportDetails(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
            }

            final data = snapshot.data ?? {};
            final String profileUrl = data['profile'] ?? '';

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'รายงานพฤติกรรมคนขับ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 35),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // รูปโปรไฟล์
                      Container(
                        width: 55,
                        height: 55,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFF2F2F2),
                        ),
                        child: ClipOval(
                          child: profileUrl.isNotEmpty
                              ? Image.network(
                                  profileUrl, // เรียกใช้งาน profileUrl ตรงนี้
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                        Icons.person,
                                        size: 38,
                                        color: Colors.grey,
                                      ),
                                )
                              : const Icon(
                                  Icons.person,
                                  size: 38,
                                  color: Colors.grey,
                                ),
                        ),
                      ),

                      const SizedBox(width: 25),

                      // ข้อมูลคนขับ
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ชื่อ: ${data['driverName']}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color.fromARGB(255, 92, 89, 89),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'หมายเลขโทรศัพท์: ${data['phoneNo']}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color.fromARGB(255, 92, 89, 89),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'จำนวนการถูกรายงาน: ${data['reportsNum']}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color.fromARGB(255, 92, 89, 89),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: data['statusAccount'] == 1
                                    ? Colors.green.withOpacity(0.1)
                                    : data['statusAccount'] == 4
                                    ? Colors.red.withOpacity(0.1)
                                    : Colors.grey.withOpacity(
                                        0.1,
                                      ), // สีสำรองกรณีเป็นสถานะอื่น
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    data['statusAccount'] == 1
                                        ? Icons.check_circle
                                        : data['statusAccount'] == 4
                                        ? Icons.block
                                        : Icons.help_outline, // ไอคอนสำรอง
                                    size: 16,
                                    color: data['statusAccount'] == 1
                                        ? Colors.green
                                        : data['statusAccount'] == 4
                                        ? Colors.red.shade700
                                        : Colors.grey.shade700, // สีไอคอนสำรอง
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    data['statusAccount'] == 1
                                        ? "บัญชีใช้งานได้"
                                        : data['statusAccount'] == 4
                                        ? "บัญชีถูกระงับ"
                                        : "ไม่ทราบสถานะ", // ข้อความสำรอง
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: data['statusAccount'] == 1
                                          ? Colors.green
                                          : data['statusAccount'] == 4
                                          ? Colors.red.shade700
                                          : Colors
                                                .grey
                                                .shade700, // สีข้อความสำรอง
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 35),

                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Text(
                      'รายละเอียด',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // กล่องรายละเอียดรายงาน
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 74),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      data['description'] ?? '',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black,
                        height: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 42),

                  if (data['statusReport'] == 0) ...[
                    // 1. ปุ่มบันทึกผลการตรวจสอบ (Full Width)

                    // 2. แถวปุ่มตักเตือน และ ระงับบัญชี (แบ่งฝั่งละเท่าๆ กัน)
                    Row(
                      children: [
                        // --- ปุ่มตักเตือน ---
                        StatefulBuilder(
                          builder: (context, setButtonState) {
                            return Expanded(
                              child: SizedBox(
                                height: 44,
                                child: ElevatedButton.icon(
                                  onPressed: isWarning
                                      ? null
                                      : () async {
                                          final providerId =
                                              data['reportedProviderId'];

                                          if (providerId == null ||
                                              providerId.toString().isEmpty) {
                                            return;
                                          }

                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            barrierDismissible: false,
                                            builder: (dialogContext) {
                                              return AlertDialog(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                                title: const Row(
                                                  children: [
                                                    Icon(
                                                      Icons
                                                          .notifications_active_outlined,
                                                      color: Color.fromARGB(
                                                        255,
                                                        3,
                                                        164,
                                                        22,
                                                      ),
                                                      size: 26,
                                                    ),
                                                    SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        'ยืนยันการตักเตือน',
                                                        style: TextStyle(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                content: const Text(
                                                  'คุณต้องการส่งคำเตือนไปยังผู้ให้บริการรายนี้ใช่หรือไม่?\n\n'
                                                  'โปรดตรวจสอบข้อมูลรายงานก่อนยืนยันการตักเตือน',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(
                                                          dialogContext,
                                                        ).pop(false),
                                                    child: const Text(
                                                      'ยกเลิก',
                                                      style: TextStyle(
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () =>
                                                        Navigator.of(
                                                          dialogContext,
                                                        ).pop(true),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor:
                                                          const Color.fromARGB(
                                                            255,
                                                            3,
                                                            164,
                                                            22,
                                                          ),
                                                      foregroundColor:
                                                          Colors.white,
                                                    ),
                                                    child: const Text(
                                                      'ยืนยันการตักเตือน',
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          );

                                          if (confirm == true &&
                                              context.mounted) {
                                            await providerWarning(
                                              context,
                                              data['job_id'],
                                              data['userId'],
                                            );

                                            if (context.mounted) {
                                              setButtonState(() {
                                                isWarning = true;
                                              });
                                            }
                                          }
                                        },
                                  icon: Icon(
                                    isWarning
                                        ? Icons.check_circle
                                        : Icons.warning_amber_rounded,
                                    size: 18,
                                  ),
                                  label: Text(
                                    isWarning ? 'ตักเตือนแล้ว' : 'ตักเตือน',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isWarning
                                        ? Colors.grey
                                        : const Color.fromARGB(255, 3, 164, 22),
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: Colors.grey,
                                    disabledForegroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(width: 12),

                        // --- ปุ่มระงับบัญชี ---
                        StatefulBuilder(
                          builder: (context, setButtonState) {
                            return Expanded(
                              child: SizedBox(
                                height: 44,
                                child: ElevatedButton.icon(
                                  onPressed: isBanAccount
                                      ? null
                                      : () async {
                                          final providerId =
                                              data['reportedProviderId'];

                                          if (providerId == null ||
                                              providerId.toString().isEmpty) {
                                            return;
                                          }

                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            barrierDismissible: false,
                                            builder: (dialogContext) {
                                              return AlertDialog(
                                                title: const Text(
                                                  'ยืนยันการระงับบัญชี',
                                                ),
                                                content: const Text(
                                                  'คุณต้องการระงับบัญชีผู้ให้บริการรายนี้ใช่หรือไม่?',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                          dialogContext,
                                                          false,
                                                        ),
                                                    child: const Text('ยกเลิก'),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                          dialogContext,
                                                          true,
                                                        ),
                                                    child: const Text(
                                                      'ยืนยันการระงับ',
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          );

                                          if (confirm == true &&
                                              context.mounted) {
                                            await _banAccount(
                                              context,
                                              providerId,
                                            );

                                            // เปลี่ยนสถานะเฉพาะปุ่ม
                                            setButtonState(() {
                                              isBanAccount = true;
                                            });
                                          }
                                        },
                                  icon: Icon(
                                    isBanAccount
                                        ? Icons.check_circle
                                        : Icons.block,
                                    size: 18,
                                  ),
                                  label: Text(
                                    isBanAccount
                                        ? 'ระงับบัญชีแล้ว'
                                        : 'ระงับบัญชี',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isBanAccount
                                        ? Colors.grey
                                        : const Color(0xFFD32F2F),
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: Colors.grey,
                                    disabledForegroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          confirmReportReviewed(
                            context,
                            reportsId, // ID เอกสารใน Collection reports
                          );
                        },
                        icon: const Icon(Icons.fact_check_outlined, size: 20),
                        label: const Text(
                          'บันทึกผลการตรวจสอบ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1976D2),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],

                  if (data['statusReport'] == 1)
                    // ปุ่มแบนบัญชี
                    Center(
                      child: SizedBox(
                        width: 100,
                        height: 38,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(
                              255,
                              3,
                              164,
                              22,
                            ),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'ตรวจสอบแล้ว',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
