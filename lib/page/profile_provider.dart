import 'package:caremate_application/page/edit_profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileProvider extends StatefulWidget {
  final String sid;

  const ProfileProvider({super.key, this.sid = "naw5Oe3VyaVwj89isnzA"});

  @override
  State<ProfileProvider> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfileProvider> {
  String realname = '';
  String username = '';
  String? profileImage;
  String phone = '';
  String gender = '';

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData(); // ดึงข้อมูลจาก Firebase มาใส่ Controller ตอนเปิดหน้า
  }

  // ดึงข้อมูลครั้งแรกจาก Firebase
  Future<void> _fetchUserData() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('user')
          .doc(widget.sid)
          .get();

      DocumentSnapshot serviceDoc = await FirebaseFirestore.instance
          .collection('provider')
          .doc(widget.sid)
          .get();

      // เอาไว้ดูใน Console ว่าหาข้อมูลเจอไหม
      debugPrint('SID = ${widget.sid}');
      debugPrint('USER EXISTS = ${userDoc.exists}');
      debugPrint('USER DATA = ${userDoc.data()}');
      debugPrint('SERVICE EXISTS = ${serviceDoc.exists}');
      debugPrint('SERVICE DATA = ${serviceDoc.data()}');

      Map<String, dynamic> data = {};

      if (userDoc.exists && userDoc.data() != null) {
        data = userDoc.data() as Map<String, dynamic>;
      }

      Map<String, dynamic> providerData = {};

      if (serviceDoc.exists && serviceDoc.data() != null) {
        providerData = serviceDoc.data() as Map<String, dynamic>;
      }

      if (mounted) {
        setState(() {
          realname = data['realname'] ?? '';
          username = data['username'] ?? '';
          phone = providerData['phone'] ?? '';
          gender = providerData['gender'] ?? '';
          profileImage = providerData['profileImage']?.toString();

          isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint(' ERROR = $e');
      debugPrint(' STACK = $stackTrace');

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('โปรไฟล์', style: TextStyle(color: Colors.black)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: const [
                  BoxShadow(blurRadius: 3, color: Colors.black12),
                ],
              ),
              child: Stack(
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
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: Icon(Icons.edit_square, color: Colors.black),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Card(
              color: const Color.fromARGB(255, 255, 253, 253),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ProfileRow(title: 'ชื่อ:', value: realname),
                    Divider(),
                    ProfileRow(title: 'ชื่อผู้ใช้:', value: username),
                    Divider(),
                    ProfileRow(title: 'เพศ:', value: gender),
                    Divider(),
                    ProfileRow(title: 'โทรศัพท์:', value: phone),
                    Divider(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfileProvider(sid: widget.sid),
                  ),
                );

                // กลับมาจากหน้าแก้ไขแล้ว
                if (result == true) {
                  await _fetchUserData();
                }
              },
              icon: const Icon(Icons.edit, color: Colors.white),
              label: const Text(
                'แก้ไขข้อมูล',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileRow extends StatelessWidget {
  final String title;
  final String value;

  const ProfileRow({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(title, style: const TextStyle(fontSize: 18)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
