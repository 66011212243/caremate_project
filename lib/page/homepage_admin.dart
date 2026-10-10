import 'package:caremate_application/page/Review_history_provider.dart';
import 'package:caremate_application/page/myJob_povider.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomepageAdmin extends StatelessWidget {
  const HomepageAdmin({super.key});

  static const int serviceRoleValue = 0;
  static const int providerRoleValue = 1;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Admin',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.red,

          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(
                text: 'ผู้รับบริการ',
              ),
              Tab(
                text: 'ผู้ให้บริการ',
              ),
            ],
          ),
        ),

        body: const TabBarView(
          children: [
            // role = 0 ผู้รับบริการ
            UserList(
              role: serviceRoleValue,
            ),

            // role = 1 ผู้ให้บริการ
            UserList(
              role: providerRoleValue,
            ),
          ],
        ),
      ),
    );
  }
}

class UserList extends StatelessWidget {
  final int role;

  const UserList({
    super.key,
    required this.role,
  });

  // ดึงรูปของผู้ใช้

  Future<String?> getProfileImage(String uid) async {
    final db = FirebaseFirestore.instance;

    if (role == 0) {
      final serviceSnap = await db
          .collection('service')
          .where(
            'service_id',
            isEqualTo: uid,
          )
          .limit(1)
          .get();

      if (serviceSnap.docs.isNotEmpty) {
        final serviceData = serviceSnap.docs.first.data();

        final photo = serviceData['photo'];

        if (photo != null && photo.toString().isNotEmpty) {
          return photo.toString();
        }
      }
    }

    // ผู้ให้บริการ
    else {
      final providerSnap = await db
          .collection('provider')
          .where(
            'provider_id',
            isEqualTo: uid,
          )
          .limit(1)
          .get();

      if (providerSnap.docs.isNotEmpty) {
        final providerData = providerSnap.docs.first.data();

        final profile = providerData['profile'];

        if (profile != null && profile.toString().isNotEmpty) {
          return profile.toString();
        }
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where(
            'role',
            isEqualTo: role,
          )
          .snapshots(),

      builder: (context, snapshot) {

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'เกิดข้อผิดพลาด: ${snapshot.error}',
            ),
          );
        }

        final users = snapshot.data?.docs ?? [];
        if (users.isEmpty) {
          return const Center(
            child: Text(
              'ไม่พบผู้ใช้งาน',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(
            vertical: 8,
          ),

          itemCount: users.length,

          itemBuilder: (context, index) {
            final userDoc = users[index];

            final data = userDoc.data();

            // Document ID ของ users
            final uid = userDoc.id;

            // ชื่อจริง
            final name =
                data['realname']?.toString() ??
                'ไม่ระบุชื่อ';

            // Username
            final username =
                data['username']?.toString() ??
                '';

            return ListTile(

              leading: FutureBuilder<String?>(
                future: getProfileImage(uid),

                builder: (context, imageSnapshot) {

                  // กำลังโหลดรูป
                  if (imageSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const CircleAvatar(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  }

                  // มีรูป
                  final imageUrl = imageSnapshot.data;

                  if (imageUrl != null &&
                      imageUrl.isNotEmpty) {
                    return CircleAvatar(
                      backgroundImage: NetworkImage(
                        imageUrl,
                      ),
                    );
                  }

                  // ไม่มีรูป
                  return const CircleAvatar(
                    child: Icon(
                      Icons.person,
                    ),
                  );
                },
              ),

              title: Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),

              subtitle: Text(
                username,
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),


              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
              ),

              onTap: () {

                if (role == 0) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MyjobPovider(
                        //uid: uid,
                      ),
                    ),
                  );
                }

                else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ReviewHistoryProvider(
                        pid: uid,
                      ),
                    ),
                  );
                }
              },
            );
          },
        );
      },
    );
  }
}