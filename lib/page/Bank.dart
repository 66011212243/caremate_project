import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

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

  // 4. ฟังก์ชันบันทึกลง Firebase Firestore
  void _saveBank() {
    FirebaseFirestore.instance.collection('bank').add({
      'account_name': accountNameCtl.text,
      'bank_name': bankNameCtl.text,
      'account_number': accountNumberCtl.text,
      'promptpay': promptpayCtl.text,
      'created_at': FieldValue.serverTimestamp(),
    }).then((value) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกสำเร็จ!')),
        );
        Navigator.pop(context);
      }
    }).catchError((error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $error')),
        );
      }
    });
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
                    const Icon(Icons.image, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "แนบรูปภาพแล้ว: ${qrCodeImage!.path.split('/').last}",
                        style: const TextStyle(color: Colors.green),
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