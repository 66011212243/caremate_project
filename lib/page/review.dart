import 'package:caremate_application/page/Report.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewPage extends StatefulWidget {
  final String jobId;
  final String pid;

  ReviewPage({super.key, required this.jobId, required this.pid});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  //  2. สร้างตัวแปรเก็บข้อความ และ คะแนนดาว (ใช้ ValueNotifier แบบง่าย ไม่ต้องแปลงเป็น StatefulWidget)
  final TextEditingController commentController = TextEditingController();

  final ValueNotifier<int> ratingNotifier = ValueNotifier<int>(5);
  bool hasReport = false;
  bool isCheckingReport = true;
  bool isReviewLoading = false;

  void startLoading() {
    if (!mounted) return;
    setState(() => isReviewLoading = true);
  }

  void stopLoading() {
    if (!mounted) return;
    setState(() => isReviewLoading = false);
  }

  //  3. ฟังก์ชันบันทึกลง Firebase
  Future<void> _saveReview(BuildContext context) async {
    if (commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกรายละเอียดเพิ่มเติม')),
      );
      return;
    }
    startLoading();

    try {
      await FirebaseFirestore.instance.collection('review').add({
        'job_id': widget.jobId,
        'provider_id': widget.pid,
        'rating': ratingNotifier.value,
        'comment': commentController.text.trim(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('บันทึกรีวิวสำเร็จ!')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
      }
    } finally {
      stopLoading();
    }
  }

  var db = FirebaseFirestore.instance;
  Map<String, dynamic>? providerData;
  Map<String, dynamic>? userData;
  Map<String, dynamic>? jobData;
  List<Map<String, dynamic>> documentData = [];

  bool isLoading = true;

  String? imageUrl;
  int? vehicleType;
  String sid = '';

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
      imageUrl = providerData?['profile'];

      if (uid != null) {
        var userDoc = await db.collection('users').doc(uid).get();

        if (userDoc.exists) {
          userData = userDoc.data();
        }
      }

      var jobDoc = await db.collection('jobs').doc(widget.jobId).get();

      if (jobDoc.exists) {
        jobData = jobDoc.data();
        vehicleType = jobData!['vehicle_type'];
        sid = jobData!['service_id'];
      }

      var documentSnapshot = await db
          .collection('document')
          .where('pid', isEqualTo: widget.pid)
          .where('vehicle_type', isEqualTo: vehicleType)
          .get();

      documentData = documentSnapshot.docs.map((doc) => doc.data()).toList();
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

  @override
  void initState() {
    super.initState();
    queryProviderDetails();
    checkReport();
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
          'รีวิว',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),

        backgroundColor: Colors.white,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// ปุ่มรายงาน
              if (isCheckingReport)
                const CircularProgressIndicator()
              else if (!hasReport)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        elevation: 3,
                      ),
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReportPage(
                              jobId: widget.jobId,
                              reporterId: sid,
                              reportedId: widget.pid,
                            ),
                          ),
                        );

                        if (result == true) {
                          await checkReport();
                        }
                      },
                      child: const Text("รายงาน"),
                    ),
                    const SizedBox(width: 10),
                  ],
                ),

              /// หัวข้อคนขับ
              const Text(
                "คนขับ",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              /// โปรไฟล์
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.grey.shade300,

                    child: const Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.brown,
                    ),
                  ),

                  const SizedBox(width: 20),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            "ชื่อ: ",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(userData?['realname'] ?? 'ไม่พบชื่อ'),
                        ],
                      ),

                      SizedBox(height: 5),

                      Row(
                        children: [
                          const Text(
                            "หมายเลขโทรศัพท์: ",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(providerData?['phone'] ?? '-'),
                        ],
                      ),

                      SizedBox(height: 5),

                      Row(
                        children: [
                          const Text(
                            "ทะเบียนรถ: ",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            documentData.isNotEmpty
                                ? documentData.first['vehicle_Registration'] ??
                                      '-'
                                : '-',
                          ),
                        ],
                      ),

                      SizedBox(height: 5),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              /// ให้คะแนน
              const Text(
                "ให้คะแนน",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),

                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(15),
                ),

                child: ValueListenableBuilder<int>(
                  valueListenable: ratingNotifier,
                  builder: (context, currentRating, child) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starIndex = index + 1;
                        return IconButton(
                          onPressed: () => ratingNotifier.value = starIndex,
                          icon: Icon(
                            starIndex <= currentRating
                                ? Icons.star
                                : Icons.star_border,
                            size: 35,
                            color: starIndex <= currentRating
                                ? Colors.amber
                                : Colors.grey,
                          ),
                        );
                      }),
                    );
                  },
                ),
              ),

              const SizedBox(height: 40),

              /// รายละเอียดเพิ่มเติม
              const Text(
                "รายละเอียดเพิ่มเติม",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 180,

                child: TextField(
                  controller: commentController, //  ผูก controller ดึงข้อความ
                  textAlignVertical: TextAlignVertical.top,
                  maxLines: null,
                  expands: true,

                  decoration: InputDecoration(
                    hintText: 'รายละเอียด....',

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 50),

              /// ปุ่มรีวิว
              Center(
                child:  AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isReviewLoading ? 160 : 120,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),

                      padding: const EdgeInsets.symmetric(vertical: 14),
                      disabledBackgroundColor: const Color(
                        0xFFD32F2F,
                      ).withOpacity(0.6),
                      disabledForegroundColor: Colors.white,
                    ),

                    onPressed: isReviewLoading
                        ? null
                        : () async {
                            await _saveReview(context);
                          },

                    child: isReviewLoading
                        ? const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                "กำลังบันทึก...",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        : const Text(
                            "รีวิว",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> checkReport() async {
    try {
      final snapshot = await db
          .collection('reports')
          .where('job_id', isEqualTo: widget.jobId)
          .where('reported_provider_id', isEqualTo: widget.pid)
          .get();

      if (!mounted) return;

      setState(() {
        hasReport = snapshot.docs.isNotEmpty;
        isCheckingReport = false;
      });
    } catch (e) {
      print("เกิดข้อผิดพลาดในการตรวจสอบการชำระเงิน: $e");

      if (!mounted) return;

      setState(() {
        isCheckingReport = false;
      });
    }
  }
}
