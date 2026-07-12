import 'dart:developer';

import 'package:caremate_application/page/homepage_service.dart';
import 'package:caremate_application/page/map_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:longdo_maps_api3_flutter/longdo_maps_api3_flutter.dart';
import 'package:flutter/material.dart';

class CreateJob extends StatefulWidget {
  String sid = '';
  CreateJob({super.key, required this.sid});

  @override
  State<CreateJob> createState() => _CreateJobState();
}

class _CreateJobState extends State<CreateJob> {
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

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    readAddress();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context, HomepageService(sid: widget.sid));
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
      ),

      body: SingleChildScrollView(
        child: Container(
          child: Padding(
            padding: const EdgeInsets.only(top: 20, left: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 350,
                  // height: 70,
                  color: Colors.white,
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 20),
                    SizedBox(
                      width: 220,
                      child: TextField(
                        controller: placeNameController,
                        decoration: InputDecoration(
                          hintText: "กรุณากรอกชื่อสถานที่",
                        ),
                      ),
                    ),
                  ],
                ),

                GestureDetector(
                  onTap: () async {
                    print("Container Clicked");
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MapPage()),
                    );

                    if (result != null) {
                      setState(() {
                        latitudeLocation = result['lat'];
                        longitudeLocation = result['lon'];
                      });

                      print("LatfromMap: $latitudeLocation");
                      print("LonfromMap: $longitudeLocation");
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 30, top: 30),
                    child: Center(
                      child: Container(
                        height: 150,
                        width: 300,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              blurRadius: 3,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),

                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            "assets/images/map_preview.png",
                            fit: BoxFit.cover,
                          ),
                        ),
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
                  children: [
                    Text(
                      "ประเภทรถ:",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 10),
                    Radio(
                      value: 1,
                      groupValue: vehicle,
                      onChanged: (value) {
                        setState(() {
                          vehicle = value;
                          log(vehicle.toString());
                        });
                      },
                    ),
                    Text("Car", style: TextStyle(fontSize: 16)),

                    SizedBox(width: 10),

                    Radio(
                      value: 0,
                      groupValue: vehicle,
                      onChanged: (value) {
                        setState(() {
                          vehicle = value;
                          log(vehicle.toString());
                        });
                      },
                    ),
                    Text("Bike", style: TextStyle(fontSize: 16)),
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
                        Text(
                          "ข้อมูลพิเศษ:",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "(ไม่จำเป็น)",
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                    SizedBox(width: 10),
                    Column(
                      children: [
                        Row(
                          children: [
                            Radio(
                              value: 0,
                              groupValue: additionalInfo,
                              onChanged: (value) {
                                setState(() {
                                  additionalInfo = value;
                                  extraPrice = 200;
                                  updateTotalPrice();
                                  print(additionalInfo);
                                });
                              },
                            ),
                            Text(
                              "ผู้ป่วยติดเตียง  (+200 บาท)",
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Radio(
                              value: 1,
                              groupValue: additionalInfo,
                              onChanged: (value) {
                                setState(() {
                                  additionalInfo = value;
                                  extraPrice = 100;
                                  updateTotalPrice();
                                  print(additionalInfo);
                                });
                              },
                            ),
                            Text(
                              "ผู้ป่วยนั่งวิลแชร์  (+100 บาท)",
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
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Color.fromARGB(
                        255,
                        255,
                        0,
                        0,
                      ), // สีพื้นหลังปุ่ม
                      foregroundColor: Colors.white, // สีตัวอักษร
                      padding: EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12), // มุมมน
                      ),
                    ),
                    onPressed: addJobData,
                    child: Text("สร้างงาน", style: TextStyle(fontSize: 18)),
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

  void addJobData() async {
    if (placeNameController.text.isEmpty ||
        latitudeLocation == null ||
        longitudeLocation == null ||
        dateController.text.isEmpty ||
        timeStartController.text.isEmpty ||
        timeEndController.text.isEmpty ||
        priceController.text.isEmpty ||
        vehicle == null ||
        jobTypeController.text.isEmpty ||
        address_id == null) {
      // ถ้าเจอช่องว่างหรือ null
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("กรุณากรอกข้อมูลให้ครบทุกช่อง")));
      return; // ไม่บันทึก
    }
    var docRef = db.collection('jobs').doc();
    var data = {
      'service_id': widget.sid,
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
      'job_status': 0,
      'address_id': address_id,
    };
    await docRef.set(data);
    log("Job data added with ID: ${docRef.id}");
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomepageService(sid: widget.sid)),
    );
  }

  void readAddress() async {
    print("readAddress called with sid: ${widget.sid}");
    var resultAddress = await db
        .collection("address")
        .where("service_id", isEqualTo: widget.sid)
        .where("main_ad_status", isEqualTo: 1)
        .get();
    if (resultAddress.docs.isNotEmpty) {
      var address =
          resultAddress.docs.first.data()['address_details'] +
          " " +
          resultAddress.docs.first.data()['district'] +
          " " +
          resultAddress.docs.first.data()['province'];
      var addreaaID = resultAddress.docs.first.id;
      log(address);
      setState(() {
        mainAddress = address;
        address_id = addreaaID;
        log(address_id);
      });
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

  void updateTotalPrice() {
    int total = price + extraPrice;
    priceController.text = "$total";
  }
}
