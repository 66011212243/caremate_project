import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportPage extends StatelessWidget {
  final String jobId;
  final String reporter_id;
  final String status_re;
  final String reported_provider_id;
  
  ReportPage({
    super.key,
    this.jobId = "001",
    this.reporter_id = "01",
    this.status_re = "1",
    this.reported_provider_id = "01",
  });

  //  2. สร้างตัวแปรเก็บข้อความ และ คะแนนดาว (ใช้ ValueNotifier แบบง่าย ไม่ต้องแปลงเป็น StatefulWidget)
  final TextEditingController commentController = TextEditingController();
  final ValueNotifier<int> ratingNotifier = ValueNotifier<int>(5);

  //  3. ฟังก์ชันบันทึกลง Firebase
  void _saveReport(BuildContext context) async {
    if (commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกรายละเอียดเพิ่มเติม')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('reports').add({
        'jobId': jobId,
        'reporter_id': reporter_id,
        'status_re': status_re,
        'description': commentController.text.trim(),
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
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        leading: const Icon(Icons.arrow_back, color: Colors.black),
        title: const Text(
          'รายงาน',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "รายงานพฤติดรรมคนขับ ",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  Center(
                    child: SizedBox(
                      width: 300,
                      height: 150,

                      child: TextField(
                        controller: commentController,
                        maxLines: null,
                        expands: true,

                        decoration: InputDecoration(
                          hintText: 'รายละเอียด...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 65),
                  SizedBox(
                    width: 150,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 255, 0, 0),
                        foregroundColor: const Color.fromARGB(
                          255,
                          255,
                          255,
                          255,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => _saveReport(context),
                      child: const Text("รายงาน"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
