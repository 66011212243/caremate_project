import 'dart:developer';

import 'package:caremate_application/page/map_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddAddressPage extends StatefulWidget {
  String sid = '';
  AddAddressPage({super.key, required this.sid});

  @override
  State<AddAddressPage> createState() => _AddAddressPageState();
}

class _AddAddressPageState extends State<AddAddressPage> {
  var db = FirebaseFirestore.instance;
  final houseNumberController = TextEditingController();
  final addressDetailController = TextEditingController();
  final districtController = TextEditingController();
  final provinceController = TextEditingController();

  int addressBegin = 0;
  double? latitude;
  double? longitude;
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
              "เพิ่มที่อยู่ของฉัน",
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

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "เพิ่มที่อยู่",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 25),

            TextField(
              controller: houseNumberController,
              decoration: InputDecoration(
                labelText: "บ้านเลขที่, หมู่",
                hintText: "เช่น 123/45 หมู่ 5",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: addressDetailController,
              decoration: InputDecoration(
                labelText: "ที่อยู่เพิ่มเติม",
                hintText: "ซอย, ถนน, แขวง/ตำบล",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: districtController,
              decoration: InputDecoration(
                labelText: "อำเภอ",
                hintText: "เช่น เมืองมหาสารคาม",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: provinceController,
              decoration: InputDecoration(
                labelText: "จังหวัด",
                hintText: "เช่น มหาสารคาม",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 10),

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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                              latitude != null
                                  ? "ละติจูด: $latitude"
                                  : "ยังไม่ได้เลือกพิกัด",
                              style: const TextStyle(fontSize: 15),
                            ),

                            const SizedBox(height: 5),

                            Text(
                              longitude != null
                                  ? "ลองจิจูด: $longitude"
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
                            latitude = result['lat'];
                            longitude = result['lon'];
                          });

                          print("LatfromMap: $latitude");
                          print("LonfromMap: $longitude");
                        }
                      },
                      icon: const Icon(Icons.map, color: Colors.red),
                      label: const Text(
                        "เพิ่มพิกัดที่อยู่",
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

            // เลือกเป็นที่อยู่ตั้งต้น
            Row(
              children: [
                Checkbox(
                  value: addressBegin == 1,
                  activeColor: Colors.red,
                  onChanged: (value) {
                    setState(() {
                      addressBegin = value == true ? 1 : 0;
                    });

                    log(addressBegin.toString());
                  },
                ),

                const Text(
                  "เลือกเป็นที่อยู่ตั้งต้น",
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ],
        ),
      ),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(25, 10, 25, 20),
          child: SizedBox(
            height: 50,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // คำสั่งสร้างที่อยู่
                addAddress();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "ยืนยันการสร้างที่อยู่",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> addAddress() async {
    if (houseNumberController.text.isEmpty ||
        addressDetailController.text.isEmpty ||
        districtController.text.isEmpty ||
        provinceController.text.isEmpty ||
        latitude == null ||
        longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("กรุณากรอกข้อมูลให้ครบทุกช่อง")),
      );
      return;
    }

    String address =
        "${houseNumberController.text}, ${addressDetailController.text}";

    // สร้าง Document Reference สำหรับที่อยู่ใหม่
    final addressRef = db.collection('address').doc();

    try {
      await db.runTransaction((transaction) async {
        // ถ้าผู้ใช้เลือกให้ที่อยู่นี้เป็นที่อยู่หลัก
        if (addressBegin == 1) {
          final mainAddressQuery = await db
              .collection('address')
              .where('service_id', isEqualTo: widget.sid)
              .where('main_ad_status', isEqualTo: 1)
              .get();

          // เปลี่ยนที่อยู่หลักเดิมให้เป็น 0
          for (final doc in mainAddressQuery.docs) {
            transaction.update(doc.reference, {'main_ad_status': 0});
          }
        }

        // เพิ่มที่อยู่ใหม่
        final data = {
          'service_id': widget.sid,
          'latitude': latitude,
          'longitude': longitude,
          'address_details': address,
          'district': districtController.text,
          'province': provinceController.text,
          'main_ad_status': addressBegin,
        };

        transaction.set(addressRef, data);
      });

      log("Address added with ID: ${addressRef.id}");

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("เพิ่มที่อยู่สำเร็จ")));

      Navigator.pop(context);
    } catch (e) {
      log("Error adding address: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("เกิดข้อผิดพลาด: $e")));
    }
  }
}
