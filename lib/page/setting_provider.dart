import 'package:caremate_application/page/Bank.dart';
import 'package:caremate_application/page/Changepassword.dart';
import 'package:caremate_application/page/document.dart';
import 'package:caremate_application/page/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsProvider extends StatefulWidget {
  final String sid;

  const SettingsProvider({super.key, this.sid = "9XfrEZu1OD6sqiAsjLBj"});

  @override
  State<SettingsProvider> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsProvider> {
  String realname = '';
  String? profileImage;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData(); // ดึงข้อมูลจาก Firebase มาใส่ Controller ตอนเปิดหน้า
  }

  // ดึงข้อมูลครั้งแรกจาก Firebase
  Future<void> _fetchUserData() async {
  try {
    final userDoc = await FirebaseFirestore.instance
        .collection('user')
        .doc(widget.sid)
        .get();

    debugPrint('USER EXISTS: ${userDoc.exists}');
    debugPrint('USER DATA: ${userDoc.data()}');

    final serviceDoc = await FirebaseFirestore.instance
        .collection('service')
        .doc(widget.sid)
        .get();

    debugPrint('SERVICE EXISTS: ${serviceDoc.exists}');
    debugPrint('SERVICE DATA: ${serviceDoc.data()}');

    if (mounted) {
      setState(() {
        if (userDoc.exists && userDoc.data() != null) {
          final userData = userDoc.data() as Map<String, dynamic>;
          realname = userData['realname']?.toString() ?? '';
        }

        if (serviceDoc.exists && serviceDoc.data() != null) {
          final serviceData =
              serviceDoc.data() as Map<String, dynamic>;
          profileImage = serviceData['profileImage']?.toString();
        }

        isLoading = false;
      });
    }
  } catch (e, stackTrace) {
    debugPrint(' ERROR: $e');
    debugPrint(' STACK: $stackTrace');

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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3, // ตอนนี้อยู่หน้า "ตั้งค่า"
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
                            builder: (context) => ProfileProvider(sid: widget.sid),
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
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(builder: (context) => const JobHistoryPage()),
                // );
              },
            ),
            const Divider(color: Colors.grey, thickness: 1, height: 30),
            buildMenu(
              'เอกสารที่เกี่ยวข้อง',
              onTap: () {
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder: (context) => const DocumentPage(),
                //   ),
                // );
              },
            ),
            const Divider(color: Colors.grey, thickness: 1, height: 30),
            buildMenu(
              'บัญชีธนาคาร',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BankPage(),
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
                  MaterialPageRoute(builder: (context) =>  ChangepasswordPage(sid: widget.sid,)),
                );
              },
            ),
            const Divider(color: Colors.grey, thickness: 1, height: 30),
            buildMenu(
              'วิธีการใช้งาน',
              onTap: () {
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder: (context) => const RegisterProvider(),
                //   ),
                // );
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
                onPressed: () {},
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
