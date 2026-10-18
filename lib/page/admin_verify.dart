import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminVerify extends StatefulWidget {
  const AdminVerify({super.key});

  @override
  State<AdminVerify> createState() => _AdminVerifyState();
}

class _AdminVerifyState extends State<AdminVerify> {
  DateTime? _getExpiryDate(dynamic approvedAt) {
    if (approvedAt is! Timestamp) return null;

    final approved = approvedAt.toDate();
    final targetMonth = approved.month + 6;
    final year = approved.year + (targetMonth - 1) ~/ 12;
    final month = (targetMonth - 1) % 12 + 1;

    final lastDay = DateTime(year, month + 1, 0).day;
    final day = approved.day > lastDay ? lastDay : approved.day;

    return DateTime(
      year,
      month,
      day,
      approved.hour,
      approved.minute,
      approved.second,
    );
  }

  Future<List<Map<String, dynamic>>> _loadExpiredDocuments() async {
    final db = FirebaseFirestore.instance;

    final snapshot = await db
        .collection('document')
        .where('status_doc', isEqualTo: 1)
        .get();

    final today = DateUtils.dateOnly(DateTime.now());
    final results = <Map<String, dynamic>>[];

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final expiryDate = _getExpiryDate(data['approve_at']);

      if (expiryDate == null) continue;

      // เลือกเฉพาะเอกสารที่หมดอายุแล้ว
      if (!DateUtils.dateOnly(expiryDate).isBefore(today)) {
        continue;
      }

      final pid = data['pid']?.toString() ?? '';

      // ค้นหาข้อมูลผู้ให้บริการ
      final providerSnap = await db.collection('provider').doc(pid).get();

      final providerUid = providerSnap.data()?['provider_uid']?.toString();

      String providerName = 'ไม่พบชื่อผู้ให้บริการ';

      if (providerUid != null && providerUid.isNotEmpty) {
        final userSnap = await db.collection('users').doc(providerUid).get();

        providerName =
            userSnap.data()?['realname']?.toString() ?? 'ไม่พบชื่อผู้ให้บริการ';
      }

      results.add({
        'docId': doc.id,
        'pid': pid,
        'providerName': providerName,
        'vehicleType': data['vehicle_type'],
        'expiryDate': expiryDate,
        'documentData': data,
      });
    }

    // เรียงวันหมดอายุจากเก่าที่สุดก่อน
    results.sort(
      (a, b) =>
          (a['expiryDate'] as DateTime).compareTo(b['expiryDate'] as DateTime),
    );

    return results;
  }

  Future<void> deleteDocument(String docId) async {
    try {
      // แสดงหน้าต่างยืนยันก่อนลบ
      final confirm = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('ยืนยันการลบ'),
            content: const Text(
              'คุณต้องการลบเอกสารนี้ใช่หรือไม่?\nการลบนี้ไม่สามารถย้อนกลับได้',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('ยกเลิก'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F),
                  foregroundColor: Colors.white,
                ),
                child: const Text('ลบเอกสาร'),
              ),
            ],
          );
        },
      );

      // ถ้าไม่ยืนยัน ให้หยุดทำงาน
      if (confirm != true) return;

      // ลบเอกสารจาก Firestore
      await FirebaseFirestore.instance
          .collection('document')
          .doc(docId)
          .delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ลบเอกสารเรียบร้อยแล้ว'),
          backgroundColor: Colors.green,
        ),
      );

      // โหลดข้อมูลใหม่ หากหน้าจอนี้ใช้ FutureBuilder หรือ query ข้อมูล
      setState(() {});
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ลบเอกสารไม่สำเร็จ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xFFD32F2F),
          title: const Text(
            'ตรวจสอบผู้ให้บริการ',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        body: Column(
          children: [
            Container(
              color: Colors.white,
              child: const TabBar(
                isScrollable: false,
                labelColor: Color(0xFFD32F2F),
                unselectedLabelColor: Colors.grey,
                indicatorColor: Color(0xFFD32F2F),
                indicatorWeight: 3,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                tabs: [
                  Tab(text: 'เอกสารหมดอายุ'),
                  Tab(text: 'ยกเลิกการระงับ'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [_buildExpiredDocsTab(), _buildSuspendedUsersTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // แท็บที่ 1: เอกสารหมดอายุ
  // ==========================================

  Widget _buildExpiredDocsTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadExpiredDocuments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('โหลดข้อมูลไม่สำเร็จ: ${snapshot.error}'));
        }

        final docs = snapshot.data ?? [];

        if (docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline, size: 56, color: Colors.green),
                SizedBox(height: 12),
                Text('ไม่มีเอกสารหมดอายุ'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final item = docs[index];
            final expiryDate = item['expiryDate'] as DateTime;
            final vehicleType = item['vehicleType'];

            final vehicleName = vehicleType == 1
                ? 'เอกสารรถยนต์'
                : 'เอกสารรถจักรยานยนต์';

            final dateText =
                '${expiryDate.day.toString().padLeft(2, '0')}/'
                '${expiryDate.month.toString().padLeft(2, '0')}/'
                '${expiryDate.year}';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 24,
                          child: Icon(Icons.person),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['providerName'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(vehicleName),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'หมดอายุแล้ว',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'วันที่หมดอายุ: $dateText',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              //print(item['docId']);
                              deleteDocument(item['docId']);
                            },
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'ลบเอกสาร',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD32F2F),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  DateTime? _getUnbanDate(dynamic suspendedAt) {
    if (suspendedAt is! Timestamp) return null;

    return suspendedAt.toDate().add(const Duration(days: 3));
  }

  Future<void> _unbanAccount(BuildContext context, String uid) async {
    try {
      final db = FirebaseFirestore.instance;

      final userRef = db.collection('users').doc(uid);
      final userSnap = await userRef.get();

      if (!userSnap.exists) {
        throw Exception('ไม่พบข้อมูลผู้ใช้');
      }

      final data = userSnap.data()!;
      final suspendedAt = data['suspended_at'];

      if (data['status_account'] != 4) {
        throw Exception('บัญชีนี้ไม่ได้อยู่ในสถานะถูกระงับ');
      }

      final unbanDate = _getUnbanDate(suspendedAt);

      if (unbanDate == null) {
        throw Exception('ไม่พบวันที่ระงับบัญชี');
      }

      if (DateTime.now().isBefore(unbanDate)) {
        throw Exception('ยังไม่ครบกำหนดปลดระงับบัญชี');
      }

      await userRef.update({'status_account': 1});

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ปลดระงับบัญชีเรียบร้อยแล้ว'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ปลดระงับบัญชีไม่สำเร็จ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ==========================================
  // แท็บที่ 2: ยกเลิกการระงับ
  // ==========================================

  Widget _buildSuspendedUsersTab() {
    return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('users')
          .where('status_account', isEqualTo: 4)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('โหลดข้อมูลผู้ถูกระงับไม่สำเร็จ'));
        }

        final users = snapshot.data?.docs ?? [];

        if (users.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline, color: Colors.green, size: 56),
                SizedBox(height: 12),
                Text('ไม่มีบัญชีที่ถูกระงับ'),
              ],
            ),
          );
        }

        // เรียงตามวันที่ระงับล่าสุดก่อน
        users.sort((a, b) {
          final dateA = a.data()['suspended_at'];
          final dateB = b.data()['suspended_at'];

          final timeA = dateA is Timestamp ? dateA.toDate() : DateTime(1970);

          final timeB = dateB is Timestamp ? dateB.toDate() : DateTime(1970);

          return timeB.compareTo(timeA);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final userDoc = users[index];
            final data = userDoc.data();

            final uid = userDoc.id;
            final name = data['realname']?.toString() ?? 'ไม่ระบุชื่อ';

            final suspendedAt = data['suspended_at'];
            final unbanDate = _getUnbanDate(suspendedAt);

            final now = DateTime.now();
            final isEligible = unbanDate != null && !now.isBefore(unbanDate);

            String formatDate(DateTime date) {
              return '${date.day}/${date.month}/${date.year}';
            }

            String remainingText() {
              if (unbanDate == null) {
                return 'ไม่มีข้อมูลวันที่ระงับ';
              }

              final difference = unbanDate.difference(now);

              if (difference.inSeconds <= 0) {
                return 'ครบกำหนดปลดระงับแล้ว';
              }

              final days = difference.inDays;
              final hours = difference.inHours % 24;
              final minutes = difference.inMinutes % 60;

              return 'เหลือ $days วัน $hours ชั่วโมง $minutes นาที';
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.grey,
                          child: Icon(Icons.person_off, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'ถูกระงับบัญชี',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    if (suspendedAt is Timestamp) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'ถูกระงับเมื่อ: '
                              '${formatDate(suspendedAt.toDate())}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],

                    if (unbanDate != null) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_month,
                            size: 16,
                            color: isEligible ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'ครบกำหนด: ${formatDate(unbanDate)}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        remainingText(),
                        style: TextStyle(
                          color: isEligible
                              ? Colors.green.shade700
                              : Colors.orange.shade800,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isEligible
                            ? () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (dialogContext) {
                                    return AlertDialog(
                                      title: const Text('ยืนยันปลดระงับบัญชี'),
                                      content: Text(
                                        'ต้องการปลดระงับบัญชีของ $name '
                                        'ใช่หรือไม่?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(
                                            dialogContext,
                                            false,
                                          ),
                                          child: const Text('ยกเลิก'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () => Navigator.pop(
                                            dialogContext,
                                            true,
                                          ),
                                          child: const Text('ยืนยัน'),
                                        ),
                                      ],
                                    );
                                  },
                                );

                                if (confirm != true || !context.mounted) {
                                  return;
                                }

                                await _unbanAccount(context, uid);

                                if (context.mounted) {
                                  setState(() {});
                                }
                              }
                            : null,
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: Text(
                          isEligible
                              ? 'ปลดการระงับบัญชี'
                              : 'ยังไม่ครบกำหนดปลดระงับ',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          disabledForegroundColor: Colors.grey.shade600,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
