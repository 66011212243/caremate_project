import 'dart:developer';

import 'package:caremate_application/page/map_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditAddressPage extends StatefulWidget {
  final String sid;
  final String addressId;

  const EditAddressPage({
    super.key,
    required this.sid,
    required this.addressId,
  });

  @override
  State<EditAddressPage> createState() => _EditAddressPageState();
}

class _EditAddressPageState extends State<EditAddressPage> {
  final db = FirebaseFirestore.instance;

  final houseNumberController = TextEditingController();
  final addressDetailController = TextEditingController();
  final districtController = TextEditingController();
  final provinceController = TextEditingController();

  int addressBegin = 0;

  double? latitude;
  double? longitude;

  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    loadAddress();
  }

  @override
  void dispose() {
    houseNumberController.dispose();
    addressDetailController.dispose();
    districtController.dispose();
    provinceController.dispose();
    super.dispose();
  }

  // ดึงข้อมูลที่อยู่เดิม
  Future<void> loadAddress() async {
    try {
      final doc = await db.collection('address').doc(widget.addressId).get();

      if (!doc.exists) {
        log("ไม่พบข้อมูลที่อยู่");
        return;
      }

      final data = doc.data()!;

      // address_details เดิมเก็บรวมกัน เช่น
      // "123/45 หมู่ 5, ซอย ABC ถนน XYZ"
      String addressDetails = data['address_details'] ?? '';

      // แยกข้อมูลก่อนและหลัง comma ตัวแรก
      String houseNumber = '';
      String detail = '';

      if (addressDetails.contains(',')) {
        final parts = addressDetails.split(',');

        houseNumber = parts.first.trim();
        detail = parts.skip(1).join(',').trim();
      } else {
        houseNumber = addressDetails;
      }

      setState(() {
        houseNumberController.text = houseNumber;
        addressDetailController.text = detail;

        districtController.text = data['district'] ?? '';
        provinceController.text = data['province'] ?? '';

        latitude = data['latitude'] != null
            ? (data['latitude'] as num).toDouble()
            : null;

        longitude = data['longitude'] != null
            ? (data['longitude'] as num).toDouble()
            : null;

        addressBegin = data['main_ad_status'] ?? 0;

        isLoading = false;
      });
    } catch (e) {
      log("Error loading address: $e");

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("เกิดข้อผิดพลาดในการโหลดข้อมูล: $e")),
      );
    }
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
              label: const Icon(Icons.arrow_back_ios, color: Colors.black),
            ),

            const Text(
              "แก้ไขที่อยู่ของฉัน",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        toolbarHeight: 70,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "แก้ไขที่อยู่",
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

                                log("LatfromMap: $latitude");
                                log("LonfromMap: $longitude");
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
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

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
              onPressed: isSaving ? null : updateAddress,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      "ยืนยันการแก้ไข",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // แก้ไขข้อมูลที่อยู่
  Future<void> updateAddress() async {
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

    setState(() {
      isSaving = true;
    });

    String address =
        "${houseNumberController.text}, ${addressDetailController.text}";

    final addressRef = db.collection('address').doc(widget.addressId);

    try {
      await db.runTransaction((transaction) async {
        // ถ้าเลือกที่อยู่นี้เป็นที่อยู่หลัก
        if (addressBegin == 1) {
          final mainAddressQuery = await db
              .collection('address')
              .where('service_id', isEqualTo: widget.sid)
              .where('main_ad_status', isEqualTo: 1)
              .get();

          // เปลี่ยนที่อยู่หลักเดิมเป็น 0
          for (final doc in mainAddressQuery.docs) {
            // ไม่ต้อง update ตัวเองซ้ำ
            if (doc.id != widget.addressId) {
              transaction.update(doc.reference, {'main_ad_status': 0});
            }
          }
        }

        // Update ข้อมูลที่อยู่
        transaction.update(addressRef, {
          'latitude': latitude,
          'longitude': longitude,
          'address_details': address,
          'district': districtController.text,
          'province': provinceController.text,
          'main_ad_status': addressBegin,
        });
      });

      log("Address updated: ${widget.addressId}");

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("แก้ไขที่อยู่สำเร็จ")));

      Navigator.pop(context, true);
    } catch (e) {
      log("Error updating address: $e");

      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("เกิดข้อผิดพลาด: $e")));
    }
  }
}
