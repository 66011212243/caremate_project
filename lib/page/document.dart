import 'dart:developer';

import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:http/http.dart' as http;
//import 'package:firebase_storage/firebase_storage.dart';

class DocumentPage extends StatefulWidget {
  final String pid;

  const DocumentPage({super.key, required this.pid});

  @override
  State<DocumentPage> createState() => _DocumentPageState();
}

class _DocumentPageState extends State<DocumentPage> {
  var db = FirebaseFirestore.instance;
  int vehicleType = 1;
  final ImagePicker picker = ImagePicker();

  final plateCtl = TextEditingController();

  bool isLoading = false;

  XFile? idCardImage;
  XFile? licenseImage;
  XFile? vehicleBookImage;
  XFile? insuranceImage;

  Future<void> takePhoto(String type) async {
    final photo = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );

    if (photo != null) {
      setState(() {
        if (type == "idcard") {
          idCardImage = photo;
        } else if (type == "license") {
          licenseImage = photo;
        } else if (type == "vehicle") {
          vehicleBookImage = photo;
        } else if (type == "insurance") {
          insuranceImage = photo;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        leading: const BackButton(color: Colors.white),
        title: const Text(
          "เอกสารที่เกี่ยวข้อง",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 255, 0, 0),
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          vehicleType = 1; // 1 = Car
                        });
                      },
                      child: Column(
                        children: [
                          Text(
                            "Car",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: vehicleType == 1
                                  ? Colors.black
                                  : Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 3,
                            color: vehicleType == 1
                                ? Colors.red
                                : Colors.transparent,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          vehicleType = 0; // 0 = Bike
                        });
                      },
                      child: Column(
                        children: [
                          Text(
                            "Bike",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: vehicleType == 0
                                  ? Colors.black
                                  : Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 3,
                            color: vehicleType == 0
                                ? Colors.red
                                : Colors.transparent,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  const Text(
                    "ทะเบียนรถ:",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: plateCtl,
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                        hintText: "ทะเบียนรถ",
                        border: UnderlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "รูปบัตรประชาชน:",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      takePhoto("idcard");
                    },
                    child: const Text(
                      "แนบไฟล์",
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  ),
                ],
              ),

              if (idCardImage != null)
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) =>
                          Dialog(child: Image.file(File(idCardImage!.path))),
                    );
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.insert_drive_file, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          idCardImage!.name,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),

              const Divider(
                color: Colors.grey,
                thickness: 2, // ความหนา
                height: 30,
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "รูปใบอนุญาตขับขี่:",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      takePhoto("license");
                    },
                    child: const Text(
                      "แนบไฟล์",
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  ),
                ],
              ),

              if (licenseImage != null)
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) =>
                          Dialog(child: Image.file(File(licenseImage!.path))),
                    );
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.insert_drive_file, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          licenseImage!.name,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),

              const Divider(
                color: Colors.grey,
                thickness: 2, // ความหนา
                height: 30,
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "รูปเอกสารหน้าเล่ม:",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      takePhoto("vehicle");
                    },
                    child: const Text(
                      "แนบไฟล์",
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  ),
                ],
              ),
              if (vehicleBookImage != null)
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => Dialog(
                        child: Image.file(File(vehicleBookImage!.path)),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.insert_drive_file, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          vehicleBookImage!.name,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),

              const Divider(
                color: Colors.grey,
                thickness: 2, // ความหนา
                height: 30,
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "รูปพรบ.รถ:",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      takePhoto("insurance");
                    },
                    child: const Text(
                      "แนบไฟล์",
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  ),
                ],
              ),
              if (insuranceImage != null)
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) =>
                          Dialog(child: Image.file(File(insuranceImage!.path))),
                    );
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.insert_drive_file, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          insuranceImage!.name,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),

              const Divider(
                color: Colors.grey,
                thickness: 2, // ความหนา
                height: 30,
              ),

              const SizedBox(height: 50),
              SizedBox(
                width: 250,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 255, 0, 0),
                    foregroundColor: const Color.fromARGB(255, 255, 255, 255),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    //saveProvider();
                  },
                  child: const Text("บันทึก"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Future<String> _uploadToStorage(String folder, XFile file) async {
  //   try {
  //     final String fileName =
  //         "${folder}_${DateTime.now().millisecondsSinceEpoch}.jpg";
  //     final Reference ref = FirebaseStorage.instance.ref().child(
  //       'documents/$fileName',
  //     );

  //     // เริ่มการอัปโหลด
  //     UploadTask uploadTask = ref.putFile(File(file.path));

  //     // รอจนกว่าจะอัปโหลดเสร็จสมบูรณ์ 100%
  //     TaskSnapshot snapshot = await uploadTask;

  //     // คืนค่า URL หลังจากที่ไฟล์ถูกเขียนลง Storage เรียบร้อยแล้ว
  //     return await snapshot.ref.getDownloadURL();
  //   } catch (e) {
  //     throw 'ไม่สามารถอัปโหลด $folder ได้: $e';
  //   }
  // }

  Future<void> saveProvider() async {
    // ป้องกันการกดซ้ำ
    if (isLoading) return;

    // ตรวจสอบข้อมูลก่อนเริ่มทำงาน
    if (idCardImage == null ||
        licenseImage == null ||
        vehicleBookImage == null ||
        insuranceImage == null ||
        plateCtl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("กรุณากรอกข้อมูลและแนบเอกสารให้ครบ")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // อัปโหลดรูปบัตรประชาชน
      final String? idCardUrl = await uploadToCloudinary(
        File(idCardImage!.path),
      );

      // อัปโหลดใบขับขี่
      final String? licenseUrl = await uploadToCloudinary(
        File(licenseImage!.path),
      );

      // อัปโหลดเอกสารหน้าเล่มรถ
      final String? vehicleUrl = await uploadToCloudinary(
        File(vehicleBookImage!.path),
      );

      // อัปโหลด พ.ร.บ.
      final String? insuranceUrl = await uploadToCloudinary(
        File(insuranceImage!.path),
      );

      // ตรวจสอบว่าอัปโหลดสำเร็จทั้งหมด
      if (idCardUrl == null ||
          licenseUrl == null ||
          vehicleUrl == null ||
          insuranceUrl == null) {
        throw Exception("อัปโหลดเอกสารไม่สำเร็จ");
      }

      // สร้าง document ใหม่
      final docRef = db.collection('document').doc();

      final datadocprovider = {
        // PID ของผู้ให้บริการ
        'pid': widget.pid,

        // ข้อมูลรถ
        'vehicle_type': vehicleType,
        'vehicle_Registration': plateCtl.text.trim(),

        // เอกสาร
        'IdCard': idCardUrl,
        'drivinglicense': licenseUrl,
        'vehicle_reg_book': vehicleUrl,
        'vehicle_insurance_file': insuranceUrl,

        // สถานะเริ่มต้น
        // 0 = รออนุมัติ
        // 1 = อนุมัติ
        // 2 = ไม่อนุมัติ
        'status_doc': 0,

        // ตอนแรกยังไม่มีเหตุผลปฏิเสธ
        'reject_reason': null,
      };

      // บันทึกเอกสาร
      await docRef.set(datadocprovider);

      // หา provider จาก pid
      final providerDoc = await db.collection('provider').doc(widget.pid).get();

      if (!providerDoc.exists) {
        throw Exception('ไม่พบข้อมูล provider PID = ${widget.pid}');
      }

      final providerData = providerDoc.data()!;

      // เอา provider_uid
      final providerUid = providerData['provider_uid'];

      if (providerUid == null || providerUid.toString().isEmpty) {
        throw Exception('ไม่พบ provider_uid');
      }

      debugPrint('PID = ${widget.pid}');
      debugPrint('provider_uid = $providerUid');

      // ไปหา users ด้วย provider_uid
      final userDoc = await db
          .collection('users')
          .doc(providerUid.toString())
          .get();

      if (!userDoc.exists) {
        throw Exception('ไม่พบข้อมูลผู้ใช้ uid = $providerUid');
      }

      // อัปเดตสถานะใน users
      await userDoc.reference.update({'status_account': 2});

      debugPrint('อัปเดต users/$providerUid status_account = 2 สำเร็จ');

      await docRef.set(datadocprovider);

      debugPrint('Document saved with ID: ${docRef.id}');
      debugPrint('PID: ${widget.pid}');
      debugPrint('Verification status: 0');
      debugPrint('Rejection reason: null');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("บันทึกเอกสารสำเร็จ รอการอนุมัติ")),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("เกิดข้อผิดพลาด: $e")));
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<String?> uploadToCloudinary(File imageFile) async {
    try {
      const cloudName = "dsz1hhnx4"; // Cloud name ของคุณ
      const uploadPreset = "flutter_upload"; // ชื่อ preset ที่ตั้งใน Cloudinary

      final url = Uri.parse(
        "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
      );

      var request = http.MultipartRequest("POST", url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      var response = await request.send();
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var jsonData = jsonDecode(responseData);
        return jsonData['secure_url']; // ✅ ได้ URL กลับมา
      } else {
        print("Upload failed with status: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Upload error: $e");
      return null;
    }
  }
}
