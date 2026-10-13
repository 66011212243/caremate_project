import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProviderReviewHistory extends StatefulWidget {
  final String pid;
  const ProviderReviewHistory({super.key, required this.pid});

  @override
  State<ProviderReviewHistory> createState() => _ProviderReviewHistoryState();
}

class _ProviderReviewHistoryState extends State<ProviderReviewHistory> {
  final db = FirebaseFirestore.instance;

  List<Map<String, dynamic>> reviews = [];
  bool isLoadingReviews = true;

  @override
  void initState() {
    super.initState();
    getReviewProvider();
  }

  Future<void> getReviewProvider() async {
    setState(() {
      isLoadingReviews = true;
    });
    try {
      final reviewSnap = await db
          .collection('review')
          .where('provider_id', isEqualTo: widget.pid)
          .get();

      print('provider_id = ${widget.pid}');
      print('จำนวนรีวิว = ${reviewSnap.docs.length}');

      List<Map<String, dynamic>> loadedReviews = [];

      for (var reviewDoc in reviewSnap.docs) {
        final reviewData = reviewDoc.data();

        // ข้อมูลรีวิว
        final jobId = reviewData['job_id']?.toString() ?? '';

        final ratingValue = reviewData['rating'];
        final rating = ratingValue is num ? ratingValue.toDouble() : 0.0;

        final comment = reviewData['comment']?.toString() ?? '';

        String serviceId = '';
        String username = 'ผู้ใช้บริการ';
        String uid = 'ผู้ใช้บริการ';

        Map<String, dynamic> serviceData = {};
        Map<String, dynamic> userData = {};

        // 1. ดึงข้อมูลงานเพื่อหา service_id
        if (jobId.isNotEmpty) {
          final jobSnap = await db.collection('jobs').doc(jobId).get();

          if (jobSnap.exists) {
            final jobData = jobSnap.data();
            serviceId = jobData?['service_id']?.toString() ?? '';
          }
        }

        // 2. ดึงข้อมูล service
        if (serviceId.isNotEmpty) {
          final serviceSnap = await db
              .collection('service')
              .doc(serviceId)
              .get();

          if (serviceSnap.exists) {
            serviceData = serviceSnap.data() ?? {};
            uid = serviceSnap['service_uid'];
          }
        }

        // 3. ดึง username จาก users
        // สมมติว่า service_id คือ document ID ของ users
        if (serviceId.isNotEmpty) {
          final userSnap = await db.collection('users').doc(uid).get();

          if (userSnap.exists) {
            userData = userSnap.data() ?? {};
            username = userData['username']?.toString() ?? 'ผู้ใช้บริการ';
          }
        }

        // 4. เก็บข้อมูลทั้งหมดไว้ใช้กับ UI
        loadedReviews.add({
          'review_id': reviewDoc.id,
          'job_id': jobId,
          'service_id': serviceId,
          'username': username,
          'rating': rating,
          'comment': comment,
          'service_data': serviceData,
          'user_data': userData,
        });
      }

      if (!mounted) return;

      setState(() {
        reviews = loadedReviews;
      });

      print('โหลดข้อมูลรีวิวสำเร็จ ${reviews.length} รายการ');
    } catch (e) {
      print('เกิดข้อผิดพลาดในการโหลดรีวิว: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoadingReviews = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE53935),
        foregroundColor: Colors.white,
        elevation: 0,
        //centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'รีวิวผู้ให้บริการ',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'รายการรีวิว',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                Text(
                  '${reviews.length} รีวิว',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Expanded(
              child: isLoadingReviews
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFE53935),
                      ),
                    )
                  : reviews.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.rate_review_outlined,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'ยังไม่มีรีวิว',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: reviews.length,
                      itemBuilder: (context, index) {
                        final review = reviews[index];

                        return _buildReviewCard(
                          name:
                              review['username']?.toString() ?? 'ผู้ใช้บริการ',
                          rating: (review['rating'] as num? ?? 0)
                              .toDouble()
                              .toStringAsFixed(1),
                          comment: review['comment']?.toString() ?? '',
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildReviewCard({
  required String name,
  required String rating,
  required String comment,
}) {
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const CircleAvatar(
              radius: 22,
              backgroundColor: Color(0xFFFFEBEE),
              child: Icon(Icons.person, color: Color(0xFFE53935), size: 25),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),

            // คะแนนรีวิว
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFFFB300),
                  size: 20,
                ),
                const SizedBox(width: 3),
                Text(
                  rating,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 14),

        Text(
          comment,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
            color: Color(0xFF555555),
          ),
        ),
      ],
    ),
  );
}
