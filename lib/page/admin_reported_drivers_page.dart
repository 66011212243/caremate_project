import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminReportedDriversPage extends StatefulWidget {
  // กำหนดค่าไว้สำหรับทดสอบหน้าแยก
  final String reports_id;

  const AdminReportedDriversPage({super.key, required this.reports_id});

  @override
  State<AdminReportedDriversPage> createState() =>
      _AdminReportedDriversPageState();
}

class _AdminReportedDriversPageState extends State<AdminReportedDriversPage> {
  bool isLoading = true;
  String? errorMessage;

  List<Map<String, dynamic>> reportedDrivers = [];

  @override
  void initState() {
    super.initState();
    fetchReportedDrivers();
  }

  // ดึงรายชื่อคนขับที่ถูกรายงาน
  Future<void> fetchReportedDrivers() async {
    try {
      final db = FirebaseFirestore.instance;

      // 1. ดึงข้อมูลจาก review
      // สมมติว่า review แต่ละเอกสารมี pid ของคนขับ
      final reviewSnapshot = await db.collection('review').get();

      final List<Map<String, dynamic>> result = [];
      final Set<String> addedPids = {};

      for (final reviewDoc in reviewSnapshot.docs) {
        final reviewData = reviewDoc.data();

        // 2. ดึง pid ของคนขับจาก review
        final pid = reviewData['reported_provider_id']?.toString() ?? '';

        if (pid.isEmpty) {
          continue;
        }

        // ไม่ให้แสดงคนขับซ้ำ
        if (!addedPids.add(pid)) {
          continue;
        }

        // 3. ค้นหา provider ด้วย pid
        // กรณี Document ID ของ provider เท่ากับ pid
        DocumentSnapshot<Map<String, dynamic>> providerDoc = await db
            .collection('provider')
            .doc(pid)
            .get();

        // ถ้า Document ID ไม่ใช่ pid ให้ลองค้นจากฟิลด์ pid
        if (!providerDoc.exists) {
          final providerQuery = await db
              .collection('provider')
              .where('provider_id', isEqualTo: pid)
              .limit(1)
              .get();

          if (providerQuery.docs.isNotEmpty) {
            providerDoc = providerQuery.docs.first;
          }
        }

        if (!providerDoc.exists) {
          debugPrint('ไม่พบ provider ของ pid: $pid');
          continue;
        }

        final providerData = providerDoc.data()!;

        // 4. ดึง uid จาก provider
        final uid =
            (providerData['uid'] ?? providerData['provider_uid'])?.toString() ??
            '';

        if (uid.isEmpty) {
          debugPrint('ไม่พบ uid ของ pid: $pid');
          continue;
        }

        // 5. ค้นหาข้อมูล users ด้วย uid
        DocumentSnapshot<Map<String, dynamic>> userDoc = await db
            .collection('users')
            .doc(uid)
            .get();

        // ถ้า Document ID ไม่ใช่ uid ให้ค้นจากฟิลด์ uid
        if (!userDoc.exists) {
          final userQuery = await db
              .collection('users')
              .where('uid', isEqualTo: uid)
              .limit(1)
              .get();

          if (userQuery.docs.isNotEmpty) {
            userDoc = userQuery.docs.first;
          }
        }

        if (!userDoc.exists) {
          debugPrint('ไม่พบ users ของ uid: $uid');
          continue;
        }

        final userData = userDoc.data()!;

        // 6. ดึงชื่อคนขับจาก users
        final name =
            (userData['username'] ??
                    userData['realname'] ??
                    userData['fullname'] ??
                    'ไม่ระบุชื่อ')
                .toString();

        result.add({
          'pid': pid,
          'uid': uid,
          'name': name,
          'review_id': reviewDoc.id,
        });
      }

      if (!mounted) return;

      setState(() {
        reportedDrivers = result;
        isLoading = false;
        errorMessage = null;
      });
    } catch (e, stackTrace) {
      debugPrint('เกิดข้อผิดพลาดในการโหลดรายชื่อ: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  // แสดงรายละเอียดเมื่อกดรายชื่อ
  void showDriverDetails(Map<String, dynamic> driver) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ข้อมูลคนขับที่ถูกรายงาน'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ชื่อ: ${driver['name']}'),
              const SizedBox(height: 8),
              Text('PID: ${driver['pid']}'),
              const SizedBox(height: 8),
              Text('UID: ${driver['uid']}'),
              const SizedBox(height: 8),
              Text('Review ID: ${driver['review_id']}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ปิด'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        automaticallyImplyLeading: true,
        title: const Text(
          'รายชื่อคนขับที่ถูกรายงาน',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() {
                isLoading = true;
                errorMessage = null;
              });
              fetchReportedDrivers();
            },
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'หน้าหลัก',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            label: 'ปฏิทิน',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none),
            label: 'ข้อความ',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'ตั้งค่า'),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              const Text(
                'โหลดรายชื่อไม่สำเร็จ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    isLoading = true;
                    errorMessage = null;
                  });
                  fetchReportedDrivers();
                },
                child: const Text('ลองอีกครั้ง'),
              ),
            ],
          ),
        ),
      );
    }

    if (reportedDrivers.isEmpty) {
      return const Center(
        child: Text('ไม่พบรายชื่อคนขับ', style: TextStyle(fontSize: 16)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: reportedDrivers.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final driver = reportedDrivers[index];

        return ListTile(
          leading: const CircleAvatar(
            backgroundColor: Colors.red,
            child: Icon(Icons.person, color: Colors.white),
          ),
          title: Text(
            driver['name'].toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text('PID: ${driver['pid']}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showDriverDetails(driver),
        );
      },
    );
  }
}
