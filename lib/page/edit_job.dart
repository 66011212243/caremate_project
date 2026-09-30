import 'dart:developer';

import 'package:caremate_application/page/map_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:longdo_maps_api3_flutter/longdo_maps_api3_flutter.dart';

class EditJob extends StatefulWidget {
  final String sid;
  final String jobId;

  const EditJob({super.key, required this.sid, required this.jobId});

  @override
  State<EditJob> createState() => _EditJobState();
}

class _EditJobState extends State<EditJob> {
  var db = FirebaseFirestore.instance;

  final map = GlobalKey<LongdoMapState>();

  DateTime? selectedDate;
  DateTime now = DateTime.now();

  TimeOfDay? startTime;
  TimeOfDay? endTime;

  TextEditingController timeStartController = TextEditingController();
  TextEditingController timeEndController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  TextEditingController priceController = TextEditingController();

  TextEditingController placeNameController = TextEditingController();
  TextEditingController jobTypeController = TextEditingController();

  int price = 0;
  int ratePerHour = 100;
  int extraPrice = 0;

  int? vehicle;
  int? additionalInfo;

  double? latitudeLocation;
  double? longitudeLocation;

  String mainAddress = "";
  String address_id = "";

  bool isLoadingJob = true;
  bool isUpdatingJob = false;

  @override
  void initState() {
    super.initState();
    loadJobData();
  }

  @override
  void dispose() {
    timeStartController.dispose();
    timeEndController.dispose();
    dateController.dispose();
    priceController.dispose();
    placeNameController.dispose();
    jobTypeController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),

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
              "แก้ไขรายละเอียดงาน",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        toolbarHeight: 70,
        automaticallyImplyLeading: false,
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      ),

      body: isLoadingJob
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Container(
                child: Padding(
                  padding: const EdgeInsets.only(top: 20, left: 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 350,
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "ที่อยู่หลัก :",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromARGB(255, 255, 0, 0),
                                ),
                              ),

                              Text(mainAddress),
                            ],
                          ),
                        ),
                      ),

                      // =========================
                      // สถานที่
                      // =========================
                      Row(
                        children: [
                          const Text(
                            "สถานที่ :",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(width: 20),

                          SizedBox(
                            width: 220,
                            child: TextField(
                              controller: placeNameController,
                              decoration: const InputDecoration(
                                hintText: "กรุณากรอกชื่อสถานที่",
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      // พิกัด
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "พิกัดที่อยู่",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 12),

                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: Colors.red,
                                  size: 28,
                                ),

                                const SizedBox(width: 10),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        latitudeLocation != null
                                            ? "ละติจูด: $latitudeLocation"
                                            : "ยังไม่ได้เลือกพิกัด",
                                        style: const TextStyle(fontSize: 15),
                                      ),

                                      const SizedBox(height: 5),

                                      Text(
                                        longitudeLocation != null
                                            ? "ลองจิจูด: $longitudeLocation"
                                            : "ยังไม่ได้เลือกพิกัด",
                                        style: const TextStyle(fontSize: 15),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const MapPage(),
                                    ),
                                  );

                                  if (result != null) {
                                    setState(() {
                                      latitudeLocation = result['lat'];
                                      longitudeLocation = result['lon'];
                                    });

                                    log("LatfromMap: $latitudeLocation");

                                    log("LonfromMap: $longitudeLocation");
                                  }
                                },
                                icon: const Icon(Icons.map, color: Colors.red),
                                label: const Text(
                                  "แก้ไขพิกัดที่อยู่",
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.red),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 15),

                      // =========================
                      // วันที่
                      // =========================
                      Row(
                        children: [
                          const Text(
                            "วันที่ :",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(width: 10),

                          SizedBox(
                            width: 200,
                            child: TextField(
                              controller: dateController,
                              readOnly: true,

                              onTap: () async {
                                DateTime initialDate = selectedDate ?? now;

                                // ป้องกันกรณีวันที่เดิมเป็นวันที่ผ่านมาแล้ว
                                if (initialDate.isBefore(
                                  DateTime(now.year, now.month, now.day),
                                )) {
                                  initialDate = now;
                                }

                                DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: initialDate,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime(now.year, 12, 31),
                                );

                                if (picked != null) {
                                  setState(() {
                                    selectedDate = picked;

                                    dateController.text =
                                        "${picked.day}/${picked.month}/${picked.year}";
                                  });
                                }
                              },

                              decoration: const InputDecoration(
                                hintText: "เลือกวันที่",
                                suffixIcon: Icon(Icons.calendar_today),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      // =========================
                      // เวลางาน
                      // =========================
                      Row(
                        children: [
                          const Text(
                            "เวลางาน :",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(width: 10),

                          const Text("จาก", style: TextStyle(fontSize: 14)),

                          const SizedBox(width: 10),

                          SizedBox(
                            width: 70,
                            height: 30,
                            child: TextField(
                              controller: timeStartController,
                              readOnly: true,

                              onTap: () async {
                                TimeOfDay? picked = await showTimePicker(
                                  context: context,
                                  initialTime: startTime ?? TimeOfDay.now(),
                                  builder: (context, child) {
                                    return MediaQuery(
                                      data: MediaQuery.of(
                                        context,
                                      ).copyWith(alwaysUse24HourFormat: true),
                                      child: child!,
                                    );
                                  },
                                );

                                if (picked != null) {
                                  setState(() {
                                    startTime = picked;

                                    timeStartController.text =
                                        "${picked.hour}:${picked.minute.toString().padLeft(2, '0')}";
                                  });

                                  calculatePrice();
                                }
                              },

                              decoration: const InputDecoration(
                                hintText: "hh:mm",
                              ),
                            ),
                          ),

                          const SizedBox(width: 10),

                          const Text("ถึง", style: TextStyle(fontSize: 14)),

                          const SizedBox(width: 10),

                          SizedBox(
                            width: 70,
                            height: 30,
                            child: TextField(
                              controller: timeEndController,
                              readOnly: true,

                              onTap: () async {
                                TimeOfDay? picked = await showTimePicker(
                                  context: context,
                                  initialTime: endTime ?? TimeOfDay.now(),
                                  builder: (context, child) {
                                    return MediaQuery(
                                      data: MediaQuery.of(
                                        context,
                                      ).copyWith(alwaysUse24HourFormat: true),
                                      child: child!,
                                    );
                                  },
                                );

                                if (picked != null) {
                                  setState(() {
                                    endTime = picked;

                                    timeEndController.text =
                                        "${picked.hour}:${picked.minute.toString().padLeft(2, '0')}";
                                  });

                                  calculatePrice();
                                }
                              },

                              decoration: const InputDecoration(
                                hintText: "hh:mm",
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      // =========================
                      // ราคา
                      // =========================
                      Row(
                        children: [
                          const Text(
                            "เรทค่าบริการ:",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(width: 10),

                          SizedBox(
                            width: 120,
                            child: TextField(
                              readOnly: true,
                              controller: priceController,
                              decoration: InputDecoration(
                                hintText: "$ratePerHour บาท / ชม.",
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      // =========================
                      // ประเภทรถ
                      // =========================
                      Row(
                        children: [
                          const Text(
                            "ประเภทรถ:",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(width: 10),

                          Radio<int>(
                            value: 1,
                            groupValue: vehicle,
                            onChanged: (value) {
                              setState(() {
                                vehicle = value;
                                log(vehicle.toString());
                              });
                            },
                          ),

                          const Text("Car", style: TextStyle(fontSize: 16)),

                          const SizedBox(width: 10),

                          Radio<int>(
                            value: 0,
                            groupValue: vehicle,
                            onChanged: (value) {
                              setState(() {
                                vehicle = value;
                                log(vehicle.toString());
                              });
                            },
                          ),

                          const Text("Bike", style: TextStyle(fontSize: 16)),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // ลักษณะงาน
                      Row(
                        children: [
                          const Text(
                            "ลักษณะงาน:",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(width: 10),

                          SizedBox(
                            width: 200,
                            child: TextField(
                              controller: jobTypeController,
                              maxLines: null,
                              decoration: const InputDecoration(
                                hintText: "กรุณากรอกลักษณะงาน",
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      // ข้อมูลพิเศษ
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              const Text(
                                "ข้อมูลพิเศษ:",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const Text(
                                "(ไม่จำเป็น)",
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),

                          const SizedBox(width: 10),

                          Column(
                            children: [
                              Row(
                                children: [
                                  Radio<int>(
                                    value: 0,
                                    groupValue: additionalInfo,
                                    onChanged: (value) {
                                      setState(() {
                                        additionalInfo = value;

                                        extraPrice = 200;

                                        updateTotalPrice();

                                        log(additionalInfo.toString());
                                      });
                                    },
                                  ),

                                  const Text(
                                    "ผู้ป่วยติดเตียง  (+200 บาท)",
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),

                              Row(
                                children: [
                                  Radio<int>(
                                    value: 1,
                                    groupValue: additionalInfo,
                                    onChanged: (value) {
                                      setState(() {
                                        additionalInfo = value;

                                        extraPrice = 100;

                                        updateTotalPrice();

                                        log(additionalInfo.toString());
                                      });
                                    },
                                  ),

                                  const Text(
                                    "ผู้ป่วยนั่งวิลแชร์  (+100 บาท)",
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // =========================
                      // ปุ่มบันทึก
                      // =========================
                      Center(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: isUpdatingJob
                                ? Colors.grey
                                : const Color.fromARGB(255, 255, 0, 0),

                            foregroundColor: Colors.white,

                            padding: const EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 10,
                            ),

                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),

                          onPressed: isUpdatingJob ? null : updateJobData,

                          child: isUpdatingJob
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    ),

                                    SizedBox(width: 10),

                                    Text(
                                      "กำลังบันทึก...",
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  ],
                                )
                              : const Text(
                                  "บันทึกการแก้ไข",
                                  style: TextStyle(fontSize: 18),
                                ),
                        ),
                      ),

                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // =========================================================
  // โหลดข้อมูลงานเดิม
  // =========================================================
  Future<void> loadJobData() async {
    try {
      log("กำลังโหลด Job ID: ${widget.jobId}");

      final doc = await db.collection('jobs').doc(widget.jobId).get();

      if (!doc.exists) {
        if (!mounted) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("ไม่พบข้อมูลงาน")));

        Navigator.pop(context);
        return;
      }

      final data = doc.data()!;

      setState(() {
        // สถานที่
        placeNameController.text = data['place_name']?.toString() ?? '';

        // พิกัด
        latitudeLocation = data['latitude'] != null
            ? (data['latitude'] as num).toDouble()
            : null;

        longitudeLocation = data['longitude'] != null
            ? (data['longitude'] as num).toDouble()
            : null;

        // วันที่
        dateController.text = data['date']?.toString() ?? '';

        // เวลา
        timeStartController.text = data['start_time']?.toString() ?? '';

        timeEndController.text = data['end_time']?.toString() ?? '';

        // แปลงเวลาเดิมกลับเป็น TimeOfDay
        startTime = parseTime(data['start_time']?.toString());

        endTime = parseTime(data['end_time']?.toString());

        // ราคา
        priceController.text = data['service_fee']?.toString() ?? '';

        price = int.tryParse(data['service_fee']?.toString() ?? '') ?? 0;

        // ประเภทรถ
        vehicle = data['vehicle_type'] != null
            ? (data['vehicle_type'] as num).toInt()
            : null;

        // ลักษณะงาน
        jobTypeController.text = data['job_type']?.toString() ?? '';

        // ข้อมูลพิเศษ
        additionalInfo = data['additional_info'] != null
            ? (data['additional_info'] as num).toInt()
            : null;

        // Address ID ของงานเดิม
        address_id = data['address_id']?.toString() ?? '';

        // คำนวณ extraPrice จากข้อมูลเดิม
        if (additionalInfo == 0) {
          extraPrice = 200;
        } else if (additionalInfo == 1) {
          extraPrice = 100;
        } else {
          extraPrice = 0;
        }

        // แปลงวันที่เดิม
        selectedDate = parseDate(data['date']?.toString());

        isLoadingJob = false;
      });

      // โหลดที่อยู่หลัก
      readAddress();

      log("โหลดข้อมูลงานสำเร็จ");
    } catch (e) {
      log("Error loading job: $e");

      if (!mounted) return;

      setState(() {
        isLoadingJob = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("เกิดข้อผิดพลาดในการโหลดข้อมูล: $e")),
      );
    }
  }

  // =========================================================
  // โหลดที่อยู่หลัก
  // =========================================================
  Future<void> readAddress() async {
    try {
      log("readAddress called with sid: ${widget.sid}");

      final resultAddress = await db
          .collection("address")
          .where("service_id", isEqualTo: widget.sid)
          .where("main_ad_status", isEqualTo: 1)
          .get();

      if (resultAddress.docs.isNotEmpty) {
        final data = resultAddress.docs.first.data();

        final address =
            "${data['address_details'] ?? ''} "
            "${data['district'] ?? ''} "
            "${data['province'] ?? ''}";

        final addressId = resultAddress.docs.first.id;

        if (!mounted) return;

        setState(() {
          mainAddress = address;

          // ถ้างานเดิมไม่มี address_id
          // ค่อยใช้ address หลักปัจจุบัน
          if (address_id.isEmpty) {
            address_id = addressId;
          }
        });

        log("Main Address: $mainAddress");
        log("Address ID: $address_id");
      } else {
        if (!mounted) return;

        setState(() {
          mainAddress = "ยังไม่มีที่อยู่หลัก";
        });
      }
    } catch (e) {
      log("Error reading address: $e");
    }
  }

  // =========================================================
  // แก้ไขงาน
  // =========================================================
  Future<void> updateJobData() async {
    // ป้องกันการกดปุ่มซ้ำ
    if (isUpdatingJob) return;

    // ตรวจสอบข้อมูล
    if (placeNameController.text.isEmpty ||
        latitudeLocation == null ||
        longitudeLocation == null ||
        dateController.text.isEmpty ||
        timeStartController.text.isEmpty ||
        timeEndController.text.isEmpty ||
        priceController.text.isEmpty ||
        vehicle == null ||
        jobTypeController.text.isEmpty ||
        address_id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("กรุณากรอกข้อมูลให้ครบทุกช่อง")),
      );

      return;
    }

    // เปลี่ยนสถานะเป็นกำลังบันทึก
    setState(() {
      isUpdatingJob = true;
    });

    try {
      final data = {
        'place_name': placeNameController.text,

        'latitude': latitudeLocation,

        'longitude': longitudeLocation,

        'date': dateController.text,

        'start_time': timeStartController.text,

        'end_time': timeEndController.text,

        'service_fee': priceController.text,

        'vehicle_type': vehicle,

        'job_type': jobTypeController.text,

        'additional_info': additionalInfo,

        'address_id': address_id,
      };

      // UPDATE งานเดิม
      await db.collection('jobs').doc(widget.jobId).update(data);

      log("แก้ไขงานสำเร็จ ID: ${widget.jobId}");

      if (!mounted) return;

      // กลับไปหน้า DetailsJob
      // พร้อมส่ง true กลับไป
      Navigator.pop(context, 'edited');
    } catch (e) {
      log("Error updating job: $e");

      if (!mounted) return;

      setState(() {
        isUpdatingJob = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("เกิดข้อผิดพลาดในการแก้ไขงาน: $e")),
      );
    }
  }

  // =========================================================
  // คำนวณราคา
  // =========================================================
  void calculatePrice() {
    if (startTime != null && endTime != null) {
      log(startTime.toString());
      log(endTime.toString());

      int startMinutes = startTime!.hour * 60 + startTime!.minute;

      int endMinutes = endTime!.hour * 60 + endTime!.minute;

      int diff = endMinutes - startMinutes;

      if (diff > 0) {
        int hours = (diff / 60).ceil();

        setState(() {
          price = hours * ratePerHour;

          updateTotalPrice();

          log("ราคาพื้นฐาน: $price");
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("เวลาสิ้นสุดต้องมากกว่าเวลาเริ่มต้น")),
        );
      }
    } else {
      price = 0;
    }
  }

  // =========================================================
  // รวมราคา
  // =========================================================
  void updateTotalPrice() {
    int total = price + extraPrice;

    priceController.text = total.toString();
  }

  // =========================================================
  // แปลง String เวลา → TimeOfDay
  // =========================================================
  TimeOfDay? parseTime(String? time) {
    if (time == null || time.isEmpty) {
      return null;
    }

    try {
      final parts = time.split(':');

      final hour = int.parse(parts[0]);

      final minute = int.parse(parts[1]);

      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      log("ไม่สามารถแปลงเวลา: $time");

      return null;
    }
  }

  // =========================================================
  // แปลง String วันที่ → DateTime
  // =========================================================
  DateTime? parseDate(String? date) {
    if (date == null || date.isEmpty) {
      return null;
    }

    try {
      final parts = date.split('/');

      final day = int.parse(parts[0]);

      final month = int.parse(parts[1]);

      final year = int.parse(parts[2]);

      return DateTime(year, month, day);
    } catch (e) {
      log("ไม่สามารถแปลงวันที่: $date");

      return null;
    }
  }
}
