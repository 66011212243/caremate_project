import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class EditBank extends StatefulWidget {
  final String pid;

  const EditBank({
    super.key,
    this.pid = "I9vYo5CMP3swjXsI6MkS",
  });

  @override
  State<EditBank> createState() => _BankPageState();
}

class _BankPageState extends State<EditBank> {
  // Controller
  final TextEditingController accountNameCtl = TextEditingController();
  final TextEditingController bankNameCtl = TextEditingController();
  final TextEditingController accountNumberCtl = TextEditingController();
  final TextEditingController promptpayCtl = TextEditingController();

  // รูป QR Code
  File? qrCodeImage;
  String? currentQrCodeUrl; // เก็บลิงก์รูป QR Code เดิมจาก Firestore
  final ImagePicker _picker = ImagePicker();

  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadBankData();
  }

  // ============================
  // ดึงข้อมูลธนาคารเดิม
  // ============================
  Future<void> _loadBankData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('bank')
          .doc(widget.pid)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data();

        // นำข้อมูลเดิมใส่เข้า Controller เพื่อให้แสดงผลบน 
        setState(() {
          accountNameCtl.text = data?['account_name'] ?? '';
          bankNameCtl.text = data?['bank_name'] ?? '';
          accountNumberCtl.text = data?['account_number'] ?? '';
          promptpayCtl.text = data?['promptpay'] ?? '';
          currentQrCodeUrl = data?['qr_code']; // URL รูปเดิม (ถ้ามี)
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถโหลดข้อมูลได้: $e'),
          ),
        );
      }
    } finally {
      // ซ่อน Loading Indicator เมื่อโหลดเสร็จสิ้นไม่ว่าจะสำเร็จหรือล้มเหลว
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ============================
  // เลือกรูป QR Code ใหม่
  // ============================
  Future<void> _pickQRCodeImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      setState(() {
        qrCodeImage = File(pickedFile.path);
      });
    }
  }

  // อัปโหลดรูปภาพไปยัง Cloudinary
  // ============================
  Future<String?> uploadToCloudinary(File imageFile) async {
    try {
      const cloudName = "dsz1hhnx4";
      const uploadPreset = "flutter_upload";

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
        return jsonData['secure_url'];
      }
      return null;
    } catch (e) {
      print("Upload error: $e");
      return null;
    }
  }

  // ============================
  // บันทึกการแก้ไขข้อมูล
  // ============================
  Future<void> _saveBank() async {
    setState(() {
      isSaving = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('bank')
          .doc(widget.pid)
          .update({
        'account_name': accountNameCtl.text.trim(),
        'bank_name': bankNameCtl.text.trim(),
        'account_number': accountNumberCtl.text.trim(),
        'promptpay': promptpayCtl.text.trim(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('แก้ไขข้อมูลสำเร็จ!'),
          ),
        );

        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    accountNameCtl.dispose();
    bankNameCtl.dispose();
    accountNumberCtl.dispose();
    promptpayCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
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
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // ============================
                    // ชื่อบัญชี
                    // ============================
                    Row(
                      children: [
                        const Text(
                          "ชื่อบัญชี:",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: accountNameCtl,
                            keyboardType: TextInputType.text,
                            decoration: const InputDecoration(
                              hintText: 'ระบุชื่อบัญชี',
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ============================
                    // ธนาคาร
                    // ============================
                    Row(
                      children: [
                        const Text(
                          "ธนาคาร:",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: bankNameCtl,
                            keyboardType: TextInputType.text,
                            decoration: const InputDecoration(
                              hintText: 'ระบุชื่อธนาคาร',
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ============================
                    // เลขบัญชี
                    // ============================
                    Row(
                      children: [
                        const Text(
                          "เลขบัญชี:",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: accountNumberCtl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: 'ระบุเลขที่บัญชี',
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ============================
                    // พร้อมเพย์
                    // ============================
                    Row(
                      children: [
                        const Text(
                          "เบอร์พร้อมเพย์:",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: promptpayCtl,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              hintText: 'ระบุเบอร์พร้อมเพย์',
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ============================
                    // QR Code
                    // ============================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "รูปคิวอาร์โค้ด:",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _pickQRCodeImage,
                          child: const Text(
                            "แนบไฟล์",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // แสดงรูปภาพใหม่ที่เลือก หรือแสดงรูปภาพเดิมจาก Network
                    if (qrCodeImage != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.image, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "แนบไฟล์: ${qrCodeImage!.path.split('/').last}",
                              style: const TextStyle(color: Colors.green),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ] else if (currentQrCodeUrl != null &&
                        currentQrCodeUrl!.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          currentQrCodeUrl!,
                          height: 150,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Text('ไม่สามารถโหลดรูปภาพเดิมได้'),
                        ),
                      ),
                    ],

                    const Divider(
                      color: Colors.grey,
                      thickness: 2,
                      height: 30,
                    ),

                    const SizedBox(height: 30),

                    // ============================
                    // ปุ่มบันทึก
                    // ============================
                    SizedBox(
                      width: 250,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                        ),
                        onPressed: isSaving ? null : _saveBank,
                        child: isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "แก้ไขบัญชีธนาคาร",
                                style: TextStyle(
                                  fontSize: 16,
                                ),
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