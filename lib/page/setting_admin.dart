import 'package:caremate_application/page/Bank.dart';
import 'package:caremate_application/page/Changepassword.dart';
import 'package:caremate_application/page/admin_all_report.dart';
import 'package:caremate_application/page/admin_price_page.dart';
import 'package:caremate_application/page/admin_verify.dart';
import 'package:caremate_application/page/app_session.dart';
import 'package:caremate_application/page/document.dart';
import 'package:caremate_application/page/driver_pending_approval_page.dart';
import 'package:caremate_application/page/login.dart';
import 'package:caremate_application/page/notification_system.dart';
import 'package:caremate_application/page/profile_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SettingAdmin extends StatefulWidget {
  final String uid;

  const SettingAdmin({super.key, required this.uid});

  @override
  State<SettingAdmin> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingAdmin> {
  String realname = '';
  String email = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAdminData(); // ดึงข้อมูลจาก Firebase มาใส่ Controller ตอนเปิดหน้า
  }

  // ดึงข้อมูลครั้งแรกจาก Firebase
  Future<void> _fetchAdminData() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .get();

      if (mounted) {
        setState(() {
          if (userDoc.exists && userDoc.data() != null) {
            final userData = userDoc.data() as Map<String, dynamic>;
            realname = userData['realname']?.toString() ?? 'ผู้ดูแลระบบ';
            email = userData['email']?.toString() ?? 'ผู้ดูแลระบบ';
            print(realname);
            print(email);
          }
          isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('ERROR: $e');
      debugPrint('STACK: $stackTrace');

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.red,
        title: const Text('การตั้งค่า', style: TextStyle(color: Colors.white)),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      child: const Icon(Icons.person, size: 28),
                    ),
                    SizedBox(width: 20),
                    Expanded(
                      child: isLoading
                          ? const Text('กำลังโหลด...')
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  realname,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  email,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            buildMenu(
              'คำร้อง',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DriverPendingApprovalPage(),
                  ),
                );
              },
            ),
            const Divider(color: Colors.grey, thickness: 1, height: 30),
            buildMenu(
              'รายงานทั้งหมด',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AdminAllReport()),
                );
              },
            ),
            const Divider(color: Colors.grey, thickness: 1, height: 30),
            buildMenu(
              'ตรวจสอบ',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AdminVerify()),
                );
              },
            ),
            const Divider(color: Colors.grey, thickness: 1, height: 30),
            buildMenu(
              'อัตราค่าบริการ',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AdminPricePage()),
                );
              },
            ),
            const Divider(color: Colors.grey, thickness: 1, height: 30),
            buildMenu(
              'เปลี่ยนรหัสผ่าน',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ChangepasswordPage(userId: widget.uid),
                  ),
                );
              },
            ),
            const Divider(color: Colors.grey, thickness: 1, height: 30),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () async {
                  await NotificationSystem().removeToken(widget.uid);
                  await GoogleSignIn().signOut();
                  await FirebaseAuth.instance.signOut();
                  await AppSession.clear();

                  if (!context.mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (route) => false,
                  );
                },
                child: const Text(
                  'ออกจากระบบ',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildMenu(String title, {VoidCallback? onTap}) {
    return ListTile(
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap, // ใส่ onTap ตรงนี้
    );
  }
}
