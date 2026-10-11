import 'package:caremate_application/page/edit_profile_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileService extends StatefulWidget {
  final String sid;

  const ProfileService({super.key, required this.sid});

  @override
  State<ProfileService> createState() => _ProfileServiceState();
}

class _ProfileServiceState extends State<ProfileService> {
  String realname = '';
  String username = '';
  String? profileImage;
  String phone = '';
  String? selectedGender; // '0' = ชาย, '1' = หญิง

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  String _genderText(String? g) {
    switch (g) {
      case '0':
        return 'ชาย';
      case '1':
        return 'หญิง';
      default:
        return 'ไม่ระบุ';
    }
  }

  // ดึงข้อมูลจาก Firebase
  Future<void> _fetchUserData() async {
    if (mounted) setState(() => isLoading = true);

    try {
      // 1. ดึง provider ด้วย sid
      final serviceDoc = await FirebaseFirestore.instance
          .collection('service')
          .doc(widget.sid)
          .get();

      debugPrint('PID = ${widget.sid}');
      debugPrint('PROVIDER EXISTS = ${serviceDoc.exists}');
      debugPrint('PROVIDER DATA = ${serviceDoc.data()}');

      if (!serviceDoc.exists || serviceDoc.data() == null) {
        debugPrint('ไม่พบข้อมูล provider');
        if (mounted) setState(() => isLoading = false);
        return;
      }

      final serviceData = serviceDoc.data() as Map<String, dynamic>;

      // 2. ดึง provider_uid
      final providerUid = serviceData['service_uid']?.toString() ?? '';
      debugPrint('SERVICE UID = $providerUid');

      Map<String, dynamic> userData = {};

      // 3. ดึงข้อมูลจาก users
      if (providerUid.isNotEmpty) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(providerUid)
            .get();

        debugPrint('USER EXISTS = ${userDoc.exists}');
        debugPrint('USER DATA = ${userDoc.data()}');

        if (userDoc.exists && userDoc.data() != null) {
          userData = userDoc.data() as Map<String, dynamic>;
        }
      } else {
        debugPrint('ไม่พบ provider_uid ใน provider');
      }

      // 4. เตรียมค่าเพศ (รองรับ int / String)
      final rawGender = serviceData['gender'];
      String? genderValue;
      if (rawGender == 0 || rawGender == '0') {
        genderValue = '0';
      } else if (rawGender == 1 || rawGender == '1') {
        genderValue = '1';
      }

      // 5. รูปโปรไฟล์: ใช้ 'profile' เป็นหลัก, 'profileImage' เป็นตัวสำรอง
      final image =
          (serviceData['profile'] ?? serviceData['profileImage'])
              ?.toString()
              .trim();

      debugPrint('PROFILE IMAGE = $image');

      if (mounted) {
        setState(() {
          realname = userData['realname']?.toString() ?? '';
          username = userData['username']?.toString() ?? '';
          phone = serviceData['phone']?.toString() ?? '';
          selectedGender = genderValue;
          profileImage = image;
          isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('ERROR = $e');
      debugPrint('STACK = $stackTrace');
      if (mounted) setState(() => isLoading = false);
    }
  }

  Widget _buildProfileImage() {
    final hasImage = profileImage != null && profileImage!.isNotEmpty;

    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade200,
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: const [
                BoxShadow(blurRadius: 3, color: Colors.black12),
              ],
            ),
            child: ClipOval(
              child: hasImage
                  ? Image.network(
                      profileImage!,
                      width: 140,
                      height: 140,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint('IMAGE ERROR = $error');
                        return const Icon(
                          Icons.person,
                          size: 70,
                          color: Colors.grey,
                        );
                      },
                    )
                  : const Icon(Icons.person, size: 70, color: Colors.grey),
            ),
          ),
          const Positioned(
            right: 4,
            bottom: 4,
            child: Icon(Icons.edit_square, color: Colors.black),
          ),
        ],
      ),
    );
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildProfileImage(),
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
                            const Divider(),
                            ProfileRow(title: 'ชื่อผู้ใช้:', value: username),
                            const Divider(),
                            ProfileRow(
                              title: 'เพศ:',
                              value: _genderText(selectedGender),
                            ),
                            const Divider(),
                            ProfileRow(title: 'โทรศัพท์:', value: phone),
                            const Divider(),
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
                            builder: (context) =>
                                EditProfileService(sid: widget.sid),
                          ),
                        );

                        // กลับมาจากหน้าแก้ไขแล้ว โหลดข้อมูลใหม่
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
              value.isEmpty ? '-' : value,
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}