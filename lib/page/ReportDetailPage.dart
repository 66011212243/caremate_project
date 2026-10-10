import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ReportDetailPage extends StatelessWidget {
  final String reports_id; // ส่ง reportId มาจากหน้าก่อนหน้า

  const ReportDetailPage({super.key, required this.reports_id});

  // ฟังก์ชันดึงข้อมูลรายละเอียดรายงาน และข้อมูล Provider / User ที่ถูกรายงาน
  Future<Map<String, dynamic>> fetchReportDetails() async {
    final db = FirebaseFirestore.instance;

    // 1. ดึงข้อมูลจากคอลเลกชัน reports
    final reportDoc = await db.collection('reports').doc(reports_id).get();
    if (!reportDoc.exists) {
      throw Exception('ไม่พบข้อมูลการรายงาน');
    }

    final reportData = reportDoc.data()!;
    final description = reportData['description'] ?? 'ไม่มีรายละเอียด';

    // ดึง ID ของ Provider ที่ถูกรายงาน (หรือ reporter_id ของผู้รายงาน)
    final reportedProviderId =
        (reportData['reported_provider_id'])?.toString() ?? '';
    '';

    String driverName = 'ไม่ระบุชื่อ';
    String phoneNo = 'ไม่ระบุเบอร์โทรศัพท์';
    String vehicleRegistration = 'ไม่ระบุทะเบียนรถ';
    String profileUrl = '';

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
        profileUrl = providerData['photo']?.toString() ?? '';

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
            driverName = userData['username']?.toString() ?? 'ไม่ระบุชื่อ';
          }
        }

        // 4. ดึงข้อมูลทะเบียนรถจาก document
        var docSnap = await db
            .collection('document')
            .where('pid', isEqualTo: reportedProviderId)
            .limit(1)
            .get();

        if (docSnap.docs.isEmpty) {
          docSnap = await db
              .collection('document')
              .where('provider_id', isEqualTo: reportedProviderId)
              .limit(1)
              .get();
        }

        if (docSnap.docs.isNotEmpty) {
          final docData = docSnap.docs.first.data();
          vehicleRegistration =
              docData['vehicle_Registration']?.toString() ?? 'ไม่ระบุทะเบียนรถ';

        }
      }
    }

    return {
      'description': description,
      'driverName': driverName,
      'phoneNo': phoneNo,
      'photo': profileUrl,
      'vehicle_Registration': vehicleRegistration,
      'reportedProviderId': reportedProviderId,
    };
  }

  // ฟังก์ชันสำหรับการแบนบัญชีผู้ใช้
  Future<void> _banAccount(BuildContext context, String providerId) async {
    try {
      final db = FirebaseFirestore.instance;

      // ดึง provider_uid เพื่อไประงับบัญชีใน collection users
      final providerDoc = await db.collection('provider').doc(providerId).get();
      if (providerDoc.exists) {
        final providerUid = providerDoc.data()?['provider_uid']?.toString();
        if (providerUid != null && providerUid.isNotEmpty) {
          await db.collection('users').doc(providerUid).update({
            'status_account': 'banned', // ปรับเปลี่ยนสถานะตามที่ระบบใช้จริง
          });
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ทำการแบนบัญชีเรียบร้อยแล้ว')),
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
            "Admin",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 255, 0, 0),
        toolbarHeight: 90,
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
            final String profileUrl = data['photoUrl'] ?? '';

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
                              'ทะเบียนรถ: ${data['vehicle_Registration']}',
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

                  // ปุ่มแบนบัญชี
                  Center(
                    child: SizedBox(
                      width: 100,
                      height: 38,
                      child: ElevatedButton(
                        onPressed: () {
                          if (data['reportedProviderId'] != null) {
                            _banAccount(context, data['reportedProviderId']);
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
                          'แบนบัญชี',
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
