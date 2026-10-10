import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ReviewhistoryPage extends StatelessWidget {
  final String sid;
  const ReviewhistoryPage({super.key, required this.sid});

  Future<List<Map<String, dynamic>>> fetchUserReviews() async {
    final db = FirebaseFirestore.instance;

    List<Map<String, dynamic>> reviews = [];

    // 1. หา jobs ของผู้ใช้บริการคนนี้
    final jobSnap = await db
        .collection('jobs')
        .where('service_id', isEqualTo: sid)
        .get();

    print('service_id = $sid');
    print('จำนวน jobs = ${jobSnap.docs.length}');

    // 2. วนหา review จากแต่ละ job
    for (var jobDoc in jobSnap.docs) {
      final jobId = jobDoc.id;

      print('กำลังค้นหา review ของ job_id = $jobId');

      final reviewSnap = await db
          .collection('review')
          .where('job_id', isEqualTo: jobId)
          .get();

      // 3. วนดู review
      for (var reviewDoc in reviewSnap.docs) {
        final reviewData = reviewDoc.data();

        final providerId = reviewData['provider_id']?.toString() ?? '';

        String providerName = 'ไม่พบชื่อผู้ให้บริการ';

        // 4. หา provider
        if (providerId.isNotEmpty) {
          final providerDoc = await db
              .collection('provider')
              .doc(providerId)
              .get();

          if (providerDoc.exists) {
            final providerData = providerDoc.data();

            // 5. เอา provider_uid
            final providerUid = providerData?['provider_uid']?.toString() ?? '';

            if (providerUid.isNotEmpty) {
              // 6. เอา provider_uid ไปหา users
              final userDoc = await db
                  .collection('users')
                  .doc(providerUid)
                  .get();

              if (userDoc.exists) {
                final userData = userDoc.data();

                providerName =
                    userData?['username']?.toString() ?? 'ไม่ระบุชื่อ';
              }
            }
          }
        }

        // 7. เก็บข้อมูล review
        reviews.add({
          'username': providerName,
          'rating': reviewData['rating'] ?? 0,
          'comment': reviewData['comment'] ?? '',
        });
      }
    }

    print('จำนวน review ทั้งหมด = ${reviews.length}');

    return reviews;
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
        title: const Text(
          'ประวัติรีวิว',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),

      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchUserReviews(),
        builder: (context, snapshot) {
          // กำลังโหลด
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // เกิดข้อผิดพลาด
          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }

          final reviews = snapshot.data ?? [];

          // ไม่มีรีวิว
          if (reviews.isEmpty) {
            return const Center(
              child: Text(
                'ยังไม่มีประวัติรีวิว',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          // แสดงรีวิว
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final data = reviews[index];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ชื่อผู้ให้บริการ
                  Text(
                    data['username'] ?? 'ไม่ระบุชื่อ',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  // คะแนน
                  Row(
                    children: [
                      ...List.generate(
                        (data['rating'] ?? 0).toInt(),
                        (index) => const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${data['rating']}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // ความคิดเห็น
                  Text(
                    data['comment'] ?? '',
                    style: const TextStyle(fontSize: 15),
                  ),

                  const Divider(height: 30, thickness: 1),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
