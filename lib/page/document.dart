import 'dart:developer';
import 'package:caremate_application/page/accountStatusPage.dart';
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
  final bool isFirstSetup;

  const DocumentPage({super.key, this.isFirstSetup = false, required this.pid});

  @override
  State<DocumentPage> createState() => _DocumentPageState();
}

class _DocumentPageState extends State<DocumentPage> {
  var db = FirebaseFirestore.instance;
  int vehicleType = 1;
  // สถานะว่ามีเอกสารของแต่ละประเภทรถหรือไม่

  // สถานะระหว่างโหลดข้อมูล
  bool isLoadingDocs = true;
  final ImagePicker picker = ImagePicker();

  // Car: vehicle_type = 1
  final TextEditingController carPlateCtl = TextEditingController();
  Map<String, dynamic>? carDocument;

  // Bike: vehicle_type = 0
  final TextEditingController bikePlateCtl = TextEditingController();
  Map<String, dynamic>? bikeDocument;

  bool isLoading = false;

  // Car: vehicle_type = 1
  String? carIdCardUrl;
  String? carLicenseUrl;
  String? carVehicleBookUrl;
  String? carInsuranceUrl;
  int? carStatus;

  // Bike: vehicle_type = 0
  String? bikeIdCardUrl;
  String? bikeLicenseUrl;
  String? bikeVehicleBookUrl;
  String? bikeInsuranceUrl;
  int? bikeStatus;

  // รูปที่เลือกสำหรับรถยนต์
  XFile? carIdCardImage;
  XFile? carLicenseImage;
  XFile? carVehicleBookImage;
  XFile? carInsuranceImage;

  // รูปที่เลือกสำหรับมอเตอร์ไซค์
  XFile? bikeIdCardImage;
  XFile? bikeLicenseImage;
  XFile? bikeVehicleBookImage;
  XFile? bikeInsuranceImage;

  static const int docRejected = 2; // ปรับตามค่าจริง

  String? carDocId;
  String? bikeDocId;

  bool _isRejected(Map<String, dynamic>? doc) =>
      doc != null && doc['status_doc'] == docRejected;

  // แก้ได้เมื่อ: ยังไม่มีเอกสาร หรือเอกสารถูกปฏิเสธ
  bool _canEdit(bool isBike) {
    final doc = isBike ? bikeDocument : carDocument;
    return doc == null || _isRejected(doc);
  }

  Future<void> takePhoto(String type, {required bool isBike}) async {
    final photo = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );

    if (photo == null || !mounted) return;

    setState(() {
      if (isBike) {
        switch (type) {
          case 'idcard':
            bikeIdCardImage = photo;
            bikeIdCardUrl = null;
            break;
          case 'license':
            bikeLicenseImage = photo;
            bikeLicenseUrl = null;
            break;
          case 'vehicle':
            bikeVehicleBookImage = photo;
            bikeVehicleBookUrl = null;
            break;
          case 'insurance':
            bikeInsuranceImage = photo;
            bikeInsuranceUrl = null;
            break;
        }
      } else {
        switch (type) {
          case 'idcard':
            carIdCardImage = photo;
            carIdCardUrl = null;
            break;
          case 'license':
            carLicenseImage = photo;
            carLicenseUrl = null; 
            break;
          case 'vehicle':
            carVehicleBookImage = photo;
            carVehicleBookUrl = null;
            break;
          case 'insurance':
            carInsuranceImage = photo;
            carInsuranceUrl = null;
            break;
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    checkDocProvider();
  }

  @override
  void dispose() {
    carPlateCtl.dispose();
    bikePlateCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        // เช็คว่าถ้าเป็นครั้งแรก (isFirstSetup == true) ให้ leading เป็น null (ไม่มีปุ่ม)
        // แต่ถ้าไม่ใช่ครั้งแรก ให้แสดงปุ่ม BackButton ตามปกติ
        leading: widget.isFirstSetup
            ? null
            : const BackButton(color: Colors.white),

        title: const Text(
          "เอกสารที่เกี่ยวข้อง",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 255, 0, 0),
        automaticallyImplyLeading: !widget.isFirstSetup,
      ),

      body: DefaultTabController(
        length: 2,

        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: TabBar(
                  indicatorColor: const Color.fromARGB(255, 255, 0, 0),
                  indicatorSize: TabBarIndicatorSize.tab,

                  onTap: (index) {
                    setState(() {
                      vehicleType = index == 0 ? 1 : 0;
                    });

                    print('vehicleType = $vehicleType');
                  },

                  tabs: const [
                    Tab(
                      child: Text(
                        "Car",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Tab(
                      child: Text(
                        "Bike",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 15),

              Expanded(
                child: TabBarView(
                  children: [
                    //tab car
                    SingleChildScrollView(
                      child: Column(
                        children: [
                          // ทะเบียนรถ
                          _buildRejectBanner(carDocument),
                          if (carStatus == 0 || carStatus == 1)
                            Row(
                              children: [
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: carStatus == 1
                                        ? Colors.green.withOpacity(0.1)
                                        : Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        carStatus == 1
                                            ? Icons.check_circle
                                            : Icons.access_time_filled,
                                        size: 16,
                                        color: carStatus == 1
                                            ? Colors.green
                                            : Colors.orange.shade700,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        carStatus == 1
                                            ? "อนุมัติแล้ว"
                                            : "รออนุมัติ",
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: carStatus == 1
                                              ? Colors.green
                                              : Colors.orange.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          Row(
                            children: [
                              const Text(
                                'ทะเบียนรถ:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  controller: carPlateCtl,
                                  readOnly: !_canEdit(false),
                                  decoration: const InputDecoration(
                                    labelText: 'ทะเบียนรถยนต์',
                                    border: UnderlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          _buildDocumentItem(
                            title: 'รูปบัตรประชาชน:',
                            imageUrl: carIdCardUrl,
                            imageFile: carIdCardImage,
                            photoType: 'idcard',
                            isBike: false,
                          ),
                          SizedBox(height: 10),
                          const Divider(
                            color: Colors.grey,
                            thickness: 2,
                            height: 30,
                          ),

                          _buildDocumentItem(
                            title: 'รูปใบอนุญาตขับขี่:',
                            imageUrl: carLicenseUrl,
                            imageFile: carLicenseImage,
                            photoType: 'license',
                            isBike: false,
                          ),
                          SizedBox(height: 10),
                          const Divider(
                            color: Colors.grey,
                            thickness: 2,
                            height: 30,
                          ),

                          _buildDocumentItem(
                            title: 'รูปเอกสารหน้าเล่ม:',
                            imageUrl: carVehicleBookUrl,
                            imageFile: carVehicleBookImage,
                            photoType: 'vehicle',
                            isBike: false,
                          ),
                          SizedBox(height: 10),
                          const Divider(
                            color: Colors.grey,
                            thickness: 2,
                            height: 30,
                          ),

                          _buildDocumentItem(
                            title: 'รูป พ.ร.บ. รถ:',
                            imageUrl: carInsuranceUrl,
                            imageFile: carInsuranceImage,
                            photoType: 'insurance',
                            isBike: false,
                          ),
                          SizedBox(height: 10),

                          const Divider(
                            color: Colors.grey,
                            thickness: 2,
                            height: 30,
                          ),

                          const SizedBox(height: 50),

                          // แสดงปุ่มบันทึกเมื่อยังไม่มีเอกสารรถยนต์
                          if (_canEdit(false))
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
                                onPressed: isLoading
                                    ? null
                                    : () => saveProvider(1),
                                child: const Text('บันทึก'),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // tab bike
                    SingleChildScrollView(
                      child: Column(
                        children: [
                          // ทะเบียนมอเตอร์ไซค์
                          _buildRejectBanner(bikeDocument),
                          if (bikeStatus == 0 || bikeStatus == 1)
                            Row(
                              children: [
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: bikeStatus == 1
                                        ? Colors.green.withOpacity(0.1)
                                        : Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        bikeStatus == 1
                                            ? Icons.check_circle
                                            : Icons.access_time_filled,
                                        size: 16,
                                        color: bikeStatus == 1
                                            ? Colors.green
                                            : Colors.orange.shade700,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        bikeStatus == 1
                                            ? "อนุมัติแล้ว"
                                            : "รออนุมัติ",
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: bikeStatus == 1
                                              ? Colors.green
                                              : Colors.orange.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          Row(
                            children: [
                              const Text(
                                'ทะเบียนรถ:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  controller: bikePlateCtl,
                                  readOnly: !_canEdit(true),
                                  decoration: const InputDecoration(
                                    labelText: 'ทะเบียนมอเตอร์ไซค์',
                                    border: UnderlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // รูปบัตรประชาชน
                          _buildDocumentItem(
                            title: 'รูปบัตรประชาชน:',
                            imageUrl: bikeIdCardUrl,
                            imageFile: bikeIdCardImage,
                            photoType: 'idcard',
                            isBike: true,
                          ),

                          SizedBox(height: 10),
                          const Divider(
                            color: Colors.grey,
                            thickness: 2,
                            height: 30,
                          ),

                          _buildDocumentItem(
                            title: 'รูปใบอนุญาตขับขี่:',
                            imageUrl: bikeLicenseUrl,
                            imageFile: bikeLicenseImage,
                            photoType: 'license',
                            isBike: true,
                          ),
                          SizedBox(height: 10),
                          const Divider(
                            color: Colors.grey,
                            thickness: 2,
                            height: 30,
                          ),

                          _buildDocumentItem(
                            title: 'รูปเอกสารหน้าเล่ม:',
                            imageUrl: bikeVehicleBookUrl,
                            imageFile: bikeVehicleBookImage,
                            photoType: 'vehicle',
                            isBike: true,
                          ),
                          SizedBox(height: 10),
                          const Divider(
                            color: Colors.grey,
                            thickness: 2,
                            height: 30,
                          ),

                          _buildDocumentItem(
                            title: 'รูป พ.ร.บ. รถ:',
                            imageUrl: bikeInsuranceUrl,
                            imageFile: bikeInsuranceImage,
                            photoType: 'insurance',
                            isBike: true,
                          ),
                          SizedBox(height: 10),

                          const Divider(
                            color: Colors.grey,
                            thickness: 2,
                            height: 30,
                          ),

                          const SizedBox(height: 50),

                          // แสดงปุ่มบันทึกเมื่อยังไม่มีเอกสารมอเตอร์ไซค์
                          if (_canEdit(true))
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
                                onPressed: isLoading
                                    ? null
                                    : () => saveProvider(0),
                                child: const Text('บันทึก'),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentItem({
    required String title,
    required String? imageUrl,
    required XFile? imageFile,
    required String photoType,
    required bool isBike,
  }) {
    final document = isBike ? bikeDocument : carDocument;
    final bool hasDocument = !_canEdit(isBike);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (!hasDocument)
              ElevatedButton(
                onPressed: () => takePhoto(photoType, isBike: isBike),
                child: const Text('แนบไฟล์'),
              ),
          ],
        ),
        const SizedBox(height: 8),

        if (imageUrl != null && imageUrl.isNotEmpty)
          GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => Dialog(
                  child: InteractiveViewer(
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          const Text('ไม่สามารถโหลดรูปภาพได้'),
                    ),
                  ),
                ),
              );
            },
            child: const Row(
              children: [
                Icon(Icons.image, color: Colors.red),
                SizedBox(width: 8),
                Expanded(child: Text('ดูรูปเอกสารที่บันทึกไว้')),
                Icon(Icons.visibility),
              ],
            ),
          )
        else if (imageFile != null)
          GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => Dialog(child: Image.file(File(imageFile.path))),
              );
            },
            child: Row(
              children: [
                const Icon(Icons.insert_drive_file, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    imageFile.name,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          )
        else
          const Text('ยังไม่ได้แนบไฟล์', style: TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildRejectBanner(Map<String, dynamic>? doc) {
    if (!_isRejected(doc)) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'เอกสารไม่ผ่าน: ${doc?['reject_reason'] ?? '-'}\nกรุณาแก้ไขแล้วส่งใหม่',
        style: const TextStyle(color: Colors.red),
      ),
    );
  }

  Future<void> checkDocProvider() async {
    try {
      debugPrint('pid: ${widget.pid}');
      final results = await Future.wait([
        FirebaseFirestore.instance
            .collection('document')
            .where('pid', isEqualTo: widget.pid)
            .where('vehicle_type', isEqualTo: 1)
            .limit(1)
            .get(),

        FirebaseFirestore.instance
            .collection('document')
            .where('pid', isEqualTo: widget.pid)
            .where('vehicle_type', isEqualTo: 0)
            .limit(1)
            .get(),
      ]);
      if (results[0].docs.isNotEmpty) {
        carDocId = results[0].docs.first.id;
        final doc = results[0].docs.first;

        debugPrint('--- CAR DOCUMENT ---');
        debugPrint('Document ID: ${doc.id}');
        debugPrint('Data: ${doc.data()}');
      } else {
        debugPrint('ไม่พบเอกสารรถยนต์');
      }

      if (results[1].docs.isNotEmpty) {
        bikeDocId = results[1].docs.first.id;
        final doc = results[1].docs.first;

        debugPrint('--- BIKE DOCUMENT ---');
        debugPrint('Document ID: ${doc.id}');
        debugPrint('Data: ${doc.data()}');
      } else {
        debugPrint('ไม่พบเอกสารมอเตอร์ไซค์');
      }

      if (!mounted) return;

      setState(() {
        // Car
        if (results[0].docs.isNotEmpty) {
          carDocument = results[0].docs.first.data();

          carPlateCtl.text = carDocument?['vehicle_Registration'] ?? '';
          carIdCardUrl = carDocument?['IdCard'];
          carLicenseUrl = carDocument?['drivinglicense'];
          carVehicleBookUrl = carDocument?['vehicle_reg_book'];
          carInsuranceUrl = carDocument?['vehicle_insurance_file'];
          carStatus = carDocument?['status_doc'];
          print(carStatus);
        }

        // Bike
        if (results[1].docs.isNotEmpty) {
          bikeDocument = results[1].docs.first.data();

          bikePlateCtl.text = bikeDocument?['vehicle_Registration'] ?? '';
          bikeIdCardUrl = bikeDocument?['IdCard'];
          bikeLicenseUrl = bikeDocument?['drivinglicense'];
          bikeVehicleBookUrl = bikeDocument?['vehicle_reg_book'];
          bikeInsuranceUrl = bikeDocument?['vehicle_insurance_file'];
          bikeStatus = bikeDocument?['status_doc'];
          print(bikeStatus);
        }

        isLoadingDocs = false;
      });
    } catch (e) {
      debugPrint('เกิดข้อผิดพลาดในการโหลดเอกสาร: $e');

      if (!mounted) return;

      setState(() {
        isLoadingDocs = false;
      });
    }
  }

  Future<void> saveProvider(int type) async {
    // type = 1 คือรถยนต์
    // type = 0 คือมอเตอร์ไซค์

    final isBike = type == 0; // ★

    final plate = type == 1 ? carPlateCtl.text : bikePlateCtl.text;
    final idCardFile = type == 1 ? carIdCardImage : bikeIdCardImage;
    final licenseFile = type == 1 ? carLicenseImage : bikeLicenseImage;
    final vehicleFile = type == 1 ? carVehicleBookImage : bikeVehicleBookImage;
    final insuranceFile = type == 1 ? carInsuranceImage : bikeInsuranceImage;

    // ★ เอกสารเดิมของประเภทนี้ (ถ้ามี) และเช็กว่าเป็นการส่งใหม่หลังถูกปฏิเสธหรือไม่
    final existingDoc = isBike ? bikeDocument : carDocument;
    final existingId = isBike ? bikeDocId : carDocId;
    final isResubmit = _isRejected(existingDoc) && existingId != null;

    if (isLoading) return;

    // ★ ตอนส่งใหม่ รูปที่ไม่ได้ถ่ายใหม่ใช้ URL เดิมได้
    bool missing(XFile? file, String key) =>
        file == null &&
        !(isResubmit && (existingDoc?[key] ?? '').toString().isNotEmpty);

    if (missing(idCardFile, 'IdCard') ||
        missing(licenseFile, 'drivinglicense') ||
        missing(vehicleFile, 'vehicle_reg_book') ||
        missing(insuranceFile, 'vehicle_insurance_file') ||
        plate.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกข้อมูลและแนบเอกสารให้ครบ')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // ★ ถ้าเลือกรูปใหม่ให้อัปโหลด ถ้าไม่ได้เลือกให้ใช้ URL เดิม
      Future<String?> pick(XFile? file, String key) async {
        if (file != null) return uploadToCloudinary(File(file.path));
        return existingDoc?[key]?.toString();
      }

      final idCardUrl = await pick(idCardFile, 'IdCard');
      final licenseUrl = await pick(licenseFile, 'drivinglicense');
      final vehicleUrl = await pick(vehicleFile, 'vehicle_reg_book');
      final insuranceUrl = await pick(insuranceFile, 'vehicle_insurance_file');

      if (idCardUrl == null ||
          licenseUrl == null ||
          vehicleUrl == null ||
          insuranceUrl == null) {
        throw Exception('อัปโหลดเอกสารไม่สำเร็จ');
      }

      // ★ ส่งใหม่ = เขียนทับเอกสารเดิม ส่งครั้งแรก/เพิ่มรถ = สร้างเอกสารใหม่
      final docRef = isResubmit
          ? db.collection('document').doc(existingId)
          : db.collection('document').doc();

      final datadocprovider = {
        'pid': widget.pid,
        'vehicle_type': type,
        'vehicle_Registration': plate.trim(),
        'IdCard': idCardUrl,
        'drivinglicense': licenseUrl,
        'vehicle_reg_book': vehicleUrl,
        'vehicle_insurance_file': insuranceUrl,
        'status_doc': 0,
        'reject_reason': null,
      };

      // หา provider -> users ก่อน (ถ้าพังจะได้ยังไม่เขียนอะไรลงไป)
      final providerDoc = await db.collection('provider').doc(widget.pid).get();
      if (!providerDoc.exists) {
        throw Exception('ไม่พบข้อมูล provider PID = ${widget.pid}');
      }

      final providerUid = providerDoc.data()?['provider_uid']?.toString();
      if (providerUid == null || providerUid.isEmpty) {
        throw Exception('ไม่พบ provider_uid');
      }

      final userDoc = await db.collection('users').doc(providerUid).get();
      if (!userDoc.exists) {
        throw Exception('ไม่พบข้อมูลผู้ใช้ uid = $providerUid');
      }

      // เปลี่ยนเป็น "รอตรวจสอบ" เฉพาะคนที่ยังไม่เคยส่ง (0) หรือถูกปฏิเสธ (3)
      // ถ้าเป็น 1 (อนุมัติแล้ว) / 2 (กำลังตรวจ) / 4 (ถูกระงับ) ห้ามแตะ
      final currentStatus = userDoc.data()?['status_account'];
      final shouldSetPending = currentStatus == 0 || currentStatus == 3;

      final batch = db.batch();
      batch.set(docRef, datadocprovider);
      if (shouldSetPending) {
        batch.update(userDoc.reference, {'status_account': 2});
      }
      await batch.commit();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("บันทึกเอกสารสำเร็จ รอการอนุมัติ")),
      );

      if (widget.isFirstSetup) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) =>
                AccountStatusPage(uid: providerUid, pid: widget.pid),
          ),
          (route) => false,
        );
      } else {
        Navigator.pop(context, true);
      }
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
