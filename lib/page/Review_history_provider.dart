import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ReviewHistoryProvider extends StatelessWidget {
  final String pid;
  const ReviewHistoryProvider({super.key, required this.pid});

  Future<List<Map<String, dynamic>>> fetchProviderReviews() async {
    final db = FirebaseFirestore.instance;
    List<Map<String, dynamic>> reviews = [];

    // 1. ยิง Query ตรงไปที่ collection 'review' โดยใช้ provider_id
    final reviewSnap = await db
        .collection('review')
        .where('provider_id', isEqualTo: pid)
        .get();

    print('provider_id = $pid');
    print('จำนวนรีวิว = ${reviewSnap.docs.length}');

    // 2. ดึงข้อมูล rating และ comment ออกมาใช้งานตรงๆ
    for (var reviewDoc in reviewSnap.docs) {
      final reviewData = reviewDoc.data();

      reviews.add({
        'rating': (reviewData['rating'] ?? 0).toDouble(),
        'comment': reviewData['comment'] ?? '',
      });
    }

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
          'ประวัติรีวิวที่ได้รับ',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchProviderReviews(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }

          final reviews = snapshot.data ?? [];

          if (reviews.isEmpty) {
            return const Center(
              child: Text(
                'ยังไม่มีประวัติรีวิว',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final data = reviews[index];
              final double rating = data['rating'] ?? 0.0;

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
                  // แสดงคะแนนดาว 5 ดวง
                  Row(
                    children: [
                      ...List.generate(
                        5,
                        (starIndex) => Icon(
                          starIndex < rating.floor()
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$rating',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // แสดงความคิดเห็น
                  Text(
                    data['comment']?.isNotEmpty == true
                        ? data['comment']
                        : 'ไม่มีข้อความความคิดเห็น',
                    style: const TextStyle(fontSize: 15, color: Colors.black87),
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
