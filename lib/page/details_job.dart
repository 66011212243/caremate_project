import 'dart:async';
import 'dart:developer';

import 'package:caremate_application/functions/job_time.dart';
import 'package:caremate_application/page/map_details_page.dart';
import 'package:caremate_application/page/myJob_povider.dart';
import 'package:caremate_application/page/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:longdo_maps_api3_flutter/longdo_maps_api3_flutter.dart';
import '../functions/details_job_functions.dart';

class DetailsJob extends StatefulWidget {
  String pid = '';
  String jobId = '';
  DetailsJob({super.key, required this.jobId, required this.pid});

  @override
  State<DetailsJob> createState() => _DetailsJobState();
}

class _DetailsJobState extends State<DetailsJob> {
  var db = FirebaseFirestore.instance;
  Map<String, dynamic> detailsJob = {};

  int? statusDrivers;
  bool isLoading = true;

  bool isApplied = false;
  bool isApplying = false;

  bool isProviderDataComplete = false;
  bool isCheckingProvider = true;
  bool _isCancelling = false;

  Timer? _timer;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    queryJobData();
    checkApplied();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
              label: Icon(Icons.arrow_back_ios, color: Colors.black),
            ),
            Text(
              "รายละเอียดงาน",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        toolbarHeight: 70,
        automaticallyImplyLeading: false,
      ),

      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : detailsJob.isEmpty
          ? Center(
              child: Text(
                'ไม่มีรายการ',
                style: TextStyle(
                  color: Color.fromARGB(255, 81, 81, 81),
                  fontSize: 16,
                ),
              ),
            )
          : SingleChildScrollView(
              child: Container(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 350,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // หัวข้อการ์ด
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFDE8E8),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'จุดรับผู้รับบริการ',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      SizedBox(height: 3),
                                      Text(
                                        'อ.${detailsJob['district'] ?? '-'} จ.${detailsJob['province'] ?? '-'}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 5),

                            // ข้อความแนะนำ
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 15,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'ตรวจสอบพื้นที่รับงานก่อนตัดสินใจสมัครงาน',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 15),
                      Row(
                        children: [
                          Text(
                            "สถานที่ :",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 10),
                          SizedBox(
                            width: 220,
                            child: Text(
                              detailsJob['place_name'],
                              style: TextStyle(fontSize: 20),
                            ),
                          ),
                        ],
                      ),

                      Padding(
                        padding: const EdgeInsets.only(bottom: 30, top: 30),
                        child: Center(
                          child: SizedBox(
                            width: 300,
                            height: 150,
                            child: Stack(
                              children: [
                                // Longdo Map
                                MapPreview(
                                  latitude: (detailsJob['latitude'] as num)
                                      .toDouble(),
                                  longitude: (detailsJob['longitude'] as num)
                                      .toDouble(),
                                ),

                                // ปุ่มใสครอบ Map
                                Positioned.fill(
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        print("Map Clicked");
                                        print("=== ก่อนเปิด Map ===");
                                        print("Lat: ${detailsJob['latitude']}");
                                        print(
                                          "Lon: ${detailsJob['longitude']}",
                                        );

                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                MapDetailsPage(
                                                  latitude:
                                                      detailsJob['latitude'],
                                                  longitude:
                                                      detailsJob['longitude'],
                                                ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            "วันที่ :",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 10),
                          SizedBox(
                            width: 200,
                            child: Text(
                              detailsJob['date'],
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 15),
                      Row(
                        children: [
                          Text(
                            "เวลางาน :",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text("จาก", style: TextStyle(fontSize: 14)),
                          SizedBox(width: 10),
                          SizedBox(
                            child: Text(
                              detailsJob['start_time'],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Text("ถึง", style: TextStyle(fontSize: 14)),
                          SizedBox(width: 10),
                          SizedBox(
                            child: Text(
                              detailsJob['end_time'],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 15),
                      Row(
                        children: [
                          Text(
                            "ระยะทาง(ไป-กลับ):",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 10),
                          SizedBox(
                            width: 120,
                            child: Text(
                              "${detailsJob['distance_km'] ?? '-'} กิโลเมตร",
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 15),
                      Row(
                        children: [
                          Text(
                            "เรทค่าบริการ:",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 10),
                          SizedBox(
                            width: 120,
                            child: Text(
                              "${detailsJob['service_fee']} บาท",
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 15),
                      Row(
                        children: [
                          Text(
                            "ประเภทรถ:",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 10),

                          Text(
                            detailsJob['vehicle_type'] == 0
                                ? "Bike (มอเตอร์ไซค์)"
                                : "Car (รถยนต์)",
                            style: TextStyle(fontSize: 16),
                          ),

                          SizedBox(width: 10),
                        ],
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            "ลักษณะงาน:",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 10),
                          SizedBox(
                            width: 200,
                            child: Text(
                              detailsJob['job_type'],
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 15),
                      if (detailsJob['additional_info'] != null)
                        Row(
                          children: [
                            Text(
                              "ข้อมูลพิเศษ:",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              detailsJob['additional_info'] == 0
                                  ? "ผู้ป่วยติดเตียง"
                                  : "ผู้ป่วยนั่งวิลแชร์",
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      SizedBox(height: 30),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ปุ่มสมัครงาน / แสดงสถานะ
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: TextButton.icon(
                              onPressed: isApplying || statusDrivers != null
                                  ? null
                                  : () async {
                                      setState(() {
                                        isApplying = true;
                                      });

                                      final complete =
                                          await checkProviderDataComplete();
                                      if (!mounted) return;

                                      if (!complete) {
                                        setState(() => isApplying = false);
                                        showProviderIncompleteDialog(context);
                                        return;
                                      }

                                      final vehicleOk =
                                          await checkVehicleTypeComplete(
                                            detailsJob['vehicle_type'],
                                          );
                                      if (!mounted) return;

                                      if (!vehicleOk) {
                                        setState(() => isApplying = false);
                                        showVehicleMismatchDialog(context);
                                        return;
                                      }

                                      final canApply = await checkTimeComplete(
                                        detailsJob['date'],
                                        detailsJob['start_time'],
                                        detailsJob['end_time'],
                                      );

                                      if (!canApply) {
                                        setState(() => isApplying = false);
                                        showTimeMismatchDialog(context);
                                        return;
                                      }

                                      await applyJob(widget.jobId);

                                      if (!mounted) return;
                                      setState(() {
                                        isApplying = false;
                                        statusDrivers = 0;
                                      });
                                    },
                              icon: isApplying
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Icon(
                                      statusDrivers == null
                                          ? Icons.work_outline
                                          : statusDrivers == 0
                                          ? Icons.hourglass_empty
                                          : statusDrivers == 1 ||
                                                statusDrivers == 5
                                          ? Icons.check_circle_outline
                                          : statusDrivers == 2 ||
                                                statusDrivers == 6 ||
                                                statusDrivers == 7
                                          ? Icons.info_outline
                                          : Icons.directions_car,
                                      size: 22,
                                    ),
                              label: Text(
                                isApplying
                                    ? 'กำลังสมัครงาน...'
                                    : statusDrivers == null
                                    ? 'สมัครงาน'
                                    : statusDrivers == 0
                                    ? 'รอคัดเลือก'
                                    : statusDrivers == 1
                                    ? 'ได้รับงานแล้ว'
                                    : statusDrivers == 2
                                    ? 'ตำแหน่งเต็ม'
                                    : statusDrivers == 6
                                    ? 'ไม่สามารถสมัครงานได้'
                                    : statusDrivers == 7
                                    ? 'ถูกยกเลิกแล้ว'
                                    : statusDrivers == 3
                                    ? 'พร้อมทำงาน'
                                    : statusDrivers == 4
                                    ? 'กำลังทำงาน'
                                    : statusDrivers == 5
                                    ? 'งานเสร็จสิ้น'
                                    : 'ไม่ทราบสถานะ',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                backgroundColor: isApplying
                                    ? const Color.fromARGB(255, 110, 110, 110)
                                    : statusDrivers == null
                                    ? Colors.red
                                    : statusDrivers == 0
                                    ? const Color.fromARGB(255, 110, 110, 110)
                                    : statusDrivers == 1 ||
                                          statusDrivers == 3 ||
                                          statusDrivers == 4 ||
                                          statusDrivers == 5
                                    ? const Color.fromARGB(255, 15, 221, 0)
                                    : statusDrivers == 2 ||
                                          statusDrivers == 6 ||
                                          statusDrivers == 7
                                    ? const Color.fromARGB(255, 220, 109, 102)
                                    : Colors.black,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: isApplying
                                    ? const Color.fromARGB(255, 110, 110, 110)
                                    : statusDrivers == 0
                                    ? const Color.fromARGB(255, 110, 110, 110)
                                    : statusDrivers == 1 ||
                                          statusDrivers == 3 ||
                                          statusDrivers == 4 ||
                                          statusDrivers == 5
                                    ? const Color.fromARGB(255, 15, 221, 0)
                                    : statusDrivers == 2 ||
                                          statusDrivers == 6 ||
                                          statusDrivers == 7
                                    ? const Color.fromARGB(255, 220, 109, 102)
                                    : const Color.fromARGB(255, 15, 221, 0),
                                disabledForegroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),

                          // ปุ่มยกเลิกสมัครงาน
                          if (statusDrivers == 0) ...[
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  showCancelApplyDialog(
                                    context,
                                    onConfirm: () async {
                                      await cancelApplyJob();
                                    },
                                  );
                                },
                                icon: const Icon(
                                  Icons.cancel_outlined,
                                  size: 20,
                                ),
                                label: const Text(
                                  'ยกเลิกสมัครงาน',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],

                          // ปุ่มยกเลิกงานที่ได้รับแล้ว
                          if (statusDrivers == 1 || statusDrivers == 3) ...[
                            const SizedBox(height: 10),

                            if (_canCancel)
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: OutlinedButton.icon(
                                  onPressed: _isCancelling
                                      ? null
                                      : () async {
                                          if (!_canCancel) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'ไม่สามารถยกเลิกงานได้ภายใน 2 ชั่วโมงก่อนเริ่มงาน',
                                                ),
                                              ),
                                            );
                                            return;
                                          }

                                          await showCancelJobDialog(
                                            context,
                                            cancelCount:
                                                (detailsJob['cancel_job']
                                                        as num?)
                                                    ?.toInt() ??
                                                0,
                                            onConfirm: () async {
                                              setState(() {
                                                _isCancelling = true;
                                              });

                                              try {
                                                await cancelJob();
                                              } finally {
                                                if (mounted) {
                                                  setState(() {
                                                    _isCancelling = false;
                                                  });
                                                }
                                              }
                                            },
                                          );
                                        },
                                  icon: _isCancelling
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.red,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.cancel_outlined,
                                          size: 20,
                                        ),
                                  label: Text(
                                    _isCancelling
                                        ? 'กำลังยกเลิกงาน...'
                                        : 'ยกเลิกงาน',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              )
                            else if (_isLocked)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  "ไม่สามารถยกเลิกงานได้ภายใน 2 ชั่วโมงก่อนเริ่มงาน",
                                  style: TextStyle(color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                          ],
                        ],
                      ),
                      SizedBox(height: 50),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Future<void> queryJobData() async {
    setState(() {
      isLoading = true;
    });

    try {
      var docSnapshot = await db.collection('jobs').doc(widget.jobId).get();

      if (docSnapshot.exists) {
        var data = docSnapshot.data();

        detailsJob = {...data!, 'job_id': docSnapshot.id};

        final addressId = data['address_id'];
        if (addressId != null && addressId.toString().isNotEmpty) {
          final addressSnapshot = await db
              .collection('address')
              .doc(addressId.toString())
              .get();

          if (addressSnapshot.exists) {
            final addressData = addressSnapshot.data()!;

            detailsJob = {
              ...detailsJob,
              'district': addressData['district'],
              'province': addressData['province'],
            };
          }
        }

        final providerSnapshot = await db
            .collection('provider')
            .doc(widget.pid)
            .get();

        if (providerSnapshot.exists) {
          final providerData = providerSnapshot.data()!;
          detailsJob = {
            ...detailsJob,
            'cancel_job': providerData['cancel_job'] ?? 0,
          };
        }
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching jobs: $e");

      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> applyJob(String jobId) async {
    var driverDoc = db.collection('all_drivers').doc();
    var data = {
      'provider_id': widget.pid,
      'job_id': jobId,
      'applied_at': FieldValue.serverTimestamp(),
      'status_drivers': 0,
    };
    log("data ที่กำลังบันทึก: $data");

    await driverDoc.set(data);
    await NotificationService().notifyService(jobId: jobId);
  }

  Future<void> checkApplied() async {
    var snapshot = await db
        .collection('all_drivers')
        .where('provider_id', isEqualTo: widget.pid)
        .where('job_id', isEqualTo: widget.jobId)
        .get();

    print("จำนวนเอกสาร: ${snapshot.docs.length}");

    if (snapshot.docs.isNotEmpty) {
      var data = snapshot.docs.first.data();

      print("ข้อมูล: $data");

      setState(() {
        isApplied = true;
        statusDrivers = data['status_drivers'];
        print("statusDrivers ตอนสร้างปุ่ม: $statusDrivers");
        print("isApplying: $isApplying");
      });
    }
  }

  Future<void> cancelApplyJob() async {
    var snapshot = await db
        .collection('all_drivers')
        .where('provider_id', isEqualTo: widget.pid)
        .where('job_id', isEqualTo: widget.jobId)
        .get();

    if (snapshot.docs.isNotEmpty) {
      var docId = snapshot.docs.first.id;

      await db.collection('all_drivers').doc(docId).delete();

      setState(() {
        isApplied = false;
        statusDrivers = null;
      });
    }
  }

  Future<void> cancelJob() async {
    final allowed = await canCancelJob();

    if (!allowed) return;
    try {
      // 1. ค้นหาผู้สมัครทั้งหมดของงานนี้
      final snapshot = await db
          .collection('all_drivers')
          .where('job_id', isEqualTo: widget.jobId)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();

        if (data['provider_id'] == widget.pid) {
          // คนขับที่ได้รับงานยกเลิก → เปลี่ยนสถานะเป็น 6
          await doc.reference.update({'status_drivers': 6});
        } else if (data['status_drivers'] == 2) {
          // ผู้สมัครที่ตำแหน่งเต็ม → ลบออกตามระบบเดิม
          await doc.reference.delete();
        }
      }

      // 2. เปลี่ยนสถานะงานกลับเป็น 0
      await db.collection('jobs').doc(widget.jobId).update({'job_status': 0});
      await incrementCancelCount();

      if (!mounted) return;
      await NotificationService().notifyServiceProviderCancelledJob(
        jobId: widget.jobId,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ยกเลิกงานเรียบร้อยแล้ว คนขับคนอื่นสามารถสมัครได้'),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('เกิดข้อผิดพลาดในการยกเลิกงาน: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ยกเลิกงานไม่สำเร็จ กรุณาลองใหม่')),
      );
    }
  }

  Future<bool> canCancelJob() async {
    final now = DateTime.now();

    final currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    final providerRef = db.collection('provider').doc(widget.pid);

    final snapshot = await providerRef.get();
    final data = snapshot.data();

    final savedMonth = data?['cancel_month'] as String?;
    final cancelCount = (data?['cancel_job'] as num?)?.toInt() ?? 0;

    // ถ้าเป็นเดือนใหม่ ให้ถือว่ายังยกเลิกไป 0 ครั้ง
    final count = savedMonth == currentMonth ? cancelCount : 0;

    if (count >= 3) {
      if (!mounted) return false;

      await showCancelLimitDialog(context);

      return false;
    }

    return true;
  }

  Future<void> incrementCancelCount() async {
    final now = DateTime.now();

    // รูปแบบปี-เดือน เช่น 2026-10
    final currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    final providerRef = db.collection('provider').doc(widget.pid);

    await db.runTransaction((transaction) async {
      final snapshot = await transaction.get(providerRef);
      final data = snapshot.data();

      final savedMonth = data?['cancel_month'] as String?;
      final currentCount = (data?['cancel_job'] as num?)?.toInt() ?? 0;

      // เดือนเดิมให้นับต่อ เดือนใหม่เริ่มนับจาก 1
      final nextCount = savedMonth == currentMonth ? currentCount + 1 : 1;

      transaction.set(providerRef, {
        'cancel_job': nextCount,
        'cancel_month': currentMonth,
      }, SetOptions(merge: true));
    });
  }

  bool _hasValue(dynamic v) => v != null && v.toString().trim().isNotEmpty;

  /// คืนค่า true ถ้าข้อมูลครบ
  Future<bool> checkProviderDataComplete() async {
    try {
      // 1. ตรวจสอบข้อมูลผู้ให้บริการ
      final providerDoc = await db.collection('provider').doc(widget.pid).get();

      final data = providerDoc.data();

      if (!providerDoc.exists || data == null) return false;

      final isProviderComplete =
          _hasValue(data['phone']) &&
          _hasValue(data['gender']) &&
          _hasValue(data['profile']);

      if (!isProviderComplete) return false;

      // 2. ตรวจสอบข้อมูลธนาคาร
      final bankQuery = await db
          .collection('bank')
          .where('provider_id', isEqualTo: widget.pid)
          .limit(1)
          .get();

      if (bankQuery.docs.isEmpty) return false;

      final bankData = bankQuery.docs.first.data();

      // 3. ตรวจสอบว่าข้อมูลธนาคารครบทุกช่อง
      return _hasValue(bankData['bank_name']) &&
          _hasValue(bankData['account_number']) &&
          _hasValue(bankData['account_name']) &&
          _hasValue(bankData['qr_code']) &&
          _hasValue(bankData['promptpay']);
    } catch (e) {
      print("Error checking provider data: $e");
      return false;
    }
  }

  Future<bool> checkVehicleTypeComplete(int vehicleType) async {
    try {
      final result = await db
          .collection('document')
          .where('pid', isEqualTo: widget.pid)
          .where('vehicle_type', isEqualTo: vehicleType)
          .where('status_doc', isEqualTo: 1)
          .limit(1)
          .get();

      return result.docs.isNotEmpty;
    } catch (e) {
      print("Error checking vehicle type: $e");
      return false;
    }
  }

  /// return true  = สมัครได้ (ไม่ชนกับงานอื่น)
  /// return false = สมัครไม่ได้ (เวลาซ้อน/ห่างไม่ถึง 2 ชม. หรือเช็คไม่สำเร็จ)
  Future<bool> checkTimeComplete(
    String date,
    String startTime,
    String endTime,
  ) async {
    const int minGapMinutes = 120; // ต้องห่างกันอย่างน้อย 2 ชม.

    try {
      // 1) งานที่ provider คนนี้สมัครไว้ และสถานะ 1, 3, 4
      final result = await db
          .collection('all_drivers')
          .where('provider_id', isEqualTo: widget.pid)
          .where('status_drivers', whereIn: [1, 3, 4])
          .get();

      // ไม่มีงานที่สมัครไว้เลย → สมัครได้
      if (result.docs.isEmpty) {
        return true;
      }

      // 2) ดึงข้อมูลงานทั้งหมดพร้อมกัน
      final jobDocs = await Future.wait(
        result.docs.map((d) {
          final jobId = d.data()['job_id'];
          return db.collection('jobs').doc(jobId).get();
        }),
      );

      // 3) เวลาของงานใหม่ (นาที)
      final newStart = timeToMinutes(startTime);
      var newEnd = timeToMinutes(endTime);
      if (newEnd <= newStart) newEnd += 1440; // งานข้ามเที่ยงคืน

      for (final jobDoc in jobDocs) {
        if (!jobDoc.exists) continue;

        final job = jobDoc.data()!;

        // 4) คนละวัน → ข้ามไป
        if (job['date'] != date) continue;

        // 5) วันเดียวกัน → เช็คเวลา
        final oldStart = timeToMinutes(job['start_time']);
        var oldEnd = timeToMinutes(job['end_time']);
        if (oldEnd <= oldStart) oldEnd += 1440;

        // ชนกัน = เวลาซ้อน หรือห่างน้อยกว่า 2 ชม.
        final isConflict =
            newStart < oldEnd + minGapMinutes &&
            oldStart < newEnd + minGapMinutes;

        if (isConflict) {
          return false;
        }
      }

      // ไม่ชนกับงานไหนเลย
      return true;
    } catch (e) {
      print("checkTimeComplete error: $e");

      // เช็คไม่ได้ → ไม่ให้สมัคร
      return false;
    }
  }

  // แปลงเวลา เช่น 08:30 → 510 นาที
  int timeToMinutes(String time) {
    final parts = time.split(':');

    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    return (hour * 60) + minute;
  }

  DateTime? get _startTime => jobStartTime(detailsJob);

  bool get _isLocked {
    final start = _startTime;
    if (start == null) return false;

    if (statusDrivers == 3) return true; // ล็อกอยู่แล้ว

    if (statusDrivers == 1) {
      return start.difference(DateTime.now()) <= const Duration(hours: 2);
    }

    return false;
  }

  // ยกเลิกได้: ได้งานแล้ว (1) และเหลือเวลาเกิน 2 ชม
  bool get _canCancel {
    final start = _startTime;
    if (start == null) return false;

    return statusDrivers == 1 &&
        start.difference(DateTime.now()) > const Duration(hours: 2);
  }
}

class MapPreview extends StatefulWidget {
  final double latitude;
  final double longitude;

  const MapPreview({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<MapPreview> createState() => _MapPreviewState();
}

class _MapPreviewState extends State<MapPreview> {
  final _map = GlobalKey<LongdoMapState>();
  bool _ready = false;

  Future<void> _moveToJob() async {
    final lat = widget.latitude;
    final lon = widget.longitude;
    debugPrint('Longdo target => lat: $lat, lon: $lon');

    try {
      // ย้ายแผนที่
      _map.currentState?.call(
        "location",
        args: [
          {"lon": lon, "lat": lat},
          true,
        ],
      );
      await Future.delayed(const Duration(milliseconds: 400));

      // ซูม
      _map.currentState?.call("zoom", args: [14]);
      await Future.delayed(const Duration(milliseconds: 300));

      // ล้างหมุดเก่า (กันหมุดซ้อนเวลาพิกัดเปลี่ยน) แล้วปักใหม่
      _map.currentState?.call("Overlays.clear");
      final marker = Longdo.LongdoObject(
        "Marker",
        args: [
          {"lon": lon, "lat": lat},
        ],
      );
      _map.currentState?.call("Overlays.add", args: [marker]);
    } catch (e) {
      debugPrint("Longdo Map Error: $e");
    }
  }

  @override
  void didUpdateWidget(covariant MapPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ถ้าพิกัดเปลี่ยนหลังแผนที่พร้อมแล้ว (เช่น ข้อมูลงานโหลดมาทีหลัง) ให้ย้ายตาม
    if (_ready &&
        (oldWidget.latitude != widget.latitude ||
            oldWidget.longitude != widget.longitude)) {
      _moveToJob();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      width: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            blurRadius: 3,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: LongdoMapWidget(
          apiKey: "57200903bc3dfd00ca50a47c1bd70f30",
          key: _map,
          eventName: [
            IJavascriptChannel(
              name: "ready",
              onMessageReceived: (message) async {
                if (_ready) return;
                _ready = true;
                await Future.delayed(const Duration(milliseconds: 1000));
                await _moveToJob();
              },
            ),
          ],
        ),
      ),
    );
  }
}
