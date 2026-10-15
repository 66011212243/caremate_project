import 'package:caremate_application/page/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ReportDetailPage extends StatelessWidget {
  final String reportsId; // ส่ง reportId มาจากหน้าก่อนหน้า

  const ReportDetailPage({super.key, required this.reportsId});

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
          }
        }
      }
    }

    return {
      'description': description,
      'driverName': driverName,
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

      // 1. ดึง provider_uid เพื่อไประงับบัญชีใน collection users
      final providerDoc = await db.collection('provider').doc(providerId).get();

      if (!providerDoc.exists) {
        throw Exception('ไม่พบข้อมูลผู้ให้บริการ');
      }

      final providerUid = providerDoc.data()?['provider_uid']?.toString();

      if (providerUid == null || providerUid.isEmpty) {
        throw Exception('ไม่พบ provider_uid ของผู้ให้บริการ');
      }

      // 2. อัปเดตสถานะบัญชีเป็น 4 (ถูกระงับ)
      await db.collection('users').doc(providerUid).update({
        'status_account': 4,
      });

      // 3. อัปเดตสถานะรายงานเป็น 1 (ดำเนินการแล้ว)
      await db.collection('reports').doc(reportsId).update({'status_re': 1});

      // 4. แจ้งผลลัพธ์
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ระงับบัญชีและอัปเดตสถานะรายงานเรียบร้อยแล้ว'),
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการแบนบัญชี: $e')),
        );
      }
    }
  }

  Future<void> providerWarning(
    BuildContext context,
    String jobId,
    String userId,
  ) async {
    try {
      final db = FirebaseFirestore.instance;
      await NotificationService().notifyProviderWarning(
        jobId: jobId,
        userId: userId,
      );

      // 3. อัปเดตสถานะรายงานเป็น 1 (ดำเนินการแล้ว)
      await db.collection('reports').doc(reportsId).update({'status_re': 1});

      // 4. แจ้งผลลัพธ์
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ตักเตือนและอัปเดตสถานะรายงานเรียบร้อยแล้ว'),
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการแบนบัญชี: $e')),
        );
      }
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

                  if (data['statusReport'] == 0)
                    // ปุ่มแบนบัญชี
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 60),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 100,
                            height: 38,
                            child: ElevatedButton(
                              onPressed: () async {
                                final providerId = data['reportedProviderId'];

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
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      title: const Row(
                                        children: [
                                          Icon(
                                            Icons.notifications_active_outlined,
                                            color: Color.fromARGB(
                                              255,
                                              3,
                                              164,
                                              22,
                                            ),
                                            size: 28,
                                          ),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'ยืนยันการตักเตือน',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      content: const Text(
                                        'คุณต้องการส่งคำเตือนไปยังผู้ให้บริการรายนี้ใช่หรือไม่?\n\n'
                                        'โปรดตรวจสอบข้อมูลรายงานก่อนยืนยันการตักเตือน',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(
                                              dialogContext,
                                            ).pop(false);
                                          },
                                          child: const Text(
                                            'ยกเลิก',
                                            style: TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.of(
                                              dialogContext,
                                            ).pop(true);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color.fromARGB(
                                                  255,
                                                  3,
                                                  164,
                                                  22,
                                                ),
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: const Text(
                                            'ยืนยันการตักเตือน',
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );

                                if (confirm == true && context.mounted) {
                                  await providerWarning(
                                    context,
                                    data['job_id'],
                                    data['userId'],
                                  );
                                }
                              },
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
                                'ตักเตือน',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 20),

                          SizedBox(
                            width: 100,
                            height: 38,
                            child: ElevatedButton(
                              onPressed: () async {
                                final providerId = data['reportedProviderId'];

                                if (providerId == null ||
                                    providerId.toString().isEmpty) {
                                  return;
                                }

                                // แสดงไดอาลอคยืนยัน
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
                                            Icons.warning_amber_rounded,
                                            color: Colors.red,
                                            size: 28,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'ยืนยันการระงับบัญชี',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      content: const Text(
                                        'คุณต้องการแบนบัญชีผู้ให้บริการรายนี้ใช่หรือไม่?\n\n'
                                        'เมื่อยืนยันแล้ว บัญชีอาจไม่สามารถใช้บริการได้ '
                                        'โปรดตรวจสอบข้อมูลก่อนดำเนินการ',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(
                                              dialogContext,
                                            ).pop(false);
                                          },
                                          child: const Text(
                                            'ยกเลิก',
                                            style: TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.of(
                                              dialogContext,
                                            ).pop(true);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: const Text('ยืนยันการแบน'),
                                        ),
                                      ],
                                    );
                                  },
                                );

                                // เรียกฟังก์ชันแบนเมื่อกดยืนยันเท่านั้น
                                if (confirm == true && context.mounted) {
                                  await _banAccount(context, providerId);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'ระงับบัญชี',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

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
