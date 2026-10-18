import 'dart:developer';
import 'package:caremate_application/functions/job_time.dart';
import 'package:caremate_application/page/homepage_service.dart';
import 'package:caremate_application/page/map_page.dart';
import 'package:caremate_application/page/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:longdo_maps_api3_flutter/longdo_maps_api3_flutter.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../functions/create_job_functions.dart';

class CreateJob extends StatefulWidget {
  final String sid;
  final String uid;

  const CreateJob({super.key, required this.sid, required this.uid});

  @override
  State<CreateJob> createState() => _CreateJobState();
}

class _CreateJobState extends State<CreateJob> {
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

  // พิกัดที่อยู่หลักของผู้รับบริการ
  double? pickupLatitude;
  double? pickupLongitude;

  // ระยะทางจากจุดรับไปปลายทาง
  double? distanceKm;
  int ratePerKm = 0;

  String mainAddress = "";
  String address_id = "";

  bool isCreatingJob = false;

  List<PreviousPlace> previousPlaces = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    readAddress();
    queryServiceRatesData();
    loadPreviousPlacesData();
  }

  @override
  void dispose() {
    placeNameFocusNode.dispose();
    placeNameController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
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
              "สร้างงาน",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        toolbarHeight: 70,
        automaticallyImplyLeading: false,
        backgroundColor: Color.fromARGB(255, 255, 255, 255),
      ),

      body: SingleChildScrollView(
        child: Container(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 350,
                  // height: 70,
                  color: Colors.grey.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
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
                Row(
                  children: [
                    Text(
                      "สถานที่ :",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 20),
                    SizedBox(
                      width: 220,
                      child: RawAutocomplete<PreviousPlace>(
                        textEditingController: placeNameController,
                        focusNode: placeNameFocusNode,

                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return const Iterable<PreviousPlace>.empty();
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

                        onSelected: (PreviousPlace place) async {
                          // เลือกชื่อสถานที่และกำหนดพิกัดปลายทาง
                          setState(() {
                            placeNameController.text = place.name;
                            latitudeLocation = place.latitude;
                            longitudeLocation = place.longitude;
                            distanceKm = null; // ล้างระยะทางเดิมก่อนคำนวณใหม่
                          });

                          // ตรวจสอบว่ามีพิกัดจุดรับหรือไม่
                          if (pickupLatitude == null ||
                              pickupLongitude == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('ไม่พบพิกัดที่อยู่หลัก'),
                              ),
                            );
                            return;
                          }

                          try {
                            // คำนวณระยะทางตามถนนจากจุดรับไปยังสถานที่ที่เลือก
                            final distance = await getRouteDistance(
                              startLat: pickupLatitude!,
                              startLon: pickupLongitude!,
                              endLat: place.latitude,
                              endLon: place.longitude,
                            );

                            if (!mounted) return;

                            if (distance != null) {
                              setState(() {
                                distanceKm = distance;
                              });

                              updateTotalPrice();

                              print(
                                'ระยะทางจากจุดรับถึงปลายทาง: '
                                '${distance.toStringAsFixed(2)} กม.',
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('ไม่สามารถคำนวณระยะทางได้'),
                                ),
                              );
                            }
                          } catch (e) {
                            debugPrint('คำนวณระยะทางไม่สำเร็จ: $e');

                            if (!mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'เกิดข้อผิดพลาดในการคำนวณระยะทาง',
                                ),
                              ),
                            );
                          }
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
                              AutocompleteOnSelected<PreviousPlace> onSelected,
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
                                        final place = options.elementAt(index);

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

                Container(
                  //width: double.infinity,
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
                              crossAxisAlignment: CrossAxisAlignment.start,
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

                              print("จุดรับ Lat: $pickupLatitude");
                              print("จุดรับ Lon: $pickupLongitude");

                              print("ปลายทาง Lat: $destinationLat");
                              print("ปลายทาง Lon: $destinationLon");

                              // ตรวจสอบว่ามีพิกัดจุดรับหรือไม่
                              if (pickupLatitude == null ||
                                  pickupLongitude == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("ไม่พบพิกัดที่อยู่หลัก"),
                                  ),
                                );
                                return;
                              }

                              // คำนวณระยะทางตามถนน
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

                                print(
                                  "ระยะทางจากจุดรับถึงปลายทาง: "
                                  "${distance.toStringAsFixed(2)} กม.",
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("ไม่สามารถคำนวณระยะทางได้"),
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.map, color: Colors.red),
                          label: const Text(
                            "เพิ่มพิกัดปลายทาง",
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
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
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
                      child: TextField(
                        controller: dateController,
                        readOnly: true,
                        onTap: () async {
                          DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate ?? now,
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
                        decoration: InputDecoration(
                          hintText: "เลือกวันที่",
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
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
                      width: 70,
                      height: 30,
                      child: TextField(
                        controller: timeStartController,
                        readOnly: true,
                        onTap: () async {
                          TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
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
                          }
                          calculatePrice();
                        },
                        decoration: InputDecoration(hintText: "hh:mm"),
                      ),
                    ),
                    SizedBox(width: 10),
                    Text("ถึง", style: TextStyle(fontSize: 14)),
                    SizedBox(width: 10),
                    SizedBox(
                      width: 70,
                      height: 30,
                      child: TextField(
                        controller: timeEndController,
                        readOnly: true,
                        onTap: () async {
                          TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
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
                          }
                          calculatePrice();
                        },

                        decoration: InputDecoration(hintText: "hh:mm"),
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

                SizedBox(height: 15),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 9),
                      child: Text(
                        "ประเภทรถ:",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    Column(
                      children: [
                        Row(
                          children: [
                            Radio(
                              value: 1,
                              groupValue: vehicle,
                              onChanged: (value) {
                                setState(() {
                                  vehicle = value;

                                  // รถยนต์ = 20 บาท/กม.
                                  ratePerKm = 20;

                                  // คำนวณราคารวมใหม่
                                  updateTotalPrice();

                                  log("Vehicle: $vehicle");
                                  log("Rate per km: $ratePerKm");
                                });
                              },
                            ),
                            const Text(
                              "Car (20บาท /กม.)",
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Radio(
                              value: 0,
                              groupValue: vehicle,
                              onChanged: (value) {
                                setState(() {
                                  vehicle = value;

                                  // มอเตอร์ไซค์ = 10 บาท/กม.
                                  ratePerKm = 10;

                                  // คำนวณราคารวมใหม่
                                  updateTotalPrice();

                                  log("Vehicle: $vehicle");
                                  log("Rate per km: $ratePerKm");
                                });
                              },
                            ),
                            const Text(
                              "Bike (10บาท /กม.)",
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),

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
                      child: TextField(
                        controller: jobTypeController,
                        maxLines: null,
                        decoration: InputDecoration(
                          hintText: "กรุณากรอกลักษณะงาน",
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 15),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 9),
                          child: Text(
                            "ข้อมูลพิเศษ:",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          "(ไม่จำเป็น)",
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),

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
                                    // กดย้ำอันเดิม = ยกเลิก
                                    additionalInfo = null;
                                    extraPrice = 0;
                                  } else {
                                    // เลือกผู้ป่วยติดเตียง
                                    additionalInfo = value;
                                    extraPrice = 200;
                                  }

                                  updateTotalPrice();

                                  print("additionalInfo: $additionalInfo");
                                  print("extraPrice: $extraPrice");
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
                                    // กดย้ำอันเดิม = ยกเลิก
                                    additionalInfo = null;
                                    extraPrice = 0;
                                  } else {
                                    // เลือกผู้ป่วยนั่งวิลแชร์
                                    additionalInfo = value;
                                    extraPrice = 100;
                                  }

                                  updateTotalPrice();

                                  print("additionalInfo: $additionalInfo");
                                  print("extraPrice: $extraPrice");
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
                SizedBox(height: 30),
                Center(
                  child: SizedBox(
                    width: 220,
                    height: 48,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 255, 0, 0),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: isCreatingJob ? null : addJobData,
                      child: isCreatingJob
                          ? const Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'กำลังสร้างงาน...',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ],
                            )
                          : const Text(
                              'สร้างงาน',
                              style: TextStyle(fontSize: 18),
                            ),
                    ),
                  ),
                ),
                SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> addJobData() async {
    // ป้องกันการกดซ้ำ
    if (isCreatingJob) return;

    // ตรวจข้อมูลในฟอร์ม
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
        address_id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("กรุณากรอกข้อมูลให้ครบทุกช่อง")),
      );
      return;
    }

    // =========================
    // เช็คเวลาเริ่ม - เวลาสิ้นสุด
    // =========================
    final startMinutes = timeToMinutes(timeStartController.text);

    final endMinutes = timeToMinutes(timeEndController.text);

    if (startMinutes >= endMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เวลาสิ้นสุดต้องมากกว่าเวลาเริ่มต้น')),
      );
      return;
    }

    // =====================================
    // ตรวจสอบวันและเวลาชนกับงานเดิม
    // =====================================

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
            "ไม่สามารถสร้างงานได้\n"
            "งานในวันเดียวกันต้องมีระยะห่างอย่างน้อย 2 ชั่วโมง",
          ),
        ),
      );

      return;
    }

    // =====================================
    // ผ่านการตรวจสอบ → สร้างงาน
    // =====================================

    setState(() {
      isCreatingJob = true;
    });

    try {
      final docRef = db.collection('jobs').doc();
      final startAt = parseJobStart({
        'date': dateController.text,
        'start_time': timeStartController.text,
      });

      if (startAt == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('กรุณาเลือกวันที่และเวลาเริ่มงานให้ถูกต้อง'),
          ),
        );
        return;
      }

      final data = {
        'service_id': widget.sid,
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
        'job_status': 0,
        'address_id': address_id,
        'start_at': Timestamp.fromDate(startAt),
      };

      await docRef.set(data);
      await NotificationService().notifyAllProviders(jobId: docRef.id);

      log("Job data added with ID: ${docRef.id}");

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomepageService(uid: widget.uid),
        ),
      );
    } catch (e) {
      log("Error adding job: $e");

      if (!mounted) return;

      setState(() {
        isCreatingJob = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("เกิดข้อผิดพลาดในการสร้างงาน: $e")),
      );
    }
  }

  Future<void> readAddress() async {
    print("readAddress called with sid: ${widget.sid}");

    var resultAddress = await db
        .collection("address")
        .where("service_id", isEqualTo: widget.sid)
        .where("main_ad_status", isEqualTo: 1)
        .get();

    if (resultAddress.docs.isNotEmpty) {
      var data = resultAddress.docs.first.data();

      var address =
          data['address_details'] +
          " " +
          data['district'] +
          " " +
          data['province'];

      var addressID = resultAddress.docs.first.id;

      // พิกัดที่อยู่หลัก = จุดรับ
      pickupLatitude = (data['latitude'] as num).toDouble();
      pickupLongitude = (data['longitude'] as num).toDouble();

      log("Address: $address");
      log("Address ID: $addressID");
      log("Pickup latitude: $pickupLatitude");
      log("Pickup longitude: $pickupLongitude");

      if (!mounted) return;

      setState(() {
        mainAddress = address;
        address_id = addressID;
      });
    }
  }

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
      print("Route URL: $url");

      final response = await http.get(url);

      print("Route status: ${response.statusCode}");
      print("Route response: ${response.body}");

      if (response.statusCode != 200) {
        print("Route API Error: ${response.statusCode}");
        return null;
      }

      final data = jsonDecode(response.body);

      // ตรวจสอบว่า API ส่งข้อมูลกลับมาหรือไม่
      if (data['data'] == null || data['data'].isEmpty) {
        print("ไม่พบข้อมูลเส้นทาง");
        return null;
      }

      // distance ของ Longdo เป็นเมตร
      final distanceMeter = data['data'][0]['distance'];

      if (distanceMeter == null) {
        print("ไม่พบ distance");
        return null;
      }

      // แปลงเมตร -> กิโลเมตร
      final distance = (distanceMeter as num).toDouble() / 1000 * 2;

      print("ระยะทางตามถนนจริง: ${distance.toStringAsFixed(2)} km");

      return distance;
    } catch (e) {
      print("getRouteDistance error: $e");
      return null;
    }
  }

  void calculatePrice() {
    if (startTime != null && endTime != null) {
      print(startTime);
      print(endTime);
      int startMinutes =
          startTime!.hour * 60 + startTime!.minute; //แปรงเวลาเริ่มต้นเป็นนาที
      int endMinutes =
          endTime!.hour * 60 + endTime!.minute; //แปรงเวลาจบเป็นนาที
      int diff = endMinutes - startMinutes;
      if (diff > 0) {
        int hours = (diff / 60).ceil();
        setState(() {
          price = hours * ratePerHour;
          updateTotalPrice();
          print(price);
        });
      }
      //else แสดงป้อปอัพแจ้งเตือนให้เลือกเวลาเริ่มต้นและเวลาจบใหม่
    } else {
      price = 0;
    }
  }

  void updateRatePerKm() {
    if (vehicle == 0) {
      // มอเตอร์ไซค์
      ratePerKm = 10;
    } else if (vehicle == 1) {
      // รถยนต์
      ratePerKm = 20;
    } else {
      ratePerKm = 0;
    }

    print("Vehicle: $vehicle");
    print("Rate per km: $ratePerKm");
  }

  void updateTotalPrice() {
    int distancePrice = 0;

    if (distanceKm != null) {
      distancePrice = (distanceKm! * ratePerKm).ceil();
    }

    int total = price + distancePrice + extraPrice;

    priceController.text = "$total";
  }

  Future<void> queryServiceRatesData() async {
    var serviceRateDoc = await db.collection('service_rates').get();
    if (serviceRateDoc.docs.isNotEmpty) {
      setState(() {
        ratePerHour = serviceRateDoc.docs.first.data()['price_per_hour'] ?? 0;
        print("Rate per hour: $ratePerHour");
      });
    }
  }

  Future<void> loadPreviousPlacesData() async {
    final places = await loadPreviousPlaces(db: db, serviceId: widget.sid);

    if (!mounted) return;

    setState(() {
      previousPlaces = places;
    });
  }
}
