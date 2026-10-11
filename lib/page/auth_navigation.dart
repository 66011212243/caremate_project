import 'package:caremate_application/page/accountStatusPage.dart';
import 'package:caremate_application/page/document.dart';
import 'package:caremate_application/page/homepage_provider.dart';
import 'package:caremate_application/page/homepage_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// import หน้าอื่น ๆ ของ CareMate ให้ตรงกับโครงสร้างโปรเจกต์

Future<void> navigateAfterLogin({
  required BuildContext context,
  required String uid,
  required int role,
}) async {
  final db = FirebaseFirestore.instance;

  try {
    // 1. ผู้รับบริการ
    if (role == 0) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => HomepageService(uid: uid)),
        (route) => false,
      );
      return;
    }

    // 2. ผู้ให้บริการ
    if (role != 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่พบประเภทบัญชีที่รองรับ')),
      );
      return;
    }

    // 3. ดึงสถานะบัญชีล่าสุดจาก Firestore
    final userDoc = await db.collection('users').doc(uid).get();

    if (!context.mounted) return;

    if (!userDoc.exists) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ไม่พบข้อมูลบัญชี')));
      return;
    }

    final userData = userDoc.data()!;
    final int statusAccount = userData['status_account'] ?? 0;

    // 4. ค้นหา pid
    final providerResult = await db
        .collection('provider')
        .where('provider_uid', isEqualTo: uid)
        .limit(1)
        .get();

    if (!context.mounted) return;

    if (providerResult.docs.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ไม่พบข้อมูลผู้ให้บริการ')));
      return;
    }

    final pid = providerResult.docs.first.id;

    // 5. บัญชีถูกระงับ
    if (statusAccount == 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บัญชีถูกระงับ กรุณาติดต่อผู้ดูแลระบบ')),
      );
      return;
    }

    // 6. ยังไม่เริ่มส่งเอกสาร
    if (statusAccount == 0) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => DocumentPage(pid: pid, isFirstSetup: true),
        ),
        (route) => false,
      );
      return;
    }

    // 7. รอตรวจสอบ หรือเอกสารไม่ผ่าน
    if (statusAccount == 2 || statusAccount == 3) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => AccountStatusPage(uid: uid, pid: pid),
        ),
        (route) => false,
      );
      return;
    }

    // 8. ตรวจสอบเอกสารก่อนอนุญาตให้เข้า HomepageProvider
    if (statusAccount == 1) {
      final documentResult = await db
          .collection('document')
          .where('pid', isEqualTo: pid)
          .get();

      if (!context.mounted) return;

      // ยังไม่มีเอกสาร ไม่อนุญาตให้เข้า HomepageProvider
      if (documentResult.docs.isEmpty) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => DocumentPage(pid: pid, isFirstSetup: true),
          ),
          (route) => false,
        );
        return;
      }

      final hasApprovedDocument = documentResult.docs.any(
        (doc) => doc.data()['status_doc'] == 1,
      );

      // บัญชีอนุมัติ แต่เอกสารไม่ผ่านหรือยังไม่อนุมัติ
      if (!hasApprovedDocument) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => AccountStatusPage(uid: uid, pid: pid),
          ),
          (route) => false,
        );
        return;
      }

      // บัญชีและเอกสารอนุมัติแล้ว
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => HomepageProvider(uid: uid)),
        (route) => false,
      );
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('สถานะบัญชีไม่ถูกต้อง')));
  } catch (e) {
    debugPrint('navigateAfterLogin error: $e');

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ไม่สามารถตรวจสอบสถานะบัญชีได้')),
    );
  }
}
