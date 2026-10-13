import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ServiceDetailPage extends StatefulWidget {
  final String sid;
  const ServiceDetailPage({super.key, required this.sid});

  @override
  State<ServiceDetailPage> createState() => _ServiceDetailPageState();
}

class _ServiceDetailPageState extends State<ServiceDetailPage> {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  Map<String, dynamic>? serviceData;
  Map<String, dynamic>? userData;

  List<Map<String, dynamic>> jobData = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadServiceDetails();
  }

  // =========================
  // โหลดข้อมูลผู้ให้บริการ
  // =========================
  Future<void> loadServiceDetails() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      // 1. ดึงข้อมูลผู้ให้บริการ
      final serviceDoc = await db.collection('service').doc(widget.sid).get();

      if (!serviceDoc.exists) {
        if (mounted) {
          setState(() {
            serviceData = null;
            userData = null;
            jobData = [];
            isLoading = false;
          });
        }
        return;
      }

      final loadedServiceData = serviceDoc.data();

      // 2. ดึงข้อมูลบัญชีผู้ใช้ด้วย provider_uid
      final uid = loadedServiceData?['service_uid'];

      Map<String, dynamic>? loadedUserData;

      if (uid != null && uid.toString().isNotEmpty) {
        final userDoc = await db.collection('users').doc(uid.toString()).get();

        if (userDoc.exists) {
          loadedUserData = userDoc.data();
        }
      }

      // 3. ดึงเอกสารทั้งหมดของผู้ให้บริการ
      final jobSnapshot = await db
          .collection('jobs')
          .where('service_id', isEqualTo: widget.sid)
          .get();

      final loadedJobs = jobSnapshot.docs.map((doc) => doc.data()).toList();

      if (!mounted) return;

      setState(() {
        serviceData = loadedServiceData;
        userData = loadedUserData;
        jobData = loadedJobs;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('เกิดข้อผิดพลาดในการโหลดข้อมูล: $e');

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFFD32F2F),
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'รายละเอียดผู้รับบริการ',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (serviceData == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFD32F2F),
          foregroundColor: Colors.white,
          title: const Text('รายละเอียดผู้ให้บริการ'),
        ),
        body: const Center(child: Text('ไม่พบข้อมูลผู้ให้บริการ')),
      );
    }

    final profile = serviceData!['profile']?.toString() ?? '';
    final accountStatus = getAccountStatus(userData?['status_account']);

    final username = userData?['username']?.toString() ?? 'ไม่พบรายชื่อ';

    final email = userData?['email']?.toString() ?? 'ไม่พบอีเมล';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFD32F2F),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'รายละเอียดผู้รับบริการ',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: loadServiceDetails,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // โปรไฟล์ผู้รับบริการ: อยู่กับที่
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: profile.isNotEmpty
                          ? NetworkImage(profile)
                          : null,
                      child: profile.isEmpty
                          ? const Icon(
                              Icons.person,
                              color: Colors.grey,
                              size: 36,
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            username,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildStatusBadge(
                            label: accountStatus['label'] as String,
                            color: accountStatus['color'] as Color,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // หัวข้อรายการงาน: อยู่กับที่
              const Text(
                'ประกาศงาน',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              // รายการงาน: เลื่อนเฉพาะส่วนนี้
              Expanded(
                child: jobData.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: 220,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.work_outline_rounded,
                                  size: 42,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'ยังไม่มีประกาศงาน',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: jobData.length,
                        itemBuilder: (context, index) {
                          return _buildJobCard(jobData[index]);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> getAccountStatus(dynamic value) {
    final status = value is num ? value.toInt() : -1;

    switch (status) {
      case 0:
        return {'label': 'ยังไม่เพิ่มเอกสาร', 'color': Colors.orange};
      case 1:
        return {'label': 'บัญชีใช้งานได้', 'color': Colors.green};
      case 2:
        return {'label': 'รอตรวจสอบเอกสาร', 'color': Colors.blue};
      case 3:
        return {'label': 'ปฏิเสธการอนุมัติบัญชี', 'color': Colors.red};
      case 4:
        return {'label': 'ระงับการใช้งาน', 'color': Colors.grey};
      default:
        return {'label': 'ไม่ทราบสถานะบัญชี', 'color': Colors.grey};
    }
  }

  // =========================
  // แปลงสถานะเอกสาร
  // อ่านจาก document.status_doc
  // =========================
  Map<String, dynamic> getDocumentStatus(dynamic value) {
    final status = value is num ? value.toInt() : -1;

    switch (status) {
      case 0:
        return {'label': 'รอตรวจ', 'color': Colors.orange};
      case 1:
        return {'label': 'อนุมัติแล้ว', 'color': Colors.green};
      case 2:
        return {'label': 'ไม่ผ่าน', 'color': Colors.red};
      default:
        return {'label': 'ไม่ทราบสถานะเอกสาร', 'color': Colors.grey};
    }
  }

  // =========================
  // แปลงประเภทรถ
  // 0 = Bike, 1 = Car
  // =========================
  Map<String, dynamic> getVehicleType(dynamic value) {
    final type = value is num ? value.toInt() : -1;

    switch (type) {
      case 0:
        return {'label': 'มอเตอร์ไซค์ (Bike)', 'icon': Icons.two_wheeler};
      case 1:
        return {'label': 'รถยนต์ (Car)', 'icon': Icons.directions_car_rounded};
      default:
        return {'label': 'ไม่ทราบประเภทรถ', 'icon': Icons.directions_car};
    }
  }

  // =========================
  // Badge แสดงสถานะ
  // =========================
  Widget _buildStatusBadge({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // =========================
  // แสดงแถวรายละเอียด
  // =========================
  Widget _buildDetailRow({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  // =========================
  // การ์ดข้อมูลรถแต่ละประเภท
  // =========================
  Widget _buildJobCard(Map<String, dynamic> document) {
    final placeName = document['place_name']?.toString().trim() ?? '';
    final vehicleType = (document['vehicle_type'] as num?)?.toInt() ?? -1;
    final jobStatus = (document['job_status'] as num?)?.toInt() ?? -1;
    final serviceFee = document['service_fee'];

    final dateValue = document['date'];
    String jobDate = 'ไม่มีข้อมูลวันที่';

    if (dateValue is Timestamp) {
      final date = dateValue.toDate();
      jobDate =
          '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    } else if (dateValue is DateTime) {
      jobDate =
          '${dateValue.day.toString().padLeft(2, '0')}/'
          '${dateValue.month.toString().padLeft(2, '0')}/'
          '${dateValue.year}';
    } else if (dateValue != null && dateValue.toString().isNotEmpty) {
      jobDate = dateValue.toString();
    }

    final vehicleName = switch (vehicleType) {
      0 => 'มอเตอร์ไซค์',
      1 => 'รถยนต์',
      _ => 'ไม่ระบุประเภทรถ',
    };

    final statusInfo = switch (jobStatus) {
      0 => {'label': 'รอผู้ให้บริการ', 'color': Colors.orange},
      1 => {'label': 'มีผู้ให้บริการแล้ว', 'color': Colors.blue},
      2 => {'label': 'ยืนยันงานแล้ว', 'color': Colors.green},
      3 => {'label': 'กำลังไปรับ', 'color': Colors.blue},
      4 => {'label': 'ถึงจุดรับแล้ว', 'color': Colors.teal},
      5 => {'label': 'ถึงจุดหมายแล้ว', 'color': Colors.teal},
      6 => {'label': 'อยู่ระหว่างให้บริการ', 'color': Colors.teal},
      7 => {'label': 'กำลังเดินทางกลับ', 'color': Colors.deepPurple},
      8 => {'label': 'ถึงจุดรับกลับแล้ว', 'color': Colors.teal},
      9 => {'label': 'เสร็จสิ้น', 'color': Colors.green},
      10 => {'label': 'ยกเลิกงาน', 'color': Colors.red},
      _ => {'label': 'ไม่ทราบสถานะ', 'color': Colors.grey},
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // หัวการ์ด
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFD32F2F).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  vehicleType == 0
                      ? Icons.two_wheeler
                      : Icons.directions_car_outlined,
                  color: const Color(0xFFD32F2F),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      placeName.isEmpty ? 'ประกาศงาน' : placeName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      vehicleName,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(
                label: statusInfo['label'] as String,
                color: statusInfo['color'] as Color,
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: Color(0xFFF0F0F0)),
          ),

          const SizedBox(height: 12),

          // วันที่
          _buildDetailRow(
            label: 'วันที่ใช้บริการ',
            value: jobDate,
            icon: Icons.calendar_month_outlined,
          ),

          const SizedBox(height: 12),

          // เวลา
          _buildDetailRow(
            label: 'เวลา',
            value:
                '${document['start_time'] ?? '--:--'} - '
                '${document['end_time'] ?? '--:--'}',
            icon: Icons.access_time_rounded,
          ),

          const SizedBox(height: 12),

          // ค่าบริการ
          _buildDetailRow(
            label: 'ค่าบริการ',
            value: serviceFee == null
                ? 'ไม่มีข้อมูล'
                : '฿${serviceFee is num ? serviceFee.toStringAsFixed(0) : serviceFee}',
            icon: Icons.payments_outlined,
          ),

          const SizedBox(height: 12),

          // สถานะงาน
          _buildDetailRow(
            label: 'สถานะงาน',
            value: statusInfo['label'] as String,
            icon: Icons.info_outline_rounded,
          ),
        ],
      ),
    );
  }
}
