import 'package:caremate_application/page/approve_provider.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DriverPendingApprovalPage extends StatelessWidget {
  const DriverPendingApprovalPage({super.key});

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
      body: const UserList(role: 1),
    );
  }
}

class UserList extends StatelessWidget {
  final int role;

  const UserList({super.key, required this.role});

  /// ดึงข้อมูลผู้ให้บริการด้วย pid
  Future<Map<String, String?>> getProviderData(String pid) async {
    final db = FirebaseFirestore.instance;

    final providerSnap = await db
        .collection('provider')
        .where('pid', isEqualTo: pid)
        .limit(1)
        .get();

    if (providerSnap.docs.isEmpty) {
      // รองรับกรณี pid เป็น document ID ของ provider
      final providerDoc = await db.collection('provider').doc(pid).get();

      if (!providerDoc.exists) {
        return {'uid': null, 'pid': null, 'profile': null};
      }

      final data = providerDoc.data()!;

      return {
        'uid': data['provider_uid']?.toString(),
        'pid': pid,
        'profile': data['profile']?.toString(),
      };
    }

    final providerDoc = providerSnap.docs.first;
    final data = providerDoc.data();

    return {
      'uid': data['provider_uid']?.toString(),
      'pid': data['pid']?.toString() ?? providerDoc.id,
      'profile': data['profile']?.toString(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('document')
          .where('status_doc', isEqualTo: 0)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
        }

        final documents = snapshot.data?.docs ?? [];

        if (documents.isEmpty) {
          return const Center(
            child: Text(
              'ไม่พบเอกสารที่รออนุมัติ',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        // แสดงเอกสารทุกใบ ไม่รวม pid ที่ซ้ำกัน
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: documents.length,
          separatorBuilder: (context, index) => const Divider(
            height: 1,
            thickness: 0.8,
            color: Color(0xFFE0E0E0),
          ),
          itemBuilder: (context, index) {
            final document = documents[index];
            final documentData = document.data();

            // ID ของเอกสารแต่ละใบใน collection document
            final documentId = document.id;

            final pid = documentData['pid']?.toString() ?? '';

            final vehicleType = documentData['vehicle_type'];

            if (pid.isEmpty) {
              return const ListTile(
                leading: Icon(Icons.warning_amber, color: Colors.orange),
                title: Text('เอกสารนี้ไม่มี pid'),
                subtitle: Text('กรุณาตรวจสอบข้อมูลใน Firestore'),
              );
            }

            return FutureBuilder<Map<String, String?>>(
              future: getProviderData(pid),
              builder: (context, providerSnapshot) {
                if (providerSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const ListTile(
                    leading: CircleAvatar(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    title: Text('กำลังโหลดข้อมูลผู้ให้บริการ...'),
                  );
                }

                if (providerSnapshot.hasError) {
                  return ListTile(
                    title: Text('โหลดข้อมูลไม่สำเร็จ (pid: $pid)'),
                    subtitle: Text(providerSnapshot.error.toString()),
                  );
                }

                final providerData = providerSnapshot.data;
                final uid = providerData?['uid'];
                final imageUrl = providerData?['profile'];

                if (uid == null || uid.isEmpty) {
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text('ไม่พบข้อมูลผู้ให้บริการ (pid: $pid)'),
                    subtitle: Text('รหัสเอกสาร: $documentId'),
                  );
                }

                return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .get(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const ListTile(
                        title: Text('กำลังโหลดข้อมูลผู้ใช้...'),
                      );
                    }

                    final userData = userSnapshot.data?.data();


                    final name =
                        userData?['realname']?.toString() ??
                        userData?['name']?.toString() ??
                        'ไม่ระบุชื่อ';

                    final username = userData?['username']?.toString() ?? '';

                    return ListTile(
                      leading: imageUrl != null && imageUrl.isNotEmpty
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
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (username.isNotEmpty)
                            Text(
                              username,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),

                          //Text('รหัสเอกสาร: $documentId'),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ApproveProvider(docId: documentId, uid: uid,),
                          ),
                        );
                      },
                    );
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
