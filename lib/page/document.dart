import 'dart:developer';

import 'package:caremate_application/page/register_provider.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:http/http.dart' as http;
//import 'package:firebase_storage/firebase_storage.dart';

class DocumentPage extends StatefulWidget {
  final String username;
  final String fullname;
  final String email;
  final String password;

  const DocumentPage({
    super.key,
    required this.username,
    required this.fullname,
    required this.email,
    required this.password,
  });

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
                  const Text(
                    "ประเภทรถ : ",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Radio<int>(
                    value: 1,
                    groupValue: vehicleType,
                    onChanged: (value) {
                      setState(() {
                        vehicleType = value!;
                      });
                    },
                  ),
                  const Text("Car"),
                  Radio<int>(
                    value: 0,
                    groupValue: vehicleType,
                    onChanged: (value) {
                      setState(() {
                        vehicleType = value!;
                      });
                    },
                  ),
                  const Text("Bike"),
                ],
              ),

              const Divider(
                color: Colors.grey,
                thickness: 2, // ความหนา
                height: 30,
              ),

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
                    saveProvider();
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
        plateCtl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("กรุณากรอกข้อมูลและแนบเอกสารให้ครบ")),
      );
      return;
    }

    setState(() {
      isLoading = true; // เริ่มแสดง Loading
    });

    try {
      // 2. ทยอยอัปโหลดทีละไฟล์และเก็บ URL
      // วิธีนี้จะช่วยให้แน่ใจว่าไฟล์ถูกอัปโหลดเสร็จก่อนไปทำขั้นตอนถัดไป
      String? idCardUrl = await uploadToCloudinary(File(idCardImage!.path));
      String? licenseUrl = await uploadToCloudinary(File(licenseImage!.path));
      String? vehicleUrl = await uploadToCloudinary(
        File(vehicleBookImage!.path),
      );
      String? insuranceUrl = await uploadToCloudinary(
        File(insuranceImage!.path),
      );

      // 3. เข้ารหัส Password
      final hashedPassword = BCrypt.hashpw(widget.password, BCrypt.gensalt());

      var docRef = db.collection('provider').doc();
      var dataprovider = {
        'providername': widget.username,
        'realname': widget.fullname,
        'email': widget.email,
        'password': hashedPassword,
        'verification_status': 0,
        'rating_avg': 0.0,
      };
      await docRef.set(dataprovider);
      log("dataprovider data added with ID: ${docRef.id}");

      var docPro = db.collection('document').doc();
      var datadocprovider = {
        'pid': docRef.id,
        'vehicle_type': vehicleType,
        'vehicle_Registration': plateCtl.text,
        'IdCard': idCardUrl,
        'drivinglicense': licenseUrl,
        'vehicle_reg_book': vehicleUrl,
        'vehicle_insurance_file': insuranceUrl,
      };
      await docPro.set(datadocprovider);
      log("datadocprovider data added with ID: ${docPro.id}");

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("สมัครสมาชิกสำเร็จ")));

      // ย้ายไปหน้า Login
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => RegisterProvider()),
        (route) => false, // ล้าง Stack หน้าเดิมทิ้งทั้งหมด
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("เกิดข้อผิดพลาด: $e")));
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false; // ปิด Loading ไม่ว่าจะสำเร็จหรือไม่ก็ตาม
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
