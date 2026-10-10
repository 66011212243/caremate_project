import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BankPage extends StatefulWidget {
  const BankPage({super.key});

  @override
  State<BankPage> createState() => _BankPageState();
}

class _BankPageState extends State<BankPage> {
  // 1. Controller สำหรับจัดการการพิมพ์ข้อมูล
  final TextEditingController accountNameCtl = TextEditingController();
  final TextEditingController bankNameCtl = TextEditingController();
  final TextEditingController accountNumberCtl = TextEditingController();
  final TextEditingController promptpayCtl = TextEditingController();

  

  // 2. ตัวแปรเก็บรูปภาพคิวอาร์โค้ดที่เลือก
  File? qrCodeImage;
  final ImagePicker _picker = ImagePicker();
  bool isLoading = false;

  @override
  void dispose() {
    accountNameCtl.dispose();
    bankNameCtl.dispose();
    accountNumberCtl.dispose();
    promptpayCtl.dispose();
    super.dispose();
  }

  // 3. ฟังก์ชันเลือกรูปคิวอาร์โค้ดจากเครื่อง
  Future<void> _pickQRCodeImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        qrCodeImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> uploadToCloudinary(File imageFile) async {
    try {
      const cloudName = "dsz1hhnx4"; // Cloud name ของคุณ
      const uploadPreset = "flutter_upload"; // ชื่อ preset ของคุณ

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
        return jsonData['secure_url']; // ได้ URL รูปภาพกลับมา
      } else {
        print("Upload failed with status: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Upload error: $e");
      return null;
    }
  }

 // 4. ฟังก์ชันบันทึกลง Firebase Firestore
Future<void> _saveBank() async {
    final accountName = accountNameCtl.text.trim();
    final bankName = bankNameCtl.text.trim();
    final accountNumber = accountNumberCtl.text.trim();
    final promptpay = promptpayCtl.text.trim();

  // เช็กว่ากรอกข้อมูลครบทุกช่องหรือไม่
  if (accountName.isEmpty ||
      bankName.isEmpty ||
      accountNumber.isEmpty ||
      promptpay.isEmpty ||
      qrCodeImage == null) { // ถ้าต้องการบังคับแนบรูปคิวอาร์โค้ดด้วย
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('กรุณากรอกข้อมูลและแนบรูปคิวอาร์โค้ดให้ครบถ้วน'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }
  setState(() {
      isLoading = true; // เปิดตัวหมุนโหลดเพื่อป้องกันการกดซ้ำ
    });

    try {
      // [จุดแก้ไขที่ 2]: อัปโหลดรูปภาพไปยัง Cloudinary ก่อน
      String? qrCodeUrl = await uploadToCloudinary(qrCodeImage!);

      if (qrCodeUrl == null) {
        throw Exception('อัปโหลดรูปภาพคิวอาร์โค้ดไม่สำเร็จ');
      }

      //[จุดแก้ไขที่ 3]: บันทึกข้อมูลพร้อม URL ของรูปคิวอาร์โค้ดลง Firebase
      await FirebaseFirestore.instance.collection('bank').add({
        'account_name': accountName,
        'bank_name': bankName,
        'account_number': accountNumber,
        'promptpay': promptpay,
        'qr_code': qrCodeUrl, // บันทึก URL รูปภาพ
        'created_at': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกสำเร็จ!')),
        );
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'บัญชีธนาคาร',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // ชื่อบัญชี
              Row(
                children: [
                  const Text(
                    "ชื่อบัญชี:",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: accountNameCtl,
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                        hintText: "ชื่อบัญชี",
                        border: UnderlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ธนาคาร
              Row(
                children: [
                  const Text(
                    "ธนาคาร:",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: bankNameCtl,
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                        hintText: "ธนาคาร",
                        border: UnderlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // เลขบัญชี
              Row(
                children: [
                  const Text(
                    "เลขบัญชี:",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: accountNumberCtl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: "เลขบัญชี",
                        border: UnderlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // เบอร์พร้อมเพย์
              Row(
                children: [
                  const Text(
                    "เบอร์พร้อมเพย์:",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: promptpayCtl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: "เบอร์พร้อมเพย์",
                        border: UnderlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // รูปคิวอาร์โค้ด + ปุ่มแนบไฟล์
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "รูปคิวอาร์โค้ด:",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton(
                    onPressed: _pickQRCodeImage, // กดแล้วเปิดคลังภาพ
                    child: const Text(
                      "แนบไฟล์",
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  ),
                ],
              ),

              // แสดงชื่อไฟล์หรือตัวอย่างรูปที่แนบไว้
              if (qrCodeImage != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.image, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "แนบรูปภาพแล้ว: ${qrCodeImage!.path.split('/').last}",
                        style: const TextStyle(color: Colors.red),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              const Divider(
                color: Colors.grey,
                thickness: 2,
                height: 30,
              ),

              const SizedBox(height: 50),

              // ปุ่มบันทึก
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
                  onPressed: _saveBank,
                  child: const Text(
                    "บันทึก",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}