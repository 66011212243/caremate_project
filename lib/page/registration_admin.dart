import 'package:caremate_application/page/Bank.dart';
import 'package:caremate_application/page/Changepassword.dart';
import 'package:caremate_application/page/document.dart';
import 'package:caremate_application/page/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegistrationAdmin extends StatefulWidget {
  final String sid;

  const RegistrationAdmin({super.key, this.sid = "9XfrEZu1OD6sqiAsjLBj"});

  @override
  State<RegistrationAdmin> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<RegistrationAdmin> {
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
        title: const Text('เอกสารขอลงทะเบียน', style: TextStyle(color: Colors.white)),
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

            const SizedBox(height: 20),
            buildMenu(
              'มัลลิกา',
              onTap: () {
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(builder: (context) => const JobHistoryPage()),
                // );
              },
            ),
            const Divider(color: Colors.grey, thickness: 1, height: 30),
            buildMenu(
              'มัลลิกา',
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
              'มัลลิกา',
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
              'พิชชาภรณ์',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) =>  ChangepasswordPage(sid: widget.sid,)),
                );
              },
            ),
            const Divider(color: Colors.grey, thickness: 1, height: 30),
            
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
