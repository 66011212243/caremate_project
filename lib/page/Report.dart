import 'package:caremate_application/page/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportPage extends StatefulWidget {
  final String jobId;
  final String reporterId;
  final String reportedId;

  ReportPage({
    super.key,
    required this.jobId,
    required this.reporterId,
    required this.reportedId,
  });

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  //  2. สร้างตัวแปรเก็บข้อความ และ คะแนนดาว (ใช้ ValueNotifier แบบง่าย ไม่ต้องแปลงเป็น StatefulWidget)
  final TextEditingController commentController = TextEditingController();

  final ValueNotifier<int> ratingNotifier = ValueNotifier<int>(5);

  //  3. ฟังก์ชันบันทึกลง Firebase
  Future<void> _saveReport(BuildContext context) async {
    if (commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกรายละเอียดเพิ่มเติม')),
      );
      return;
    }

    try {
      final db = FirebaseFirestore.instance;
      final pid = widget.reportedId;

      // อ้างอิงเอกสาร provider ด้วย pid
      final providerRef = db.collection('provider').doc(pid);

      // สร้าง ID สำหรับรายงานใหม่
      final reportRef = db.collection('reports').doc();

      await db.runTransaction((transaction) async {
        // อ่านข้อมูล provider
        final providerDoc = await transaction.get(providerRef);

        if (!providerDoc.exists) {
          throw Exception('ไม่พบข้อมูลผู้ให้บริการ');
        }

        // อ่านจำนวนรายงานปัจจุบัน
        final currentCount =
            (providerDoc.data()?['reports_num'] as num?)?.toInt() ?? 0;

        // บันทึกรายงาน
        transaction.set(reportRef, {
          'job_id': widget.jobId,
          'reporter_id': widget.reporterId,
          'reported_provider_id': widget.reportedId,
          'status_re': 0,
          'description': commentController.text.trim(),
        });

        // เพิ่มจำนวนรายงานใน provider
        transaction.update(providerRef, {'reports_num': currentCount + 1});
      });

      if (!context.mounted) return;
      await NotificationService().notifyAdminsNewReport(jobId: widget.jobId);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('บันทึกการรายงานสำเร็จ!')));

      Navigator.pop(context, true);
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'รายงาน',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        //centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // หัวข้อหน้า
            const Text(
              "รายงานพฤติกรรมคนขับ",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "กรุณาอธิบายรายละเอียด หรือพฤติกรรมที่ไม่เหมาะสมที่พบเจอ",
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),

            // ช่องกรอกรายละเอียดข้อความ
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: commentController,
                maxLines: 6,
                style: const TextStyle(fontSize: 15, color: Colors.black87),
                decoration: InputDecoration(
                  hintText: 'รายละเอียด...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
                  alignLabelWithHint: true,
                  contentPadding: const EdgeInsets.all(16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.red, width: 1.5),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // ปุ่มกดส่งรายงาน
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shadowColor: Colors.red.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                onPressed: () => _saveReport(context),
                child: const Text(
                  "รายงาน",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
