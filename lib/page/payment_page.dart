import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class PaymentPage extends StatefulWidget {
  final String jobId;
  final String providerId;
  final int moneyAmount;
  const PaymentPage({
    super.key,
    required this.jobId,
    required this.providerId,
    required this.moneyAmount,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  var db = FirebaseFirestore.instance;
  final ImagePicker picker = ImagePicker();
  File? imagePayment;
  bool isUploading = false;

  Map<String, dynamic>? bankData;
  bool isLoadingBank = true;
  @override
  void initState() {
    super.initState();
    getBankProvider();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "การชำระเงิน",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -------------------------
            // ช่องทางการชำระเงิน
            // -------------------------
            const Text(
              "ช่องทางการชำระเงิน",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            const SizedBox(height: 12),

            _paymentMethodCard(
              icon: Icons.account_balance,
              iconColor: Colors.blue,
              title: "เลขบัญชี",
              subtitle: "ชำระเงินผ่านบัญชีธนาคาร",
              onTap: () {
                _showBankAccountDialog(context);
              },
            ),

            const SizedBox(height: 12),

            _paymentMethodCard(
              icon: Icons.qr_code_2,
              iconColor: Colors.green,
              title: "QR Code",
              subtitle: "สแกน QR Code เพื่อชำระเงิน",
              onTap: () {
                _showQrCodeDialog(context);
              },
            ),

            const SizedBox(height: 12),

            _paymentMethodCard(
              icon: Icons.phone_android,
              iconColor: Colors.orange,
              title: "เลขพร้อมเพย์",
              subtitle: "ชำระเงินผ่านพร้อมเพย์",
              onTap: () {
                _showPromptPayDialog(context);
              },
            ),

            const SizedBox(height: 24),

            const Divider(),

            const SizedBox(height: 20),

            // -------------------------
            // แนบหลักฐาน
            // -------------------------
            const Text(
              "หลักฐานการชำระเงิน",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "จำนวนเงินที่ต้องชำระ: ${widget.moneyAmount} บาท",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text(
              "หลังจากโอนเงินแล้ว กรุณาแนบสลิปเพื่อยืนยันการชำระเงิน",
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),

            const SizedBox(height: 16),

            if (imagePayment == null)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    addImgByGallery();
                  },
                  icon: const Icon(Icons.attach_file),
                  label: const Text(
                    "แนบหลักฐานการชำระเงิน",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // แสดงสถานะว่ามีไฟล์แล้ว
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade600),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            "แนบหลักฐานการชำระเงินแล้ว",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // แสดงรูปที่เลือก
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      imagePayment!,
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ปุ่มเปลี่ยนรูป
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        addImgByGallery();
                      },
                      icon: const Icon(Icons.image_outlined),
                      label: const Text(
                        "เปลี่ยนรูปภาพ",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ปุ่มบันทึกลงฐานข้อมูล
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isUploading
                          ? null
                          : () async {
                              setState(() {
                                isUploading = true;
                              });

                              try {
                                await addPaymentData();

                                if (!mounted) return;

                                Navigator.pop(context, true);
                              } catch (e) {
                                if (!mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "ไม่สามารถบันทึกการชำระเงินได้: $e",
                                    ),
                                  ),
                                );
                              } finally {
                                if (mounted) {
                                  setState(() {
                                    isUploading = false;
                                  });
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        disabledBackgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isUploading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.cloud_upload_outlined),
                                SizedBox(width: 8),
                                Text(
                                  "ยืนยันการชำระเงิน",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 50),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> getBankProvider() async {
    try {
      final bankDoc = await db
          .collection('bank')
          .where('provider_id', isEqualTo: widget.providerId)
          .limit(1)
          .get();

      if (bankDoc.docs.isNotEmpty && mounted) {
        setState(() {
          bankData = bankDoc.docs.first.data();
        });
      }
    } catch (e) {
      print('Error fetching bank: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoadingBank = false;
        });
      }
    }
  }

  // =========================================================
  // Payment Method Card
  // =========================================================

  Widget _paymentMethodCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 25),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // Bank Account
  // =========================================================

  void _showBankAccountDialog(BuildContext pageContext) {
    // ยังโหลดไม่เสร็จ หรือไม่พบข้อมูลธนาคาร
    if (isLoadingBank || bankData == null) {
      ScaffoldMessenger.of(pageContext).showSnackBar(
        SnackBar(
          content: Text(
            isLoadingBank ? "กำลังโหลดข้อมูล..." : "ไม่พบข้อมูลบัญชีธนาคาร",
          ),
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }

    final bankName = bankData!['bank_name'] ?? '-';
    final accountNumber = bankData!['account_number'] ?? '-';
    final accountName = bankData!['account_name'] ?? '-';

    showDialog(
      context: pageContext,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            "ข้อมูลบัญชีธนาคาร",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("ธนาคาร: $bankName"),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      accountNumber,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    tooltip: "คัดลอกเลขบัญชี",
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: accountNumber),
                      );

                      if (!dialogContext.mounted) return;
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text("คัดลอกเลขบัญชีแล้ว"),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text("ชื่อบัญชี: $accountName"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("ปิด"),
            ),
          ],
        );
      },
    );
  }

  // =========================================================
  // QR Code
  // =========================================================

  void _showQrCodeDialog(BuildContext pageContext) {
    if (isLoadingBank || bankData == null) {
      ScaffoldMessenger.of(pageContext).showSnackBar(
        SnackBar(
          content: Text(
            isLoadingBank ? "กำลังโหลดข้อมูล..." : "ไม่พบข้อมูล QR Code",
          ),
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }

    final String qrUrl = (bankData!['qr_code'] ?? '').toString().trim();

    if (qrUrl.isEmpty) {
      ScaffoldMessenger.of(pageContext).showSnackBar(
        const SnackBar(
          content: Text("ยังไม่มีรูป QR Code"),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    showDialog(
      context: pageContext,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            "QR Code",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "สแกน QR Code เพื่อชำระเงิน",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 240,
                  height: 240,
                  color: Colors.grey.shade100,
                  child: Image.network(
                    qrUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.broken_image,
                              size: 48,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 8),
                            Text("โหลดรูปไม่สำเร็จ"),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("ปิด"),
            ),
          ],
        );
      },
    );
  }

  // =========================================================
  // PromptPay
  // =========================================================

  void _showPromptPayDialog(BuildContext pageContext) {
    if (isLoadingBank || bankData == null) {
      ScaffoldMessenger.of(pageContext).showSnackBar(
        SnackBar(
          content: Text(
            isLoadingBank ? "กำลังโหลดข้อมูล..." : "ไม่พบข้อมูลพร้อมเพย์",
          ),
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }

    final String promptPayNumber = (bankData!['promptpay'] ?? '')
        .toString()
        .trim();

    if (promptPayNumber.isEmpty) {
      ScaffoldMessenger.of(pageContext).showSnackBar(
        const SnackBar(
          content: Text("ยังไม่มีเลขพร้อมเพย์"),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    showDialog(
      context: pageContext,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            "เลขพร้อมเพย์",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Row(
            children: [
              Expanded(
                child: Text(
                  promptPayNumber,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy),
                tooltip: "คัดลอกเลขพร้อมเพย์",
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: promptPayNumber));

                  if (!dialogContext.mounted) return;
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text("คัดลอกเลขพร้อมเพย์แล้ว"),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("ปิด"),
            ),
          ],
        );
      },
    );
  }

  void addImgByGallery() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    imagePayment = File(picked.path);
    setState(() {});
  }

  String? imageUrlSlip;

  Future<void> addPaymentData() async {
    try {
      if (imagePayment == null) {
        throw Exception("ยังไม่ได้เลือกรูปสลิป");
      }

      // อัปโหลดรูปไป Cloudinary
      final imageUrlSlip = await uploadToCloudinary(imagePayment!);

      if (imageUrlSlip == null || imageUrlSlip.isEmpty) {
        throw Exception("อัปโหลดรูปสลิปไม่สำเร็จ");
      }

      log("Slip Image URL: $imageUrlSlip");

      // สร้าง Document ID ให้ Firestore
      final paymentDoc = FirebaseFirestore.instance
          .collection('payments')
          .doc();

      // เพิ่มข้อมูลลง Firestore
      await paymentDoc.set({
        'payment_id': paymentDoc.id,
        'job_id': widget.jobId,
        'provider_id': widget.providerId,
        'slip_image': imageUrlSlip,
        'money_amount': widget.moneyAmount,
      });

      log("เพิ่มข้อมูล payment สำเร็จ");
    } catch (e) {
      log("Error addPaymentData: $e");

      // ส่ง Error กลับไปให้ onPressed จัดการ
      rethrow;
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
