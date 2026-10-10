import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AdminPricePage extends StatefulWidget {
  const AdminPricePage({super.key});

  @override
  State<AdminPricePage> createState() => _AdminPricePageState();
}

class _AdminPricePageState extends State<AdminPricePage> {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  // ราคาปัจจุบัน
  int hourlyPrice = 0;
  int bikePrice = 0;
  int carPrice = 0;

  // Controller
  final TextEditingController hourlyController = TextEditingController();
  final TextEditingController bikeController = TextEditingController();
  final TextEditingController carController = TextEditingController();

  // ID ของ document ใน service_rates
  String? rateDocumentId;

  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    loadPrices();
  }

  @override
  void dispose() {
    hourlyController.dispose();
    bikeController.dispose();
    carController.dispose();
    super.dispose();
  }

  // ============================================================
  // โหลดราคาจาก Firestore
  // ============================================================
  Future<void> loadPrices() async {
    try {
      debugPrint('================================');
      debugPrint('เริ่มโหลดข้อมูล service_rates');
      debugPrint('================================');

      if (mounted) {
        setState(() {
          isLoading = true;
        });
      }

      debugPrint('กำลังอ่าน Firestore...');

      final snapshot = await db
          .collection('service_rates')
          .limit(1)
          .get()
          .timeout(
            const Duration(seconds: 10),
          );

      debugPrint(
        'อ่าน Firestore สำเร็จ จำนวนข้อมูล = ${snapshot.docs.length}',
      );

      // ----------------------------------------------------------
      // กรณียังไม่มีข้อมูล
      // ----------------------------------------------------------
      if (snapshot.docs.isEmpty) {
        debugPrint('ยังไม่มีข้อมูลใน service_rates');

        rateDocumentId = null;

        hourlyPrice = 0;
        bikePrice = 0;
        carPrice = 0;

        // ไม่กำหนด 60
        hourlyController.clear();
        bikeController.clear();
        carController.clear();
      }

      else {
        final doc = snapshot.docs.first;

        rateDocumentId = doc.id;

        final data = doc.data();

        debugPrint('Document ID = ${doc.id}');
        debugPrint('ข้อมูล = $data');

        hourlyPrice = _toInt(data['price_per_hour']);
        bikePrice = _toInt(data['price_km_bike']);
        carPrice = _toInt(data['price_km_car']);

        hourlyController.text = _formatNumber(hourlyPrice);
        bikeController.text = _formatNumber(bikePrice);
        carController.text = _formatNumber(carPrice);

        debugPrint('ราคาต่อชั่วโมง = $hourlyPrice');
        debugPrint('มอเตอร์ไซค์/กม. = $bikePrice');
        debugPrint('รถยนต์/กม. = $carPrice');
      }

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      debugPrint('โหลดข้อมูลเสร็จแล้ว');
    } catch (e, stackTrace) {
      debugPrint('================================');
      debugPrint('ERROR loadPrices');
      debugPrint('================================');
      debugPrint('Error: $e');
      debugPrint('StackTrace: $stackTrace');

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ไม่สามารถโหลดข้อมูลราคาได้\n$e',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // ============================================================
  // แปลงข้อมูลจาก Firestore เป็น int
  // ============================================================
  int _toInt(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    return int.tryParse(value.toString()) ?? 0;
  }

  // ============================================================
  // แสดงตัวเลขโดยไม่มีทศนิยม
  // ============================================================
  String _formatNumber(int value) {
    return value.toString();
  }

  // ============================================================
  // บันทึกราคา
  // ============================================================
  Future<void> savePrice() async {
    if (isSaving) return;

    // ----------------------------------------------------------
    // อ่านค่าจากช่องกรอก
    // ----------------------------------------------------------
    final int? newHourlyPrice =
        int.tryParse(hourlyController.text.trim());

    final int? newBikePrice =
        int.tryParse(bikeController.text.trim());

    final int? newCarPrice =
        int.tryParse(carController.text.trim());

    // ----------------------------------------------------------
    // ตรวจสอบราคาต่อชั่วโมง
    // ----------------------------------------------------------
    if (newHourlyPrice == null || newHourlyPrice < 0) {
      _showMessage(
        'กรุณากรอกราคาต่อชั่วโมงเป็นจำนวนเต็ม',
        isError: true,
      );
      return;
    }

    // ----------------------------------------------------------
    // ตรวจสอบราคามอเตอร์ไซค์
    // ----------------------------------------------------------
    if (newBikePrice == null || newBikePrice < 0) {
      _showMessage(
        'กรุณากรอกราคามอเตอร์ไซค์ต่อกิโลเมตรเป็นจำนวนเต็ม',
        isError: true,
      );
      return;
    }

    // ----------------------------------------------------------
    // ตรวจสอบราคารถยนต์
    // ----------------------------------------------------------
    if (newCarPrice == null || newCarPrice < 0) {
      _showMessage(
        'กรุณากรอกราคารถยนต์ต่อกิโลเมตรเป็นจำนวนเต็ม',
        isError: true,
      );
      return;
    }

    try {
      setState(() {
        isSaving = true;
      });

      // --------------------------------------------------------
      // ข้อมูลที่จะบันทึก
      // --------------------------------------------------------
      final Map<String, dynamic> data = {
        'price_per_hour': newHourlyPrice,
        'price_km_bike': newBikePrice,
        'price_km_car': newCarPrice,
      };

      debugPrint('================================');
      debugPrint('กำลังบันทึกราคา');
      debugPrint('================================');
      debugPrint('ข้อมูลที่จะบันทึก = $data');

      // --------------------------------------------------------
      // ถ้ามี document อยู่แล้ว → update
      // --------------------------------------------------------
      if (rateDocumentId != null) {
        debugPrint(
          'กำลัง UPDATE document = $rateDocumentId',
        );

        await db
            .collection('service_rates')
            .doc(rateDocumentId)
            .update(data);
      }

      // --------------------------------------------------------
      // ถ้ายังไม่มี document → สร้างใหม่
      // --------------------------------------------------------
      else {
        debugPrint('ยังไม่มี document → กำลังสร้างใหม่');

        final docRef = await db
            .collection('service_rates')
            .add(data);

        rateDocumentId = docRef.id;

        debugPrint(
          'สร้าง document สำเร็จ ID = ${docRef.id}',
        );
      }

      // --------------------------------------------------------
      // อัปเดตค่าบนหน้า UI
      // --------------------------------------------------------
      hourlyPrice = newHourlyPrice;
      bikePrice = newBikePrice;
      carPrice = newCarPrice;

      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      _showMessage(
        'บันทึกราคาเรียบร้อยแล้ว',
        isError: false,
      );
    } catch (e, stackTrace) {
      debugPrint('================================');
      debugPrint('ERROR savePrice');
      debugPrint('================================');
      debugPrint('Error: $e');
      debugPrint('StackTrace: $stackTrace');

      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      _showMessage(
        'ไม่สามารถบันทึกราคาได้\n$e',
        isError: true,
      );
    }
  }

  // ============================================================
  // ยกเลิกการแก้ไข
  // ============================================================
  void cancelEdit() {
    hourlyController.text = _formatNumber(hourlyPrice);
    bikeController.text = _formatNumber(bikePrice);
    carController.text = _formatNumber(carPrice);

    _showMessage(
      'ยกเลิกการแก้ไขแล้ว',
      isError: false,
    );
  }

  // ============================================================
  // แสดงข้อความ
  // ============================================================
  void _showMessage(
    String message, {
    required bool isError,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  // ============================================================
  // ช่องกรอกราคา
  // ============================================================
  Widget priceTextField({
    required String label,
    required String unit,
    required TextEditingController controller,
  }) {
    return TextField(
      controller: controller,

      // รับเฉพาะตัวเลข
      keyboardType: TextInputType.number,

      // ไม่ให้กรอก . หรือ , หรืออักษร
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],

      decoration: InputDecoration(
        labelText: label,
        suffixText: unit,
        border: const OutlineInputBorder(),
      ),
    );
  }

  // ============================================================
  // UI
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'จัดการอัตราค่าบริการ',
        ),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),

      body: isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'กำลังโหลดข้อมูลราคา...',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ------------------------------------------------
                  // หัวข้อ
                  // ------------------------------------------------
                  const Text(
                    'อัตราค่าบริการ',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'ผู้ดูแลระบบสามารถกำหนดและแก้ไขอัตราค่าบริการได้',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 25),

                  // ------------------------------------------------
                  // ราคาต่อชั่วโมง
                  // ------------------------------------------------
                  priceTextField(
                    label: 'ราคาต่อชั่วโมง',
                    unit: 'บาท/ชั่วโมง',
                    controller: hourlyController,
                  ),

                  const SizedBox(height: 20),

                  // ------------------------------------------------
                  // มอเตอร์ไซค์
                  // ------------------------------------------------
                  priceTextField(
                    label: 'รถมอเตอร์ไซค์',
                    unit: 'บาท/กม.',
                    controller: bikeController,
                  ),

                  const SizedBox(height: 20),

                  // ------------------------------------------------
                  // รถยนต์
                  // ------------------------------------------------
                  priceTextField(
                    label: 'รถยนต์',
                    unit: 'บาท/กม.',
                    controller: carController,
                  ),

                  const SizedBox(height: 30),

                  // ------------------------------------------------
                  // ปุ่ม
                  // ------------------------------------------------
                  Row(
                    children: [
                      // ปุ่มยกเลิก
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isSaving
                              ? null
                              : cancelEdit,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(
                              double.infinity,
                              50,
                            ),
                          ),
                          child: const Text(
                            'ยกเลิก',
                          ),
                        ),
                      ),

                      const SizedBox(width: 15),

                      // ปุ่มบันทึก
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isSaving
                              ? null
                              : savePrice,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(
                              double.infinity,
                              50,
                            ),
                          ),
                          child: isSaving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'บันทึก',
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}