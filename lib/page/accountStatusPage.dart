import 'package:caremate_application/page/document.dart';
import 'package:caremate_application/page/homepage_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AccountStatusPage extends StatefulWidget {
  final String uid;
  final String pid;

  const AccountStatusPage({super.key, required this.uid, required this.pid});

  @override
  State<AccountStatusPage> createState() => _AccountStatusPageState();
}

class _AccountStatusPageState extends State<AccountStatusPage> {
  var db = FirebaseFirestore.instance;

  // 0 = รอตรวจสอบ, 1 = อนุมัติแล้ว, 2 = ไม่ผ่าน
  int accountStatus = 0;
  String rejectReason = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    checkAccountStatus();
  }

  Future<void> checkAccountStatus() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      // 1. ดึงข้อมูลบัญชีผู้ใช้จาก users
      final userDoc = await db.collection('users').doc(widget.uid).get();

      if (!userDoc.exists) {
        if (!mounted) return;

        setState(() {
          isLoading = false;
        });
        return;
      }

      final userData = userDoc.data()!;

      // 2. ค้นหาข้อมูลผู้ให้บริการจาก provider_uid
      final providerResult = await db
          .collection('provider')
          .where('provider_uid', isEqualTo: widget.uid)
          .limit(1)
          .get();

      int docStatus = 0;
      String? documentRejectReason;

      // 3. ตรวจสอบเอกสารของผู้ให้บริการ
      if (providerResult.docs.isNotEmpty) {
        // ใช้ ID ของเอกสาร provider เป็น pid
        final pid = providerResult.docs.first.id;

        final documentResult = await db
            .collection('document')
            .where('pid', isEqualTo: pid)
            .where('status_doc', isEqualTo: 2)
            .limit(1)
            .get();

        if (documentResult.docs.isNotEmpty) {
          final documentData = documentResult.docs.first.data();

          docStatus = documentData['status_doc'] ?? 0;
          documentRejectReason = documentData['reject_reason'];
        }
      }

      if (!mounted) return;

      // 4. อัปเดตสถานะบัญชีและเอกสาร
      setState(() {
        accountStatus = userData['status_account'] ?? 0;
        //statusDoc = docStatus;

        rejectReason = documentRejectReason ?? 'เอกสารไม่ถูกต้อง';

        isLoading = false;
      });
    } catch (e) {
      debugPrint('checkAccountStatus error: $e');

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          "สถานะบัญชี",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),

                  // แสดง Icon & Content ตามสถานะ
                  if (accountStatus == 2) _buildPendingStatus(),
                  if (accountStatus == 3) _buildRejectedStatus(),
                  if (accountStatus == 1) _buildApprovedStatus(),

                  const Spacer(),

                  // ปุ่มควบคุมด้านล่าง
                  _buildBottomButtons(),
                ],
              ),
            ),
    );
  }

  // 1. UI รอตรวจสอบ
  Widget _buildPendingStatus() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.hourglass_top_rounded,
            size: 70,
            color: Colors.orange.shade700,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          "กำลังตรวจสอบเอกสาร",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          "ระบบกำลังทำการตรวจสอบเอกสารของคุณ\nโดยปกติจะใช้เวลาประมาณ 1-2 วันทำการ",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey.shade700,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // 2. UI ไม่ผ่านการอนุมัติ
  Widget _buildRejectedStatus() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.cancel_rounded, size: 70, color: Colors.red),
        ),
        const SizedBox(height: 24),
        const Text(
          "เอกสารไม่ผ่านการอนุมัติ",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          "เนื่องจากข้อมูลหรือเอกสารของคุณไม่ตรงตามเงื่อนไข",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 20),

        // กล่องแสดงเหตุผลที่ไม่ผ่าน
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "เหตุผลที่ไม่ผ่าน:",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 6),
              Text(rejectReason, style: TextStyle(color: Colors.red.shade900)),
            ],
          ),
        ),
      ],
    );
  }

  // 3. UI ผ่านการอนุมัติแล้ว
  Widget _buildApprovedStatus() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            size: 70,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          "อนุมัติบัญชีเรียบร้อยแล้ว",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          "ยินดีต้อนรับ! บัญชีของคุณได้รับการยืนยันเรียบร้อยแล้ว",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
        ),
      ],
    );
  }

  // ส่วนปุ่มด้านล่าง
  Widget _buildBottomButtons() {
    if (accountStatus == 2) {
      // รอตรวจสอบ
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: checkAccountStatus,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "รีเฟรชสถานะ",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      );
    } else if (accountStatus == 3) {
      // ไม่ผ่าน
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    DocumentPage(pid: widget.pid, isFirstSetup: true),
              ),
              (route) => false,
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            "แก้ไขเอกสารอีกครั้ง",
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
        ),
      );
    } else {
      // ผ่านแล้ว
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomepageProvider(uid: widget.uid),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            "เข้าสู่หน้าหลัก",
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
        ),
      );
    }
  }
}
