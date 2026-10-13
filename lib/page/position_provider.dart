import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:caremate_application/page/payment_page.dart';
import 'package:caremate_application/page/review.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:longdo_maps_api3_flutter/longdo.dart';
import 'package:longdo_maps_api3_flutter/view.dart';
import 'package:flutter/services.dart';

class PositionProvider extends StatefulWidget {
  final String jobId;
  const PositionProvider({super.key, required this.jobId});

  @override
  State<PositionProvider> createState() => _PositionProviderState();
}

class _PositionProviderState extends State<PositionProvider> {
  final map = GlobalKey<LongdoMapState>();
  var db = FirebaseFirestore.instance;
  int activeStep = 0;
  int jobStatus = 0;
  int? vehicleType;
  int moneyAmount = 0;
  StreamSubscription? jobSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  providerSubscription;

  Map<String, dynamic> detailsJob = {};
  Map<String, dynamic> detailsService = {};
  Map<String, dynamic> detailsUser = {};
  Map<String, dynamic> detailsAddress = {};

  Map<String, dynamic> allDriversData = {};
  Map<String, dynamic> providerData = {};
  Map<String, dynamic> userData = {};
  Map<String, dynamic> documentData = {};
  Map<String, double> getLatLngProvider = {};

  bool isLoading = true;
  bool hasPayment = false;
  bool isCheckingPayment = true;

  bool hasReview = false;
  bool isCheckingReview = true;

  bool _followRider = true;
  double? _providerLat;
  double? _providerLon;

  bool _mapReady = false;

  dynamic _bikeMarker;
  String? _bikeUri;
  String? _carUri;

  @override
  void initState() {
    super.initState();

    _loadIcons();
    loadAll(); // งาน + ที่อยู่ -> ไรเดอร์ + listener ตำแหน่ง -> วาดหมุด
    listenJobStatus(); // ฟังสถานะงานแยกต่างหาก
    checkPayment();
    checkReview();
  }

  Future<void> loadAll() async {
    await queryJobData(); // งาน + ที่อยู่ ต้องมาก่อน
    await queryProviderData(); // ไรเดอร์ + เริ่ม listener ตำแหน่ง

    if (!mounted) return;
    await updateMarkers(); // วาดหมุดปลายทางหลังข้อมูลพร้อม
  }

  Future<void> _loadIcons() async {
    _bikeUri = await assetToDataUri('assets/images/bike1.png');
    _carUri = await assetToDataUri('assets/images/car0.png');
  }

  @override
  void dispose() {
    jobSubscription?.cancel();
    providerSubscription?.cancel();
    super.dispose();
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
              label: Icon(
                Icons.arrow_back_ios,
                color: const Color.fromARGB(255, 255, 255, 255),
              ),
            ),
            Text(
              "พิกัดคนขับ",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        toolbarHeight: 90,
        automaticallyImplyLeading: false,
      ),

      body: Stack(
        children: [
          Positioned(
            right: 16,
            bottom: 120,
            child: FloatingActionButton.small(
              onPressed: () {
                setState(() {
                  _followRider = !_followRider;
                });
              },
              child: Icon(
                _followRider ? Icons.my_location : Icons.location_searching,
              ),
            ),
          ),
          Positioned.fill(
            child: LongdoMapWidget(
              apiKey: "57200903bc3dfd00ca50a47c1bd70f30",
              key: map,
              eventName: [
                IJavascriptChannel(
                  name: "ready",
                  onMessageReceived: (message) async {
                    print("Map Loaded");
                    _mapReady = true;

                    // ถ้ารู้ตำแหน่งรถแล้ว ให้เลื่อนแผนที่ไปที่รถ
                    if (_providerLat != null && _providerLon != null) {
                      map.currentState?.call(
                        "location",
                        args: [
                          {"lon": _providerLon, "lat": _providerLat},
                          true,
                        ],
                      );
                      await Future.delayed(const Duration(milliseconds: 500));
                      map.currentState?.call("zoom", args: [15, true]);
                    }

                    // วาดหมุดปลายทาง เส้นทาง และรถ จากข้อมูลที่โหลดไว้
                    await updateMarkers();
                  },
                ),
              ],
            ),
          ),

          // =========================
          // Bottom Sheet
          // =========================
          DraggableScrollableSheet(
            initialChildSize: 0.28,
            minChildSize: 0.12,
            maxChildSize: 0.80,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(25),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.20),
                      blurRadius: 12,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),

                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.zero,
                  children: [
                    const SizedBox(height: 12),

                    // =========================
                    // Drag Handle
                    // =========================
                    Center(
                      child: Container(
                        width: 45,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),
                    if ([3, 4, 5, 6].contains(jobStatus))
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Row(
                          children: [
                            _buildStep(
                              icon: Icons.directions_car_outlined,
                              title: "กำลังเดินทาง",
                              step: 0,
                            ),

                            _buildLine(0),

                            _buildStep(
                              icon: Icons.person_pin_circle_outlined,
                              title: "ถึงผู้รับบริการ",
                              step: 1,
                            ),

                            _buildLine(1),

                            _buildStep(
                              icon: Icons.location_on_outlined,
                              title: "ถึงปลายทาง",
                              step: 2,
                            ),
                          ],
                        ),
                      ),
                    if ([7, 8, 9].contains(jobStatus))
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Row(
                          children: [
                            _buildStep(
                              icon: Icons.directions_car_outlined,
                              title: "กำลังเดินทางกลับ",
                              step: 0,
                            ),

                            _buildLine(0),

                            _buildStep(
                              icon: Icons.person_pin_circle_outlined,
                              title: "กลับถึงจุดรับงานแล้ว",
                              step: 1,
                            ),

                            _buildLine(1),

                            _buildStep(
                              icon: Icons.location_on_outlined,
                              title: "งานเสร็จสิ้น",
                              step: 2,
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 18),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 25),
                      child: Text(
                        "ข้อมูลคนขับ",
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // =========================
                    // Driver Card
                    // =========================
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),

                      child: Column(
                        children: [
                          // =========================
                          // รูป + ข้อมูลคนขับ
                          // =========================
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // รูปคนขับ
                              Container(
                                width: 95,
                                height: 115,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.grey,
                                  size: 60,
                                ),
                              ),

                              const SizedBox(width: 18),

                              // ข้อมูล
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      userData['realname'] ?? "ไม่พบชื่อผู้ขับ",
                                      style: TextStyle(
                                        fontSize: 21,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    const SizedBox(height: 12),

                                    Row(
                                      children: [
                                        Icon(
                                          Icons.phone,
                                          size: 20,
                                          color: Colors.red.shade600,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            providerData['phone'] ??
                                                "ไม่พบเบอร์โทร",
                                            style: TextStyle(fontSize: 16),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 10),

                                    Row(
                                      children: [
                                        Icon(
                                          Icons.directions_car,
                                          size: 20,
                                          color: Colors.red.shade600,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            documentData['vehicle_Registration'] ??
                                                "ไม่พบทะเบียนรถ",
                                            style: TextStyle(fontSize: 16),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          if (jobStatus == 9) SizedBox(height: 18),
                          if (isCheckingReview)
                            const CircularProgressIndicator()
                          else if (jobStatus == 9 && !hasReview)
                            _paymentButton(
                              icon: Icons.person_outline,
                              text: "รีวิวผู้ให้บริการ",
                              onPressed: () async {
                                print('provider pid: ${providerData['pid']}');
                                print('รหัสงาน: ${widget.jobId}');
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ReviewPage(
                                      jobId: widget.jobId,
                                      pid: providerData['pid'],
                                    ),
                                  ),
                                );

                                if (result == true) {
                                  checkReview();
                                }
                              },
                            )
                          else if (jobStatus == 9 && hasReview)
                            _paymentButton(
                              icon: Icons.check_circle_outline,
                              text: "รีวิวผู้ให้บริการแล้ว",
                              onPressed: null,
                            ),
                          const SizedBox(height: 20),

                          // เส้นแบ่ง
                          Divider(color: Colors.grey.shade300, height: 1),

                          const SizedBox(height: 18),

                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "จำนวนเงินค่าบริการ: ${moneyAmount} บาท",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // =========================
                          // วิธีการชำระเงิน
                          // =========================
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "วิธีการชำระเงิน",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.payments_outlined,
                                    color: Colors.red,
                                    size: 22,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "การชำระเงิน",
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 10),

                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "สามารถชำระค่าบริการได้ 2 วิธี",
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),

                                    SizedBox(height: 10),

                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "• ",
                                          style: TextStyle(fontSize: 15),
                                        ),
                                        Expanded(
                                          child: Text(
                                            "เงินสด สามารถชำระเงินโดยตรงกับผู้ให้บริการ",
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    SizedBox(height: 6),

                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "• ",
                                          style: TextStyle(fontSize: 15),
                                        ),
                                        Expanded(
                                          child: Text(
                                            "โอนเงิน กดปุ่ม \"โอนจ่าย\" เพื่อดูข้อมูลการชำระเงิน",
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 12),

                              if (isCheckingPayment)
                                const CircularProgressIndicator()
                              else if (!hasPayment)
                                _paymentButton(
                                  icon: Icons.account_balance,
                                  text: "โอนจ่าย",
                                  onPressed: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PaymentPage(
                                          jobId: widget.jobId,
                                          providerId: providerData['pid'],
                                          moneyAmount: moneyAmount,
                                        ),
                                      ),
                                    );

                                    if (result == true) {
                                      checkPayment();
                                    }
                                  },
                                )
                              else
                                _paymentButton(
                                  icon: Icons.check_circle_outline,
                                  text: "แนบหลักฐานการชำระเงินแล้ว",
                                  onPressed: null,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _paymentButton({
    required IconData icon,
    required String text,
    VoidCallback? onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 21),

              const SizedBox(width: 8),

              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            "เลือกวิธีชำระเงิน",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.account_balance, color: Colors.blue),
                title: const Text("เลขบัญชี"),
                subtitle: const Text("ชำระเงินผ่านบัญชีธนาคาร"),
                onTap: () {
                  Navigator.pop(context);
                  _showBankAccountDialog();
                },
              ),

              const Divider(),

              ListTile(
                leading: const Icon(Icons.qr_code_2, color: Colors.green),
                title: const Text("QR Code"),
                subtitle: const Text("สแกน QR Code เพื่อชำระเงิน"),
                onTap: () {
                  Navigator.pop(context);
                  _showQrCodeDialog();
                },
              ),

              const Divider(),

              ListTile(
                leading: const Icon(Icons.phone_android, color: Colors.orange),
                title: const Text("เลขพร้อมเพย์"),
                subtitle: const Text("ชำระเงินผ่านพร้อมเพย์"),
                onTap: () {
                  Navigator.pop(context);
                  _showPromptPayDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBankAccountDialog() {
    const accountNumber = "123-4-56789-0";

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("ข้อมูลบัญชีธนาคาร"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("ธนาคาร: กสิกรไทย", style: TextStyle(fontSize: 16)),
              const SizedBox(height: 12),

              Row(
                children: [
                  const Expanded(
                    child: Text(
                      accountNumber,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  IconButton(
                    icon: const Icon(Icons.copy),
                    tooltip: "คัดลอกเลขบัญชี",
                    onPressed: () async {
                      await Clipboard.setData(
                        const ClipboardData(text: accountNumber),
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("คัดลอกเลขบัญชีแล้ว"),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 8),

              const Text("ชื่อบัญชี: CareMate", style: TextStyle(fontSize: 16)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("ปิด"),
            ),
          ],
        );
      },
    );
  }

  void _showQrCodeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("QR Code สำหรับชำระเงิน"),
          content: Image.asset(
            'assets/images/qr_code.png',
            width: 250,
            height: 250,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("ปิด"),
            ),
          ],
        );
      },
    );
  }

  void _showPromptPayDialog() {
    const promptPayNumber = "081-234-5678";

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("ข้อมูลพร้อมเพย์"),
          content: Row(
            children: [
              const Expanded(
                child: Text(
                  promptPayNumber,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),

              IconButton(
                icon: const Icon(Icons.copy),
                tooltip: "คัดลอกเลขพร้อมเพย์",
                onPressed: () async {
                  await Clipboard.setData(
                    const ClipboardData(text: promptPayNumber),
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("คัดลอกเลขพร้อมเพย์แล้ว"),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("ปิด"),
            ),
          ],
        );
      },
    );
  }

  Future<void> checkPayment() async {
    try {
      final snapshot = await db
          .collection('payments')
          .where('job_id', isEqualTo: widget.jobId)
          .limit(1)
          .get();

      if (!mounted) return;

      setState(() {
        hasPayment = snapshot.docs.isNotEmpty;
        isCheckingPayment = false;
      });
    } catch (e) {
      print("เกิดข้อผิดพลาดในการตรวจสอบการชำระเงิน: $e");

      if (!mounted) return;

      setState(() {
        isCheckingPayment = false;
      });
    }
  }

  Future<void> checkReview() async {
    try {
      final snapshot = await db
          .collection('review')
          .where('job_id', isEqualTo: widget.jobId)
          .where('provider_id', isEqualTo: providerData['pid'])
          .get();

      if (!mounted) return;

      setState(() {
        hasReview = snapshot.docs.isNotEmpty;
        isCheckingReview = false;
      });
    } catch (e) {
      print("เกิดข้อผิดพลาดในการตรวจสอบการชำระเงิน: $e");

      if (!mounted) return;

      setState(() {
        isCheckingReview = false;
      });
    }
  }

  Future<void> queryJobData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // 1. ดึงข้อมูล Job
      var docSnapshot = await db.collection('jobs').doc(widget.jobId).get();

      if (docSnapshot.exists) {
        var data = docSnapshot.data();

        detailsJob = {...data!, 'job_id': docSnapshot.id};
      }

      jobStatus = detailsJob['job_status'] ?? 0;
      vehicleType = detailsJob['vehicle_type'];
      updateActiveStep(jobStatus);

      // 2. ดึงข้อมูล Service
      if (detailsJob['service_id'] != null) {
        var serviceDoc = await db
            .collection('service')
            .doc(detailsJob['service_id'])
            .get();

        if (serviceDoc.exists) {
          var data = serviceDoc.data();

          detailsService = {...data!, 'sid': serviceDoc.id};
        }
      }

      // 3. ดึงข้อมูล User
      if (detailsService['service_uid'] != null) {
        var userDoc = await db
            .collection('users')
            .doc(detailsService['service_uid'])
            .get();

        if (userDoc.exists) {
          var data = userDoc.data();

          detailsUser = {...data!, 'uid': userDoc.id};
        }
      }

      // 4. ดึงข้อมูล Address
      if (detailsJob['address_id'] != null) {
        var addressDoc = await db
            .collection('address')
            .doc(detailsJob['address_id'])
            .get();

        if (addressDoc.exists) {
          var data = addressDoc.data();

          detailsAddress = {...data!, 'address_id': addressDoc.id};

          print("Address: $detailsAddress");
        } else {
          print("ไม่พบข้อมูล Address");
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

  Future<void> queryProviderData() async {
    try {
      // 1. หา Provider จาก all_drivers
      final allDrivers = await db
          .collection('all_drivers')
          .where('job_id', isEqualTo: widget.jobId)
          .where('status_drivers', isEqualTo: 4)
          .get();

      if (allDrivers.docs.isEmpty) {
        print("ไม่พบ Provider ที่ได้รับงานนี้");
        return;
      }

      final driverDoc = allDrivers.docs.first;

      final tempAllDriversData = {
        ...driverDoc.data(),
        'all_driver_id': driverDoc.id,
      };

      final String? providerId = tempAllDriversData['provider_id']?.toString();

      print("All Drivers Data: $tempAllDriversData");
      print("Provider ID: $providerId");

      if (providerId == null || providerId.isEmpty) {
        print("ไม่พบ provider_id");
        return;
      }

      // 2. หา Provider
      final providerDoc = await db.collection('provider').doc(providerId).get();

      if (!providerDoc.exists) {
        print("ไม่พบข้อมูล Provider: $providerId");
        return;
      }

      final tempProviderData = {...providerDoc.data()!, 'pid': providerDoc.id};

      final String? userId = tempProviderData['provider_uid']?.toString();

      print("Provider Data: $tempProviderData");
      print("User ID: $userId");

      // 3. หาเอกสารของ Provider
      final documentSnapshot = await db
          .collection('document')
          .where('pid', isEqualTo: providerId)
          .where('vehicle_type', isEqualTo: vehicleType)
          .get();

      Map<String, dynamic> tempDocumentData = {};

      if (documentSnapshot.docs.isNotEmpty) {
        final documentDoc = documentSnapshot.docs.first;

        tempDocumentData = {
          ...documentDoc.data(),
          'document_id': documentDoc.id,
        };

        print("Document Data: $tempDocumentData");
      } else {
        print("ไม่พบเอกสารของ Provider");
      }

      // 5. หา User
      Map<String, dynamic> tempUserData = {};

      if (userId != null && userId.isNotEmpty) {
        final userDoc = await db.collection('users').doc(userId).get();

        if (userDoc.exists) {
          tempUserData = {...userDoc.data()!, 'uid': userDoc.id};

          print("User Data: $tempUserData");
        } else {
          print("ไม่พบข้อมูล User: $userId");
        }
      }

      // 6. เก็บข้อมูลไว้ใช้ใน UI

      if (!mounted) return;

      setState(() {
        allDriversData = tempAllDriversData;
        providerData = tempProviderData;
        documentData = tempDocumentData;
        userData = tempUserData;
      });

      final String locationDocId = (providerData['pid'] ?? '').toString();
      log("Location Doc ID: $locationDocId");
      listenProviderLocation(locationDocId);
    } catch (e) {
      print("Error queryProviderData: $e");
    }
  }

  void listenProviderLocation(String lid) {
    providerSubscription?.cancel(); // กันซ้อน

    providerSubscription = FirebaseFirestore.instance
        .collection('location_provider')
        .doc(lid)
        .snapshots()
        .listen((snapshot) async {
          // เติม async
          final data = snapshot.data();
          if (data == null) {
            log('ยังไม่มีเอกสารตำแหน่งของไรเดอร์');
            return;
          }

          final lat = (data['latitude'] as num?)?.toDouble();
          final lon = (data['longitude'] as num?)?.toDouble();
          if (lat == null || lon == null) return;

          _providerLat = lat;
          _providerLon = lon;
          log('ตำแหน่งไรเดอร์: $lat, $lon');

          await updateBikeMarker(); // เพิ่มบรรทัดนี้

          if (_followRider) {
            map.currentState?.call(
              "location",
              args: [
                {"lon": lon, "lat": lat},
                true, // true = เลื่อนแบบมีแอนิเมชัน
              ],
            );
          }
        }, onError: (e) => print("Rider listen failed: $e"));
  }

  Future<String> assetToDataUri(String path) async {
    final bytes = await rootBundle.load(path);
    final base64Str = base64Encode(bytes.buffer.asUint8List());
    return "data:image/png;base64,$base64Str";
  }

  Future<void> updateMarkers({int? status}) async {
    if (!_mapReady) return;
    final mapState = map.currentState;
    if (mapState == null) return;

    mapState.call("Overlays.clear");
    mapState.call("Route.clear");
    _bikeMarker = null;

    // ใช้สถานะที่ส่งมาก่อน ถ้าไม่ส่งมาก็ใช้ค่าใน detailsJob
    final currentStatus = status ?? detailsJob['job_status'];

    double? lat;
    double? lon;

    if (currentStatus == 4 || currentStatus == 5 || currentStatus == 6) {
      lat = (detailsJob['latitude'] as num?)?.toDouble();
      lon = (detailsJob['longitude'] as num?)?.toDouble();
      log("ปลายทาง: lat = $lat, lon = $lon");
    } else if (currentStatus == 3 ||
        currentStatus == 7 ||
        currentStatus == 8 ||
        currentStatus == 9) {
      lat = (detailsAddress['latitude'] as num?)?.toDouble();
      lon = (detailsAddress['longitude'] as num?)?.toDouble();
      log("ที่อยู่ผู้รับบริการ: lat = $lat, lon = $lon");
    }

    if (lat != null && lon != null) {
      final marker = Longdo.LongdoObject(
        "Marker",
        args: [
          {"lon": lon, "lat": lat},
        ],
      );
      mapState.call("Overlays.add", args: [marker]);
    }

    // ลากเส้นทางจากไรเดอร์ไปหาปลายทาง
    if (lat != null &&
        lon != null &&
        _providerLat != null &&
        _providerLon != null) {
      mapState.call(
        "Route.add",
        args: [
          {"lon": _providerLon, "lat": _providerLat},
        ],
      );
      mapState.call(
        "Route.add",
        args: [
          {"lon": lon, "lat": lat},
        ],
      );
      mapState.call("Route.search");
    }
    if (_providerLat != null) {
      await updateBikeMarker();
    }
  }

  Future<void> updateBikeMarker() async {
    if (!_mapReady) return;

    // ถ้ารูปยังไม่พร้อม ให้รอตรงนี้เท่านั้น (ก่อนแตะ _bikeMarker)
    if (_bikeUri == null || _carUri == null) {
      await _loadIcons();
    }

    // ===== จากนี้ไปห้ามมี await =====
    final mapState = map.currentState;
    final lat = _providerLat;
    final lon = _providerLon;
    if (mapState == null || lat == null || lon == null) return;

    final rawType = detailsJob['vehicle_type'];
    final vehicleType = int.tryParse('$rawType') ?? 0;
    final iconUri = vehicleType == 1 ? _carUri : _bikeUri;
    int _bikeCalls = 0; // ประกาศไว้ในคลาส

    // ในฟังก์ชัน ก่อนเช็ค _bikeMarker
    log(
      "updateBikeMarker #${++_bikeCalls}, มีหมุดเก่า = ${_bikeMarker != null}",
    );

    if (_bikeMarker != null) {
      mapState.call("Overlays.remove", args: [_bikeMarker]);
    }

    _bikeMarker = Longdo.LongdoObject(
      "Marker",
      args: [
        {"lon": lon, "lat": lat},
        {
          "icon": {
            "url": iconUri,
            "offset": {"x": 0, "y": 0},
          },
          "size": {"x": 40, "y": 40},
        },
      ],
    );

    mapState.call("Overlays.add", args: [_bikeMarker]);
  }

  void listenJobStatus() {
    jobSubscription = FirebaseFirestore.instance
        .collection('jobs')
        .doc(widget.jobId)
        .snapshots()
        .listen((snapshot) {
          if (!snapshot.exists) return;

          final data = snapshot.data();

          if (data == null) return;

          final status = data['job_status'] ?? 0;
          final fee = data['service_fee'] ?? 0;

          if (!mounted) return;

          setState(() {
            jobStatus = status;
            moneyAmount = fee;
            updateActiveStep(status);
          });
          // ===== เติมตรงนี้ =====
          detailsJob['job_status'] = status;

          if (providerData.isEmpty) {
            queryProviderData();
          }

          updateMarkers(status: status);
        });
  }

  void updateActiveStep(int status) {
    if (status == 3) {
      activeStep = 0;
    } else if (status == 4) {
      activeStep = 1;
    } else if (status == 5) {
      activeStep = 2;
    } else if (status == 7) {
      activeStep = 0;
    } else if (status == 8) {
      activeStep = 1;
    } else if (status == 9) {
      activeStep = 2;
    }
  }

  Widget _buildStep({
    required IconData icon,
    required String title,
    required int step,
  }) {
    bool finished = step < activeStep;
    bool active = step == activeStep;

    Color color;

    if (finished) {
      color = Colors.green;
    } else if (active) {
      color = Colors.red;
    } else {
      color = Colors.grey.shade300;
    }

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            child: Icon(icon, color: Colors.white, size: 27),
          ),

          const SizedBox(height: 7),

          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
              color: active ? Colors.red : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLine(int step) {
    bool finished = step < activeStep;

    return Expanded(
      child: Container(
        height: 3,
        margin: const EdgeInsets.only(bottom: 25),
        color: finished ? Colors.green : Colors.grey.shade300,
      ),
    );
  }
}
