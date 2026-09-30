import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DriversPage extends StatefulWidget {
  String JobId = "";

  DriversPage({super.key, required this.JobId});

  @override
  State<DriversPage> createState() => _DriversPageState();
}

class _DriversPageState extends State<DriversPage> {
  var db = FirebaseFirestore.instance;

  List<Map<String, dynamic>> driverJobs = [];

  bool isLoading = true;
  double averageRating = 0.0;
  int reviewCount = 0;

  @override
  void initState() {
    super.initState();
    queryDriverJobs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              label: const Icon(Icons.arrow_back_ios, color: Colors.black),
            ),
            const Text(
              'ผู้สมัครทั้งหมด',
              style: TextStyle(color: Colors.black),
            ),
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : driverJobs.isEmpty
          ? const Center(
              child: Text(
                'ไม่มีผู้สมัคร',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                itemCount: driverJobs.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                itemBuilder: (context, index) {
                  var driver = driverJobs[index];

                  return Card(
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 45,
                            backgroundColor: Colors.grey.shade300,
                            child: const Icon(Icons.person, size: 60),
                          ),

                          const SizedBox(height: 10),

                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              driver['realname'] ?? 'ไม่พบชื่อ',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    driver['averageRating'] == 0.0
                                        ? '-'
                                        : driver['averageRating']
                                              .toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),

                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.greenAccent,
                                ),
                                onPressed: () {
                                  print('เลือกคนขับ: ${driver['provider_id']}');
                                  final pageContext = context;
                                  showDialog(
                                    context: pageContext,
                                    builder: (dialogContext) {
                                      return AlertDialog(
                                        title: Text("ยืนยันการเลือกผู้สมัคร"),
                                        content: Text(
                                          "คุณต้องเลือกผู้สมัครนี้หรือไม่?",
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(dialogContext);
                                            },
                                            child: Text(
                                              "ยกเลิก",
                                              style: TextStyle(
                                                color: Colors.grey,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),

                                          TextButton(
                                            onPressed: () async {
                                              // ปิด Dialog ยืนยัน
                                              Navigator.of(dialogContext).pop();

                                              // เปิด Dialog แสดง Loading
                                              showDialog(
                                                context: pageContext,
                                                barrierDismissible: false,
                                                builder: (loadingContext) {
                                                  return const AlertDialog(
                                                    content: Row(
                                                      children: [
                                                        CircularProgressIndicator(),
                                                        SizedBox(width: 20),
                                                        Text(
                                                          "กำลังเลือกผู้ให้บริการ...",
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              );

                                              try {
                                                // รอให้เลือกคนขับและอัปเดตข้อมูลเสร็จ
                                                await chooseDriver(
                                                  driver['provider_id'],
                                                );

                                                // ปิด Loading
                                                if (!mounted) return;
                                                Navigator.of(pageContext).pop();

                                                // ปิด DetailsJob และกลับไป MyjobPovider
                                                Navigator.of(
                                                  pageContext,
                                                ).pop(true);
                                              } catch (e) {
                                                // ถ้าเกิด Error ให้ปิด Loading
                                                if (!mounted) return;
                                                Navigator.of(pageContext).pop();

                                                print("เกิดข้อผิดพลาด: $e");
                                              }
                                            },
                                            child: Text(
                                              "ยืนยัน",
                                              style: TextStyle(
                                                color: const Color.fromARGB(
                                                  255,
                                                  0,
                                                  98,
                                                  15,
                                                ),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                child: const Text('เลือก'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  Future<void> queryJobs() async {}

  Future<void> queryDriverJobs() async {
    try {
      setState(() {
        isLoading = true;
      });

      final stopwatch = Stopwatch()..start();

      var snapshot = await db
          .collection('all_drivers')
          .where('job_id', isEqualTo: widget.JobId)
          .where('status_drivers', isEqualTo: 0)
          .get();

      List<Map<String, dynamic>> drivers = [];

      // 2. โหลดข้อมูลแต่ละคน
      await Future.wait(
        snapshot.docs.map((doc) async {
          var driverData = doc.data();

          String? providerId = driverData['provider_id'];

          if (providerId == null) {
            return;
          }

          // provider
          var providerDoc = await db
              .collection('provider')
              .doc(providerId)
              .get();

          if (!providerDoc.exists) {
            return;
          }

          var providerData = providerDoc.data();
          if (providerData == null) {
            return;
          }

          double averageRating = await queryProviderRatings(providerId);

          String? uid = providerData['provider_uid'];

          if (uid == null) {
            return;
          }

          // user
          var userDoc = await db.collection('users').doc(uid).get();

          if (!userDoc.exists) {
            return;
          }

          var userData = userDoc.data();

          if (userData == null) {
            return;
          }

          drivers.add({
            'driver_id': doc.id,
            'provider_id': providerId,
            'uid': uid,
            'realname': userData['realname'],
            'profileImage': userData['profileImage'],
            'averageRating': averageRating,
          });
        }),
      );

      if (!mounted) return;

      setState(() {
        driverJobs = drivers;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching driver jobs: $e");

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> chooseDriver(String driverId) async {
    // 1. เปลี่ยนสถานะงานเป็น 1
    await db.collection('jobs').doc(widget.JobId).update({'job_status': 1});

    // 2. ดึงผู้สมัครทั้งหมดของงานนี้
    var snapshot = await db
        .collection('all_drivers')
        .where('job_id', isEqualTo: widget.JobId)
        .get();

    // 3. เปลี่ยนสถานะของผู้สมัครแต่ละคน
    for (var doc in snapshot.docs) {
      var data = doc.data();

      if (data['provider_id'] == driverId) {
        // คนที่ถูกเลือก
        await doc.reference.update({'status_drivers': 1});
      } else {
        // คนที่ไม่ได้ถูกเลือก
        await doc.reference.update({'status_drivers': 2});
      }
    }
  }

  Future<double> queryProviderRatings(String providerId) async {
    var ratingsSnapshot = await db
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
}
