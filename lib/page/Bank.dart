import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class BankPage extends StatefulWidget {
  final String pid;

  const BankPage({
    super.key,
    required this.pid,
  });

  @override
  State<BankPage> createState() => _BankPageState();
}

class _BankPageState extends State<BankPage> {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  // Controller
  final TextEditingController accountNameCtl = TextEditingController();
  final TextEditingController bankNameCtl = TextEditingController();
  final TextEditingController accountNumberCtl = TextEditingController();
  final TextEditingController promptpayCtl = TextEditingController();

  // รูป QR
  File? qrCodeImage;          // รูปใหม่ที่เพิ่งเลือก
  String? existingQrUrl;      // URL รูปเดิมที่เคยบันทึกไว้
  final ImagePicker _picker = ImagePicker();

  bool isLoading = false;     // กำลังบันทึก
  bool isFetching = true;     // กำลังโหลดข้อมูลเดิม
  String? bankDocId;          // null = ยังไม่มีข้อมูล (เพิ่มใหม่), มีค่า = แก้ไข

  @override
  void initState() {
    super.initState();
    _loadBank();
  }

  @override
  void dispose() {
    accountNameCtl.dispose();
    bankNameCtl.dispose();
    accountNumberCtl.dispose();
    promptpayCtl.dispose();
    super.dispose();
  }

  // โหลดข้อมูลบัญชีเดิมด้วย pid
  Future<void> _loadBank() async {
    try {
      final pid = widget.pid.trim();
      if (pid.isEmpty) throw Exception('PID เป็นค่าว่าง');

      final snap = await db
          .collection('bank')
          .where('provider_id', isEqualTo: pid)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        final doc = snap.docs.first;
        final data = doc.data();

        bankDocId = doc.id;
        accountNameCtl.text = data['account_name']?.toString() ?? '';
        bankNameCtl.text = data['bank_name']?.toString() ?? '';
        accountNumberCtl.text = data['account_number']?.toString() ?? '';
        promptpayCtl.text = data['promptpay']?.toString() ?? '';
        existingQrUrl = data['qr_code']?.toString();
      }
    } catch (e, stackTrace) {
      debugPrint('loadBank error: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('โหลดข้อมูลไม่สำเร็จ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isFetching = false);
    }
  }

  // เลือกรูป QR จากเครื่อง
  Future<void> _pickQRCodeImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        qrCodeImage = File(pickedFile.path);
      });
    }
  }

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
      } else {
        debugPrint("Upload failed with status: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      debugPrint("Upload error: $e");
      return null;
    }
  }

  // บันทึก: มีข้อมูลเดิม → update, ไม่มี → add
  Future<void> _saveBank() async {
    if (isLoading) return;

    final accountName = accountNameCtl.text.trim();
    final bankName = bankNameCtl.text.trim();
    final accountNumber = accountNumberCtl.text.trim();
    final promptpay = promptpayCtl.text.trim();

    final hasQr = qrCodeImage != null ||
        (existingQrUrl != null && existingQrUrl!.isNotEmpty);

    if (accountName.isEmpty ||
        bankName.isEmpty ||
        accountNumber.isEmpty ||
        promptpay.isEmpty ||
        !hasQr) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกข้อมูลและแนบรูปคิวอาร์โค้ดให้ครบถ้วน'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // ถ้าเลือกรูปใหม่ → อัปโหลด, ถ้าไม่ → ใช้ URL เดิม
      String? qrCodeUrl = existingQrUrl;
      if (qrCodeImage != null) {
        qrCodeUrl = await uploadToCloudinary(qrCodeImage!);
        if (qrCodeUrl == null) {
          throw Exception('อัปโหลดรูปภาพคิวอาร์โค้ดไม่สำเร็จ');
        }
      }

      final data = {
        'provider_id': widget.pid,
        'account_name': accountName,
        'bank_name': bankName,
        'account_number': accountNumber,
        'promptpay': promptpay,
        'qr_code': qrCodeUrl,
      };

      final bankRef = db.collection('bank');

      if (bankDocId != null) {
        await bankRef.doc(bankDocId).update({
          ...data,
          'updated_at': FieldValue.serverTimestamp(),
        });
      } else {
        await bankRef.add({
          ...data,
          'created_at': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกสำเร็จ!')),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ช่องกรอกข้อมูลแบบ Row (ลดโค้ดซ้ำ)
  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required TextInputType keyboardType,
  }) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: label.replaceAll(':', ''),
              border: const UnderlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isFetching) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
              _buildField(
                label: "ชื่อบัญชี:",
                controller: accountNameCtl,
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 20),

              _buildField(
                label: "ธนาคาร:",
                controller: bankNameCtl,
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 20),

              _buildField(
                label: "เลขบัญชี:",
                controller: accountNumberCtl,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),

              _buildField(
                label: "เบอร์พร้อมเพย์:",
                controller: promptpayCtl,
                keyboardType: TextInputType.phone,
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
                    onPressed: _pickQRCodeImage,
                    child: Text(
                      (qrCodeImage != null ||
                              (existingQrUrl?.isNotEmpty ?? false))
                          ? "เปลี่ยนรูป"
                          : "แนบไฟล์",
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  ),
                ],
              ),

              // แสดงรูปที่เลือกใหม่ หรือรูปเดิม
              if (qrCodeImage != null) ...[
                const SizedBox(height: 10),
                Image.file(qrCodeImage!, height: 200),
              ] else if (existingQrUrl != null &&
                  existingQrUrl!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Image.network(
                  existingQrUrl!,
                  height: 200,
                  errorBuilder: (_, __, ___) =>
                      const Text('ไม่สามารถโหลดรูปภาพได้'),
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
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: isLoading ? null : _saveBank,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text("บันทึก", style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}