import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DetailsProvider extends StatefulWidget {
  String pid = "";
  int vehicle_type = 0;
  DetailsProvider({super.key, required this.pid, required this.vehicle_type});

  @override
  State<DetailsProvider> createState() => _DetailsProviderState();
}

class _DetailsProviderState extends State<DetailsProvider> {
  var db = FirebaseFirestore.instance;
  Map<String, dynamic>? providerData;
  Map<String, dynamic>? userData;
  List<Map<String, dynamic>> documentData = [];

  bool isLoading = true;

  double averageRating = 0.0;
  int reviewCount = 0;

  @override
  void initState() {
    super.initState();
    queryProviderDetails();
    queryProviderRatings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: Row(
          children: [
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              label: Icon(Icons.arrow_back_ios, color: Colors.black),
            ),
            Text(
              "รายละเอียดผู้ให้บริการ",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        toolbarHeight: 70,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // หัวข้อ
                  const Text(
                    'ข้อมูลผู้ให้บริการ',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 20),

                  // Card ข้อมูล
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 8,
                          spreadRadius: 1,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // รูป + ชื่อ
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (dialogContext) {
                                    return Dialog(
                                      backgroundColor: Colors.transparent,
                                      child: Container(
                                        width: 300,
                                        height: 300,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: const Center(
                                          child: Text(
                                            '👤',
                                            style: TextStyle(fontSize: 120),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                              child: CircleAvatar(
                                radius: 35,
                                backgroundColor: Colors.grey.shade200,
                                child: const Icon(
                                  Icons.person,
                                  size: 45,
                                  color: Colors.grey,
                                ),
                              ),
                            ),

                            const SizedBox(width: 15),

                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'ผู้ให้บริการ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),

                                const SizedBox(height: 3),

                                Text(
                                  userData?['username'] ?? 'ไม่พบชื่อ',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 25),

                        const Divider(),

                        const SizedBox(height: 15),

                        // ทะเบียนรถ
                        Row(
                          children: [
                            const Icon(
                              Icons.directions_car,
                              size: 24,
                              color: Colors.grey,
                            ),

                            const SizedBox(width: 12),

                            const Text(
                              'ทะเบียนรถ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const Spacer(),

                            Text(
                              documentData.isNotEmpty
                                  ? documentData
                                            .first['vehicle_Registration'] ??
                                        '-'
                                  : '-',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // อายุ
                        const SizedBox(height: 18),

                        // เบอร์โทร
                        Row(
                          children: [
                            const Icon(
                              Icons.phone,
                              size: 24,
                              color: Colors.grey,
                            ),

                            const SizedBox(width: 12),

                            const Text(
                              'เบอร์โทรศัพท์',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const Spacer(),

                            Text(
                              providerData?['phone'] ?? '-',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        const Divider(),

                        const SizedBox(height: 10),

                        // คะแนน
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 26,
                            ),

                            const SizedBox(width: 8),

                            const Text(
                              'คะแนน',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const Spacer(),

                            Text(
                              reviewCount == 0
                                  ? 'ยังไม่มีรีวิว'
                                  : averageRating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> queryProviderDetails() async {
    try {
      setState(() {
        isLoading = true;
      });

      // ดึงข้อมูล provider
      var providerDoc = await db.collection('provider').doc(widget.pid).get();

      if (!providerDoc.exists) {
        print('ไม่พบข้อมูล provider');
        return;
      }

      providerData = providerDoc.data();

      // เอา provider_uid ไปดึงข้อมูล user
      var uid = providerData?['provider_uid'];

      if (uid != null) {
        var userDoc = await db.collection('users').doc(uid).get();

        if (userDoc.exists) {
          userData = userDoc.data();
        }
      }

      // ดึง document ของ provider
      // และต้องมี vehicle_type ตรงกับ widget.vehicle_type
      var documentSnapshot = await db
          .collection('document')
          .where('pid', isEqualTo: widget.pid)
          .where('vehicle_type', isEqualTo: widget.vehicle_type)
          .get();

      documentData = documentSnapshot.docs.map((doc) => doc.data()).toList();

      // print('providerData: $providerData');
      // print('userData: $userData');
      // print('documentData: $documentData');
    } catch (e) {
      print('เกิดข้อผิดพลาด: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> queryProviderRatings() async {
    var ratingsSnapshot = await db
        .collection('review')
        .where('provider_id', isEqualTo: widget.pid)
        .get();

    if (ratingsSnapshot.docs.isEmpty) {
      setState(() {
        averageRating = 0.0;
        reviewCount = 0;
      });

      return;
    }

    double totalRating = 0.0;

    for (var doc in ratingsSnapshot.docs) {
      var data = doc.data();

      var rating = data['rating'];

      if (rating != null) {
        totalRating += (rating as num).toDouble();
      }
    }

    setState(() {
      reviewCount = ratingsSnapshot.docs.length;
      averageRating = totalRating / reviewCount;
    });

    // print('จำนวนรีวิว: $reviewCount');
    // print('คะแนนรวม: $totalRating');
    // print('คะแนนเฉลี่ย: $averageRating');
  }
}
