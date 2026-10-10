import 'package:caremate_application/page/approve_provider.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DriverPendingApprovalPage extends StatelessWidget {
  final String uid;
  const DriverPendingApprovalPage({
    super.key,
    this.uid = 'arXBJKmqJjrpARdjZ5Lp',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'เอกสารขอลงทะเบียน',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.red,
      ),
      body: const UserList(role: 1), // role = 1 สำหรับ Provider/คนขับ
    );
  }
}

class UserList extends StatelessWidget {
  final int role;

  const UserList({super.key, required this.role});

  /// ฟังก์ชันสำหรับดึง pid และ profile image จาก collection 'provider'
  Future<Map<String, String?>> getProviderData(String uid) async {
    final db = FirebaseFirestore.instance;

    final providerSnap = await db
        .collection('provider')
        .where('provider_uid', isEqualTo: uid)
        .limit(1)
        .get();

    if (providerSnap.docs.isNotEmpty) {
      final doc = providerSnap.docs.first;
      final data = doc.data();

      // ดึง pid (อาจเป็น document ID หรือ ฟิลด์ 'pid')
      final pid = data['pid']?.toString() ?? doc.id;
      final profile = data['profile']?.toString();

      return {
        'pid': pid,
        'profile': profile,
      };
    }

    return {'pid': null, 'profile': null};
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      // กรอง role เท่ากับ 1 และ status_account เท่ากับ 2 (รออนุมัติ)
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: role)
          .where('status_account', isEqualTo: 2) 
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
        }

        final users = snapshot.data?.docs ?? [];
        if (users.isEmpty) {
          return const Center(
            child: Text(
              'ไม่พบคำขอลงทะเบียนที่รออนุมัติ',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: users.length,
          separatorBuilder: (context, index) => const Divider(
            height: 1,
            thickness: 0.8,
            color: Color(0xFFE0E0E0),
          ),
          itemBuilder: (context, index) {
            final userDoc = users[index];
            final data = userDoc.data();
            final uid = userDoc.id; // uid จากคอลเลกชัน users

            final name = data['realname']?.toString() ??
                data['name']?.toString() ??
                'ไม่ระบุชื่อ';

            final username = data['username']?.toString() ?? '';

            return FutureBuilder<Map<String, String?>>(
              future: getProviderData(uid),
              builder: (context, providerSnapshot) {
                final providerData = providerSnapshot.data;
                final imageUrl = providerData?['profile'];
                final pid = providerData?['pid'];

                return ListTile(
                  leading: (imageUrl != null && imageUrl.isNotEmpty)
                      ? CircleAvatar(
                          backgroundImage: NetworkImage(imageUrl),
                        )
                      : const CircleAvatar(
                          backgroundColor: Colors.grey,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                  title: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: username.isNotEmpty
                      ? Text(
                          username,
                          style: const TextStyle(
                              fontSize: 14, color: Colors.grey),
                        )
                      : null,
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey,
                  ),
                  onTap: () {
                    // ตรวจสอบว่ามี pid ก่อนส่งไปหน้า ApproveProvider
                    if (pid != null && pid.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ApproveProvider(
                            pid: pid, // ส่ง pid จาก provider
                          ),
                        ),
                      );
                    } else {
                      // กรณีไม่พบ pid
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('ไม่พบข้อมูลเอกสารของคนขับคนนี้'),
                        ),
                      );
                    }
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}