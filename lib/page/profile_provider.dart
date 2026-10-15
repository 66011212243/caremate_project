import 'package:caremate_application/page/edit_profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileProvider extends StatefulWidget {
  final String pid;

  const ProfileProvider({super.key, required this.pid});

  @override
  State<ProfileProvider> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfileProvider> {
  String realname = '';
  String username = '';
  String? profileImage;
  String phone = '';
  String? selectedGender; // '0' = ชาย, '1' = หญิง
  double averageRating = 0.0;

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
    if (mounted) {
      setState(() => isLoading = true);
    }

    try {
      // 1. ดึงข้อมูล provider ด้วย pid
      final providerDoc = await FirebaseFirestore.instance
          .collection('provider')
          .doc(widget.pid)
          .get();

      if (!providerDoc.exists || providerDoc.data() == null) {
        debugPrint('ไม่พบข้อมูล provider');

        if (mounted) {
          setState(() => isLoading = false);
        }
        return;
      }

      final providerData = providerDoc.data()!;

      // 2. ดึง provider_uid
      final providerUid = providerData['provider_uid']?.toString() ?? '';

      // 3. ดึงข้อมูลจาก users
      Map<String, dynamic> userData = {};

      if (providerUid.isNotEmpty) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(providerUid)
            .get();

        if (userDoc.exists && userDoc.data() != null) {
          userData = userDoc.data()!;
        }
      }

      // 4. เตรียมค่าเพศ
      final rawGender = providerData['gender'];
      String? genderValue;

      if (rawGender == 0 || rawGender == '0') {
        genderValue = '0';
      } else if (rawGender == 1 || rawGender == '1') {
        genderValue = '1';
      }

      // 5. ดึงรูปโปรไฟล์
      final image = (providerData['profile'] ?? providerData['profileImage'])
          ?.toString()
          .trim();

      // 6. ดึงคะแนนดาวเฉลี่ยด้วย pid
      final rating = await queryProviderRatings(widget.pid);

      // 7. อัปเดตข้อมูลทั้งหมด
      if (mounted) {
        setState(() {
          realname = userData['realname']?.toString() ?? '';
          username = userData['username']?.toString() ?? '';
          phone = providerData['phone']?.toString() ?? '';
          selectedGender = genderValue;
          profileImage = image;
          averageRating = rating;
          isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('ERROR = $e');
      debugPrint('STACK = $stackTrace');

      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<double> queryProviderRatings(String providerId) async {
    var ratingsSnapshot = await FirebaseFirestore.instance
        .collection('review')
        .where('provider_id', isEqualTo: providerId)
        .get();

    if (ratingsSnapshot.docs.isEmpty) {
      return 0.0;
    }

    double totalRating = 0.0;
    int reviewCount = 0;

    for (var doc in ratingsSnapshot.docs) {
      var data = doc.data();
      var rating = data['rating'];

      if (rating != null) {
        totalRating += (rating as num).toDouble();
        reviewCount++;
      }
    }

    if (reviewCount == 0) {
      return 0.0;
    }

    double averageRating = totalRating / reviewCount;

    print('provider_id: $providerId');
    print('จำนวนรีวิว: $reviewCount');
    print('คะแนนเฉลี่ย: $averageRating');

    return averageRating;
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
                        return const Center(child: CircularProgressIndicator());
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
                    const SizedBox(height: 20),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 24),
                          const SizedBox(width: 4),
                          Text(
                            averageRating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
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
                                EditProfileProvider(pid: widget.pid),
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
