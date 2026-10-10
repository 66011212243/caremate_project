import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ApproveProvider extends StatefulWidget {
  final String pid;

  const ApproveProvider({
    super.key,
    required this.pid,
  });

  @override
  State<ApproveProvider> createState() => _ApproveProviderState();
}

class _ApproveProviderState extends State<ApproveProvider> {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  bool isLoading = true;
  bool isProcessing = false;

  String? documentId;
  String? userUid;

  Map<String, dynamic>? documentData;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  
  // โหลดข้อมูลเอกสาร
 // โหลดข้อมูลเอกสาร
  Future<void> loadData() async {
    try {
      debugPrint('================================');
      debugPrint('PID ที่ได้รับจาก HomepageAdmin: ${widget.pid}');
      debugPrint('================================');

      if (widget.pid.trim().isEmpty) {
        throw Exception('PID เป็นค่าว่าง');
      }

      final cleanPid = widget.pid.trim();

      // 1. ค้นหา document ด้วย PID
      final documentSnapshot = await db
          .collection('document')
          .where('pid', isEqualTo: cleanPid)
          .limit(1)
          .get();

      debugPrint(
        'จำนวน document ที่พบ: ${documentSnapshot.docs.length}',
      );

      if (documentSnapshot.docs.isEmpty) {
        throw Exception(
          'ไม่พบเอกสารของผู้ให้บริการ PID: $cleanPid',
        );
      }

      final documentDoc = documentSnapshot.docs.first;
      documentId = documentDoc.id;
      documentData = documentDoc.data();

      debugPrint('พบ Document ID = $documentId');

      // ------------------------------------------------
      // 2. หา UID ของ users จากการ Query ไปที่ provider ก่อน
      // ------------------------------------------------

      // ลองหาจาก provider_uid ในตาราง provider ด้วย PID
      // (ถ้า pid คือ doc.id ของ provider ใช้แบบ ก., ถ้า pid เป็น field ใช้แบบ ข.)
      
      // แบบ ก: กรณี PID คือ Document ID ของคอลเลกชัน provider
      final providerDoc = await db.collection('provider').doc(cleanPid).get();
      
      if (providerDoc.exists && providerDoc.data()?['provider_uid'] != null) {
        userUid = providerDoc.data()!['provider_uid'].toString();
      } else {
        // แบบ ข: กรณี PID เป็น Field ข้างในคอลเลกชัน provider (สำรองไว้)
        final providerSnapshot = await db
            .collection('provider')
            .where('pid', isEqualTo: cleanPid)
            .limit(1)
            .get();

        if (providerSnapshot.docs.isNotEmpty) {
          userUid = providerSnapshot.docs.first.data()['provider_uid']?.toString();
        }
      }

      debugPrint('UID ของ users ที่ได้จาก provider = $userUid');

      if (userUid == null || userUid!.isEmpty) {
        throw Exception('ไม่พบ UID ของผู้ใช้ที่ผูกกับ PID: $cleanPid ในคอลเลกชัน provider');
      }

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('loadData error: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // เปิดดูรูปจาก URL
  void showImage(String imageUrl, String title) {
    if (imageUrl.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่พบลิงก์รูปภาพ'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // หัวข้อ
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: Colors.white,
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // รูปภาพ
              Flexible(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder:
                        (context, child, loadingProgress) {
                      if (loadingProgress == null) {
                        return child;
                      }

                      return const SizedBox(
                        height: 400,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const SizedBox(
                        height: 400,
                        child: Center(
                          child: Text(
                            'ไม่สามารถโหลดรูปภาพได้',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // ปุ่มปิด
              Container(
                width: double.infinity,
                color: Colors.white,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'ปิด',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // รายการเอกสาร กดเพื่อดูรูป
  Widget documentImageButton({
    required String title,
    required String? imageUrl,
  }) {
    final url = imageUrl?.trim() ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.image),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          url.isEmpty
              ? 'ไม่มีรูปภาพ'
              : 'กดเพื่อดูรูปภาพ',
        ),
        trailing: url.isEmpty
            ? const Icon(
                Icons.image_not_supported,
                color: Colors.grey,
              )
            : const Icon(
                Icons.visibility,
                color: Colors.blue,
              ),
        onTap: url.isEmpty
            ? null
            : () {
                showImage(url, title);
              },
      ),
    );
  }

  // อนุมัติ
  Future<void> approveProvider() async {
    if (isProcessing) return;

    if (documentId == null || userUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่พบข้อมูลสำหรับอนุมัติ'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isProcessing = true;
    });

    try {
      // users
      await db.collection('users').doc(userUid).update({
        'status_account': 1,
      });

      // document
      await db.collection('document').doc(documentId).update({
        'status_doc': 1,
        'reject_reason': null,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('อนุมัติผู้ให้บริการเรียบร้อยแล้ว'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('อนุมัติไม่สำเร็จ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ปฏิเสธ
  Future<void> rejectProvider() async {
    if (isProcessing) return;

    final reasonController = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ปฏิเสธเอกสาร'),
          content: TextField(
            controller: reasonController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'เหตุผลที่ปฏิเสธ',
              hintText: 'กรุณาระบุเหตุผล',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () {
                final reason = reasonController.text.trim();

                if (reason.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('กรุณาระบุเหตุผล'),
                    ),
                  );
                  return;
                }

                Navigator.pop(context, reason);
              },
              child: const Text(
                'ปฏิเสธ',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    reasonController.dispose();

    if (reason == null || reason.trim().isEmpty) {
      return;
    }

    if (documentId == null || userUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่พบข้อมูลสำหรับปฏิเสธ'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isProcessing = true;
    });

    try {
      // users
      await db.collection('users').doc(userUid).update({
        'status_account': 3,
      });

      // document
      await db.collection('document').doc(documentId).update({
        'status_doc': 2,
        'reject_reason': reason.trim(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ปฏิเสธเอกสารเรียบร้อยแล้ว'),
          backgroundColor: Colors.orange,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ปฏิเสธไม่สำเร็จ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // แสดงหน้า
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.red,
          title: const Text(
            'ตรวจสอบเอกสาร',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          iconTheme: const IconThemeData(
            color: Colors.white,
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (documentData == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.red,
          title: const Text(
            'ตรวจสอบเอกสาร',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          iconTheme: const IconThemeData(
            color: Colors.white,
          ),
        ),
        body: const Center(
          child: Text(
            'ไม่พบข้อมูลเอกสาร',
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    // ดึงข้อมูลจาก Firestore

    final vehicleType = documentData!['vehicle_type'];
    final vehicleRegistration =
        documentData!['vehicle_Registration']?.toString() ?? '';

    final idCard =
        documentData!['IdCard']?.toString() ?? '';

    final drivingLicense =
        documentData!['drivinglicense']?.toString() ?? '';

    final vehicleRegBook =
        documentData!['vehicle_reg_book']?.toString() ?? '';

    final vehicleInsurance =
        documentData!['vehicle_insurance_file']?.toString() ?? '';

    final statusDoc = documentData!['status_doc'] ?? 0;

    final rejectReason =
        documentData!['reject_reason']?.toString() ?? '';

    String vehicleText;

    if (vehicleType.toString() == '1') {
      vehicleText = 'รถยนต์';
    } else if (vehicleType.toString() == '0') {
      vehicleText = 'รถจักรยานยนต์';
    } else {
      vehicleText = vehicleType?.toString() ?? '-';
    }

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        leading: const BackButton(
          color: Colors.white,
        ),
        title: const Text(
          'ตรวจสอบเอกสารผู้ให้บริการ',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.red,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ข้อมูลรถ

            const Text(
              'ข้อมูลยานพาหนะ',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Row(
                      children: [
                        const Text(
                          'ประเภทรถ: ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(vehicleText),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        const Text(
                          'ทะเบียนรถ: ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            vehicleRegistration.isEmpty
                                ? '-'
                                : vehicleRegistration,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            // เอกสาร

            const Text(
              'เอกสารที่เกี่ยวข้อง',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            documentImageButton(
              title: 'บัตรประชาชน',
              imageUrl: idCard,
            ),

            documentImageButton(
              title: 'ใบขับขี่',
              imageUrl: drivingLicense,
            ),

            documentImageButton(
              title: 'เล่มทะเบียนรถ',
              imageUrl: vehicleRegBook,
            ),

            documentImageButton(
              title: 'ประกันภัยรถ',
              imageUrl: vehicleInsurance,
            ),

            const SizedBox(height: 20),

            // สถานะ

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text(
                      'สถานะเอกสาร: ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(width: 10),

                    if (statusDoc == 0)
                      const Text(
                        'รอตรวจสอบ',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                    if (statusDoc == 1)
                      const Text(
                        'อนุมัติแล้ว',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                    if (statusDoc == 2)
                      const Text(
                        'ไม่อนุมัติ',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // เหตุผลที่ปฏิเสธ

            if (statusDoc == 2 &&
                rejectReason.isNotEmpty) ...[
              const SizedBox(height: 15),

              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'เหตุผลที่ปฏิเสธ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(rejectReason),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 30),

            // ปุ่มอนุมัติ / ปฏิเสธ

            if (statusDoc == 0)
              Row(
                children: [

                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          isProcessing
                              ? null
                              : rejectProvider,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding:
                            const EdgeInsets.symmetric(
                          vertical: 15,
                        ),
                      ),
                      child: const Text(
                        'ปฏิเสธ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          isProcessing
                              ? null
                              : approveProvider,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding:
                            const EdgeInsets.symmetric(
                          vertical: 15,
                        ),
                      ),
                      child: isProcessing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child:
                                  CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'อนุมัติ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}