import 'package:caremate_application/page/Bank.dart';
import 'package:caremate_application/page/Changepassword.dart';
import 'package:caremate_application/page/app_session.dart';
import 'package:caremate_application/page/document.dart';
import 'package:caremate_application/page/history_job_provider.dart';
import 'package:caremate_application/page/login.dart';
import 'package:caremate_application/page/notification_system.dart';
import 'package:caremate_application/page/profile_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SettingsProvider extends StatefulWidget {
  final String pid;

  const SettingsProvider({super.key, required this.pid});

  @override
  State<SettingsProvider> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsProvider> {
  String realname = '';
  String? profileImage;
  bool isLoading = true;
  String uid = '';

  @override
  void initState() {
    super.initState();
    _fetchUserData(); // ดึงข้อมูลจาก Firebase มาใส่ Controller ตอนเปิดหน้า
  }

  // ดึงข้อมูลครั้งแรกจาก Firebase
  Future<void> _fetchUserData() async {
    try {
      // 1. ใช้ pid ค้นหา provider ก่อน
      DocumentSnapshot providerDoc = await FirebaseFirestore.instance
          .collection('provider')
          .doc(widget.pid)
          .get();

      debugPrint('PID = ${widget.pid}');
      debugPrint('PROVIDER EXISTS = ${providerDoc.exists}');
      debugPrint('PROVIDER DATA = ${providerDoc.data()}');

      if (!providerDoc.exists || providerDoc.data() == null) {
        debugPrint('ไม่พบข้อมูล provider');

        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
        return;
      }

      // 2. ดึง provider_uid จาก provider
      Map<String, dynamic> providerData =
          providerDoc.data() as Map<String, dynamic>;

      String providerUid = providerData['provider_uid']?.toString() ?? '';

      debugPrint('PROVIDER UID = $providerUid');

      if (providerUid.isEmpty) {
        debugPrint('ไม่พบ provider_uid ใน provider');

        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
        return;
      }

      // 3. ใช้ provider_uid ไปค้น users
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(providerUid)
          .get();

      debugPrint('USER EXISTS = ${userDoc.exists}');
      debugPrint('USER DATA = ${userDoc.data()}');

      Map<String, dynamic> userData = {};

      if (userDoc.exists && userDoc.data() != null) {
        userData = userDoc.data() as Map<String, dynamic>;
      }

      // 4. เอาข้อมูลไปแสดง
      if (mounted) {
        setState(() {
          uid = providerUid;
          realname = userData['realname'] ?? '';

          profileImage = providerData['profile']?.toString();

          isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('ERROR = $e');
      debugPrint('STACK = $stackTrace');

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
                      backgroundImage:
                          profileImage != null && profileImage!.isNotEmpty
                          ? NetworkImage(profileImage!)
                          : null,
                      child: profileImage == null || profileImage!.isEmpty
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: isLoading
                          ? const Text('กำลังโหลด...')
                          : Text(
                              realname,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ProfileProvider(pid: widget.pid),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'โปรไฟล์',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            buildMenu(
              'ประวัติการทำงาน',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HistoryJobProvider(pid: widget.pid),
                  ),
                );
              },
            ),
            const Divider(color: Colors.grey, thickness: 1, height: 30),
            buildMenu(
              'เอกสารที่เกี่ยวข้อง',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DocumentPage(pid: widget.pid),
                  ),
                );
              },
            ),
            const Divider(color: Colors.grey, thickness: 1, height: 30),
            buildMenu(
              'บัญชีธนาคาร',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BankPage(pid: widget.pid),
                  ),
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
                    builder: (context) => ChangepasswordPage(userId: uid),
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
                  await NotificationSystem().removeToken(uid);
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
