import 'dart:convert';
import 'dart:developer';

import 'package:caremate_application/page/map_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:longdo_maps_api3_flutter/longdo_maps_api3_flutter.dart';
import '../functions/create_job_functions.dart';

class EditJob extends StatefulWidget {
  final String sid;
  final String jobId;

  const EditJob({super.key, required this.sid, required this.jobId});

  @override
  State<EditJob> createState() => _EditJobState();
}

class _EditJobState extends State<EditJob> {
  final FocusNode placeNameFocusNode = FocusNode();
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
  int ratePerHour = 0;
  int extraPrice = 0;

  int? vehicle;
  int? additionalInfo;

  double? latitudeLocation;
  double? longitudeLocation;

  // พิกัดที่อยู่หลักของผู้รับบริการ (จุดรับ)
  double? pickupLatitude;
  double? pickupLongitude;

  // ระยะทางและอัตราค่าเดินทาง
  double? distanceKm;
  int ratePerKm = 0;

  String mainAddress = "";
  String address_id = "";

  bool isLoadingJob = true;
  bool isUpdatingJob = false;

  List<PreviousPlace> previousPlaces = [];

  @override
  void initState() {
    super.initState();
    initData();
  }

  Future<void> initData() async {
    await queryServiceRatesData();
    await loadPreviousPlacesData();
    await loadJobData();
  }

  @override
  void dispose() {
    placeNameFocusNode.dispose();
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
                        color: Colors.grey.shade50,
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
                      // สถานที่ (Autocomplete)
                      // =========================
                      Row(
                        children: [
                          const Text(
                            "สถานที่ :",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 20),
                          SizedBox(
                            width: 220,
                            child: RawAutocomplete<PreviousPlace>(
                              textEditingController: placeNameController,
                              focusNode: placeNameFocusNode,
                              optionsBuilder:
                                  (TextEditingValue textEditingValue) {
                                    if (textEditingValue.text.isEmpty) {
                                      return const Iterable<
                                        PreviousPlace
                                      >.empty();
                                    }
                                    return previousPlaces.where((place) {
                                      return place.name.toLowerCase().contains(
                                        textEditingValue.text.toLowerCase(),
                                      );
                                    });
                                  },
                              displayStringForOption: (PreviousPlace place) {
                                return place.name;
                              },
                              onSelected: (PreviousPlace place) {
                                setState(() {
                                  placeNameController.text = place.name;
                                  latitudeLocation = place.latitude;
                                  longitudeLocation = place.longitude;
                                });
                              },
                              fieldViewBuilder:
                                  (
                                    BuildContext context,
                                    TextEditingController controller,
                                    FocusNode focusNode,
                                    VoidCallback onFieldSubmitted,
                                  ) {
                                    return TextField(
                                      controller: controller,
                                      focusNode: focusNode,
                                      decoration: const InputDecoration(
                                        hintText: "กรุณากรอกชื่อสถานที่",
                                      ),
                                    );
                                  },
                              optionsViewBuilder:
                                  (
                                    BuildContext context,
                                    AutocompleteOnSelected<PreviousPlace>
                                    onSelected,
                                    Iterable<PreviousPlace> options,
                                  ) {
                                    return Align(
                                      alignment: Alignment.topLeft,
                                      child: Material(
                                        elevation: 4,
                                        child: SizedBox(
                                          width: 220,
                                          child: ListView.builder(
                                            padding: EdgeInsets.zero,
                                            shrinkWrap: true,
                                            itemCount: options.length,
                                            itemBuilder: (context, index) {
                                              final place = options.elementAt(
                                                index,
                                              );
                                              return ListTile(
                                                title: Text(place.name),
                                                onTap: () {
                                                  onSelected(place);
                                                },
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      // =========================
                      // พิกัด
                      // =========================
                      Container(
                        width: 360,
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
                                      const SizedBox(height: 5),
                                      if (distanceKm != null)
                                        Text(
                                          "ระยะทาง(ไป-กลับ): ${distanceKm!.toStringAsFixed(2)} กม.",
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
                                    final double destinationLat =
                                        (result['lat'] as num).toDouble();
                                    final double destinationLon =
                                        (result['lon'] as num).toDouble();

                                    setState(() {
                                      latitudeLocation = destinationLat;
                                      longitudeLocation = destinationLon;
                                    });

                                    if (pickupLatitude == null ||
                                        pickupLongitude == null) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "ไม่พบพิกัดที่อยู่หลัก",
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    final distance = await getRouteDistance(
                                      startLat: pickupLatitude!,
                                      startLon: pickupLongitude!,
                                      endLat: destinationLat,
                                      endLon: destinationLon,
                                    );

                                    if (distance != null) {
                                      setState(() {
                                        distanceKm = distance;
                                      });
                                      updateTotalPrice();
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "ไม่สามารถคำนวณระยะทางได้",
                                          ),
                                        ),
                                      );
                                    }
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
                                ratePerKm = 20; // รถยนต์ = 20 บาท/กม.
                                updateTotalPrice();
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
                                ratePerKm = 10; // มอเตอร์ไซค์ = 10 บาท/กม.
                                updateTotalPrice();
                              });
                            },
                          ),
                          const Text("Bike", style: TextStyle(fontSize: 16)),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // =========================
                      // ลักษณะงาน
                      // =========================
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

                      // =========================
                      // ข้อมูลพิเศษ
                      // =========================
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
                                    toggleable: true,
                                    onChanged: (value) {
                                      setState(() {
                                        if (value == null) {
                                          additionalInfo = null;
                                          extraPrice = 0;
                                        } else {
                                          additionalInfo = value;
                                          extraPrice = 200;
                                        }
                                        updateTotalPrice();
                                      });
                                    },
                                  ),
                                  const Text(
                                    "ผู้ป่วยติดเตียง (+200 บาท)",
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Radio<int>(
                                    value: 1,
                                    groupValue: additionalInfo,
                                    toggleable: true,
                                    onChanged: (value) {
                                      setState(() {
                                        if (value == null) {
                                          additionalInfo = null;
                                          extraPrice = 0;
                                        } else {
                                          additionalInfo = value;
                                          extraPrice = 100;
                                        }
                                        updateTotalPrice();
                                      });
                                    },
                                  ),
                                  const Text(
                                    "ผู้ป่วยนั่งวิลแชร์ (+100 บาท)",
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
  // โหลดราคากลางบริการ
  // =========================================================
  Future<void> queryServiceRatesData() async {
    var serviceRateDoc = await db.collection('service_rates').get();
    if (serviceRateDoc.docs.isNotEmpty) {
      setState(() {
        ratePerHour = serviceRateDoc.docs.first.data()['price_per_hour'] ?? 0;
      });
    }
  }

  // =========================================================
  // โหลดสถานที่เดิม
  // =========================================================
  Future<void> loadPreviousPlacesData() async {
    final places = await loadPreviousPlaces(db: db, serviceId: widget.sid);
    if (!mounted) return;
    setState(() {
      previousPlaces = places;
    });
  }

  // =========================================================
  // โหลดข้อมูลงานเดิม
  // =========================================================
  // =========================================================
  // โหลดข้อมูลงานเดิม
  // =========================================================
  Future<void> loadJobData() async {
    try {
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
        placeNameController.text = data['place_name']?.toString() ?? '';

        latitudeLocation = data['latitude'] != null
            ? (data['latitude'] as num).toDouble()
            : null;

        longitudeLocation = data['longitude'] != null
            ? (data['longitude'] as num).toDouble()
            : null;

        distanceKm = data['distance_km'] != null
            ? (data['distance_km'] as num).toDouble()
            : null;

        dateController.text = data['date']?.toString() ?? '';
        timeStartController.text = data['start_time']?.toString() ?? '';
        timeEndController.text = data['end_time']?.toString() ?? '';

        startTime = parseTime(data['start_time']?.toString());
        endTime = parseTime(data['end_time']?.toString());

        vehicle = data['vehicle_type'] != null
            ? (data['vehicle_type'] as num).toInt()
            : null;

        if (vehicle == 1) {
          ratePerKm = 20;
        } else if (vehicle == 0) {
          ratePerKm = 10;
        }

        jobTypeController.text = data['job_type']?.toString() ?? '';

        additionalInfo = data['additional_info'] != null
            ? (data['additional_info'] as num).toInt()
            : null;

        address_id = data['address_id']?.toString() ?? '';

        if (additionalInfo == 0) {
          extraPrice = 200;
        } else if (additionalInfo == 1) {
          extraPrice = 100;
        } else {
          extraPrice = 0;
        }

        selectedDate = parseDate(data['date']?.toString());

        // =========================================================
        // 1. ดึงราคารวมเดิม (เช่น 1200) ใส่ Controller ตรงๆ
        // =========================================================
        int savedFee =
            int.tryParse(data['service_fee']?.toString() ?? '0') ?? 0;
        priceController.text = "$savedFee";

        // =========================================================
        // 2. ย้อนคำนวณหาค่า price พื้นฐาน (หักค่าระยะทาง + ค่าบริการพิเศษออก)
        // เพื่อให้เวลาเปลี่ยนเวลา/รถภายหลัง สามารถคำนวณต่อได้ถูกต้อง
        // =========================================================
        int distancePrice = 0;
        if (distanceKm != null) {
          distancePrice = (distanceKm! * ratePerKm).ceil();
        }
        price = savedFee - distancePrice - extraPrice;
        if (price < 0) price = 0;

        // *** สำคัญ: ห้ามใส่ calculatePrice(); ตรงนี้เด็ดขาด ***

        isLoadingJob = false;
      });

      await readAddress();
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
      final resultAddress = await db
          .collection("address")
          .where("service_id", isEqualTo: widget.sid)
          .where("main_ad_status", isEqualTo: 1)
          .get();

      if (resultAddress.docs.isNotEmpty) {
        final data = resultAddress.docs.first.data();

        final address =
            "${data['address_details'] ?? ''} ${data['district'] ?? ''} ${data['province'] ?? ''}";
        final addressId = resultAddress.docs.first.id;

        pickupLatitude = (data['latitude'] as num).toDouble();
        pickupLongitude = (data['longitude'] as num).toDouble();

        if (!mounted) return;

        setState(() {
          mainAddress = address;
          if (address_id.isEmpty) {
            address_id = addressId;
          }
        });
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
  // แก้ไขงาน (พร้อม Validation และเช็คเวลาชน)
  // =========================================================
  Future<void> updateJobData() async {
    if (isUpdatingJob) return;

    if (placeNameController.text.isEmpty ||
        latitudeLocation == null ||
        longitudeLocation == null ||
        distanceKm == null ||
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

    final startMinutes = timeToMinutes(timeStartController.text);
    final endMinutes = timeToMinutes(timeEndController.text);

    if (startMinutes >= endMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เวลาสิ้นสุดต้องมากกว่าเวลาเริ่มต้น')),
      );
      return;
    }

    // เช็ควันและเวลาชนกับงานอื่น
    final canCreate = await checkJobTimeConflict(
      db: db,
      serviceId: widget.sid,
      date: dateController.text,
      startTime: timeStartController.text,
      endTime: timeEndController.text,
    );

    if (!canCreate) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "ไม่สามารถแก้ไขงานได้\nงานในวันเดียวกันต้องมีระยะห่างอย่างน้อย 2 ชั่วโมง",
          ),
        ),
      );
      return;
    }

    setState(() {
      isUpdatingJob = true;
    });

    try {
      final data = {
        'place_name': placeNameController.text,
        'latitude': latitudeLocation,
        'longitude': longitudeLocation,
        'distance_km': distanceKm,
        'date': dateController.text,
        'start_time': timeStartController.text,
        'end_time': timeEndController.text,
        'service_fee': int.tryParse(priceController.text) ?? 0,
        'vehicle_type': vehicle,
        'job_type': jobTypeController.text,
        'additional_info': additionalInfo,
        'address_id': address_id,
      };

      await db.collection('jobs').doc(widget.jobId).update(data);

      if (!mounted) return;
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
  // คำนวณระยะทาง
  // =========================================================
  Future<double?> getRouteDistance({
    required double startLat,
    required double startLon,
    required double endLat,
    required double endLon,
  }) async {
    const apiKey = "57200903bc3dfd00ca50a47c1bd70f30";

    final url = Uri.parse(
      "https://api.longdo.com/RouteService/json/route/guide"
      "?flon=$startLon"
      "&flat=$startLat"
      "&tlon=$endLon"
      "&tlat=$endLat"
      "&mode=t"
      "&type=1"
      "&locale=th"
      "&key=$apiKey",
    );

    try {
      final response = await http.get(url);

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);

      if (data['data'] == null || data['data'].isEmpty) return null;

      final distanceMeter = data['data'][0]['distance'];
      if (distanceMeter == null) return null;

      final distance = (distanceMeter as num).toDouble() / 1000 * 2;
      return distance;
    } catch (e) {
      print("getRouteDistance error: $e");
      return null;
    }
  }

  // =========================================================
  // คำนวณราคาตามชั่วโมงและระยะทาง
  // =========================================================
  void calculatePrice() {
    if (startTime != null && endTime != null) {
      int startMinutes = startTime!.hour * 60 + startTime!.minute;
      int endMinutes = endTime!.hour * 60 + endTime!.minute;
      int diff = endMinutes - startMinutes;

      if (diff > 0) {
        int hours = (diff / 60).ceil();
        setState(() {
          price = hours * ratePerHour;
          updateTotalPrice();
        });
      }
    } else {
      price = 0;
    }
  }

  void updateTotalPrice() {
    int distancePrice = 0;

    if (distanceKm != null) {
      distancePrice = (distanceKm! * ratePerKm).ceil();
    }

    int total = price + distancePrice + extraPrice;
    priceController.text = "$total";
  }

  TimeOfDay? parseTime(String? time) {
    if (time == null || time.isEmpty) return null;
    try {
      final parts = time.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      return null;
    }
  }

  DateTime? parseDate(String? date) {
    if (date == null || date.isEmpty) return null;
    try {
      final parts = date.split('/');
      return DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
    } catch (e) {
      return null;
    }
  }
}
