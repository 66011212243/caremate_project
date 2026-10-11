import 'package:caremate_application/page/Review_history_provider.dart';
import 'package:caremate_application/page/approve_provider.dart';
import 'package:caremate_application/page/notifications_page.dart';
import 'package:caremate_application/page/setting_admin.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomepageAdmin extends StatefulWidget {
  static const int serviceRoleValue = 0;
  static const int providerRoleValue = 1;
  final String uid;

  const HomepageAdmin({super.key, required this.uid});

  @override
  State<HomepageAdmin> createState() => _HomepageAdminState();
}

// 1. เพิ่มการประกาศ Class _HomepageAdminState ให้ถูกต้อง
class _HomepageAdminState extends State<HomepageAdmin> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      Container(),
      NotificationsPage(uid: widget.uid),
      SettingAdmin(uid: widget.uid),
    ];
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _selectedIndex == 0
                ? 'Admin'
                : _selectedIndex == 1
                ? 'การแจ้งเตือน'
                : "การตั้งค่า",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.red,

          bottom: _selectedIndex == 0
              ? const TabBar(
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  tabs: [
                    Tab(text: 'ผู้รับบริการ'),
                    Tab(text: 'ผู้ให้บริการ'),
                  ],
                )
              : null,
        ),

        body: _selectedIndex == 0
            ? TabBarView(
                children: [
                  // 2. เรียกใช้ static variable ผ่าน HomepageAdmin.
                  UserList(role: HomepageAdmin.serviceRoleValue),
                  UserList(role: HomepageAdmin.providerRoleValue),
                ],
              )
            : pages[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Color.fromARGB(255, 255, 0, 0),
          currentIndex: _selectedIndex,

          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },

          items: [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "หน้าหลัก"),

            BottomNavigationBarItem(
              icon: Icon(Icons.notifications),
              label: "ข้อความ",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: "ตั้งค่า",
            ),
          ],
        ),
      ),
    );
  }
}

// 2. Data Model สำหรับเก็บรูป และ PID
class RelatedProfileData {
  final String? profileUrl;
  final String? pid;

  RelatedProfileData({this.profileUrl, this.pid});
}

class UserList extends StatelessWidget {
  final int role;

  const UserList({super.key, required this.role});

  Future<RelatedProfileData> getRelatedProfileData(String uid) async {
    final db = FirebaseFirestore.instance;

    try {
      if (role == 0) {
        // ผู้รับบริการ
        final serviceSnap = await db
            .collection('service')
            .where('service_uid', isEqualTo: uid)
            .limit(1)
            .get();

        if (serviceSnap.docs.isNotEmpty) {
          final doc = serviceSnap.docs.first;
          final serviceData = doc.data();
          final photo = serviceData['profile']?.toString().trim();

          return RelatedProfileData(
            profileUrl: (photo != null && photo.isNotEmpty) ? photo : null,
            pid: doc.id,
          );
        }
      } else {
        // ผู้ให้บริการ
        final providerSnap = await db
            .collection('provider')
            .where('provider_uid', isEqualTo: uid)
            .limit(1)
            .get();

        if (providerSnap.docs.isNotEmpty) {
          final doc = providerSnap.docs.first;
          final providerData = doc.data();
          final profile = providerData['profile']?.toString().trim();

          final pidValue = providerData['pid']?.toString() ?? doc.id;

          return RelatedProfileData(
            profileUrl: (profile != null && profile.isNotEmpty)
                ? profile
                : null,
            pid: pidValue,
          );
        }
      }
    } catch (e) {
      debugPrint('getRelatedProfileData error: $e');
    }

    return RelatedProfileData();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: role)
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
            child: Text('ไม่พบผู้ใช้งาน', style: TextStyle(fontSize: 16)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: users.length,

          itemBuilder: (context, index) {
            final userDoc = users[index];
            final data = userDoc.data();
            final uid = userDoc.id;

            final name = data['realname']?.toString() ?? 'ไม่ระบุชื่อ';
            final username = data['username']?.toString() ?? '';

            return FutureBuilder<RelatedProfileData>(
              future: getRelatedProfileData(uid),
              builder: (context, profileSnapshot) {
                final profileData = profileSnapshot.data;
                final imageUrl = profileData?.profileUrl;
                final pid = profileData?.pid;

                return ListTile(
                  leading: Builder(
                    builder: (context) {
                      if (profileSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const CircleAvatar(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }

                      if (imageUrl != null && imageUrl.isNotEmpty) {
                        return CircleAvatar(
                          backgroundImage: NetworkImage(imageUrl),
                        );
                      }

                      return const CircleAvatar(child: Icon(Icons.person));
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
                    style: const TextStyle(fontSize: 14),
                  ),

                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),

                  onTap: () {
                    if (role == 0) {
                      // ผู้รับบริการ
                    } else if (role == 1) {
                      if (pid != null && pid.isNotEmpty) {
                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(
                        //     builder: (context) => ApproveProvider(pid: pid),
                        //   ),
                        // );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'ไม่พบข้อมูล PID ของผู้ให้บริการท่านนี้',
                            ),
                          ),
                        );
                      }
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
