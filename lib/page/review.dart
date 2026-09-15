import 'package:caremate_application/page/Report.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewPage extends StatelessWidget {
  final String jobId;
  final String driverName;
  final String driverId;
  final String phoneNumber;
  final String licensePlate;
  final String promptPay;

  ReviewPage({
    super.key,
    this.jobId = "001",
    this.driverName = "พิชยกรณ์ ยามรัมย์",
    this.driverId = "01",
    this.phoneNumber = "095588291",
    this.licensePlate = "กข1234",
    this.promptPay = "1234567890",
  });

  //  2. สร้างตัวแปรเก็บข้อความ และ คะแนนดาว (ใช้ ValueNotifier แบบง่าย ไม่ต้องแปลงเป็น StatefulWidget)
  final TextEditingController commentController = TextEditingController();
  final ValueNotifier<int> ratingNotifier = ValueNotifier<int>(5);

  //  3. ฟังก์ชันบันทึกลง Firebase
  void _saveReview(BuildContext context) async {
    if (commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกรายละเอียดเพิ่มเติม')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('review').add({
        'jobId': jobId,
        'driverId': driverId,
        'rating': ratingNotifier.value,
        'comment': commentController.text.trim(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('บันทึกรีวิวสำเร็จ!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
      }
    }
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
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      elevation: 3,
                    ),

                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ReportPage()),
                      );
                    },

                    child: const Text("รายงาน"),
                  ),

                  const SizedBox(width: 10),

                  const Icon(Icons.more_vert),
                ],
              ),

              const SizedBox(height: 20),

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
                          Text(driverName),
                        ],
                      ),

                      SizedBox(height: 5),

                      Row(
                        children: [
                          const Text(
                            "หมายเลขโทรศัพท์: ",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(phoneNumber),
                        ],
                      ),

                      SizedBox(height: 5),

                      Row(
                        children: [
                          const Text(
                            "ทะเบียนรถ: ",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(licensePlate),
                        ],
                      ),

                      SizedBox(height: 5),

                      Row(
                        children: [
                          const Text(
                            "เลขบัญชี: ",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(promptPay),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 40),

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

              const SizedBox(height: 50),

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
                child: SizedBox(
                  width: 120,

                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),

                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),

                    onPressed: () => _saveReview(context),

                    child: const Text("รีวิว"),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
