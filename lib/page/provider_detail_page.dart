import 'package:caremate_application/page/provider_review_history.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProviderDetailPage extends StatefulWidget {
  final String pid;

  const ProviderDetailPage({super.key, required this.pid});

  @override
  State<ProviderDetailPage> createState() => _ProviderDetailPageState();
}

class _ProviderDetailPageState extends State<ProviderDetailPage> {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  Map<String, dynamic>? providerData;
  Map<String, dynamic>? userData;

  List<Map<String, dynamic>> documentData = [];

  bool isLoading = true;
  bool isLoadingRating = true;

  double averageRating = 0.0;
  int reviewCount = 0;

  @override
  void initState() {
    super.initState();
    loadProviderDetails();
  }

  // =========================
  // โหลดข้อมูลผู้ให้บริการ
  // =========================
  Future<void> loadProviderDetails() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      // 1. ดึงข้อมูลผู้ให้บริการ
      final providerDoc = await db.collection('provider').doc(widget.pid).get();

      if (!providerDoc.exists) {
        if (mounted) {
          setState(() {
            providerData = null;
            userData = null;
            documentData = [];
            isLoading = false;
          });
        }
        return;
      }

      final loadedProviderData = providerDoc.data();

      // 2. ดึงข้อมูลบัญชีผู้ใช้ด้วย provider_uid
      final uid = loadedProviderData?['provider_uid'];

      Map<String, dynamic>? loadedUserData;

      if (uid != null && uid.toString().isNotEmpty) {
        final userDoc = await db.collection('users').doc(uid.toString()).get();

        if (userDoc.exists) {
          loadedUserData = userDoc.data();
        }
      }

      // 3. ดึงเอกสารทั้งหมดของผู้ให้บริการ
      final documentSnapshot = await db
          .collection('document')
          .where('pid', isEqualTo: widget.pid)
          .get();

      final loadedDocuments = documentSnapshot.docs
          .map((doc) => doc.data())
          .toList();

      // 4. เรียงเอกสารตามประเภทรถ
      loadedDocuments.sort((a, b) {
        final typeA = (a['vehicle_type'] as num?)?.toInt() ?? -1;
        final typeB = (b['vehicle_type'] as num?)?.toInt() ?? -1;
        return typeA.compareTo(typeB);
      });

      if (!mounted) return;

      setState(() {
        providerData = loadedProviderData;
        userData = loadedUserData;
        documentData = loadedDocuments;
        isLoading = false;
      });

      // 5. โหลดคะแนนรีวิว
      await queryProviderRatings();
    } catch (e) {
      debugPrint('เกิดข้อผิดพลาดในการโหลดข้อมูล: $e');

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // =========================
  // โหลดคะแนนรีวิว
  // =========================
  Future<void> queryProviderRatings() async {
    if (mounted) {
      setState(() {
        isLoadingRating = true;
      });
    }

    try {
      final snapshot = await db
          .collection('review')
          .where('provider_id', isEqualTo: widget.pid)
          .get();

      double totalRating = 0;
      int count = 0;

      for (final doc in snapshot.docs) {
        final rating = doc.data()['rating'];

        if (rating is num) {
          totalRating += rating.toDouble();
          count++;
        }
      }

      if (!mounted) return;

      setState(() {
        reviewCount = count;
        averageRating = count == 0 ? 0.0 : totalRating / count;
        isLoadingRating = false;
      });
    } catch (e) {
      debugPrint('เกิดข้อผิดพลาดในการโหลดคะแนน: $e');

      if (mounted) {
        setState(() {
          isLoadingRating = false;
        });
      }
    }
  }

  // =========================
  // แปลงสถานะบัญชี
  // อ่านจาก users.status_account
  // =========================
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
  // แสดงสถิติ
  // =========================
  Widget _buildInfoTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================
  // การ์ดข้อมูลรถแต่ละประเภท
  // =========================
  Widget _buildVehicleCard(Map<String, dynamic> document) {
    final vehicle = getVehicleType(document['vehicle_type']);
    final status = getDocumentStatus(document['status_doc']);

    final registration =
        document['vehicle_Registration']?.toString().trim() ?? '';

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
                  vehicle['icon'] as IconData,
                  color: const Color(0xFFD32F2F),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  vehicle['label'] as String,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildStatusBadge(
                label: status['label'] as String,
                color: status['color'] as Color,
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: Color(0xFFF0F0F0)),
          ),
          _buildDetailRow(
            label: 'ทะเบียนรถ',
            value: registration.isEmpty ? 'ไม่มีข้อมูล' : registration,
            icon: Icons.badge_outlined,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            label: 'สถานะตรวจสอบ',
            value: status['label'] as String,
            icon: Icons.verified_outlined,
          ),
        ],
      ),
    );
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
            'รายละเอียดผู้ให้บริการ',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (providerData == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFD32F2F),
          foregroundColor: Colors.white,
          title: const Text('รายละเอียดผู้ให้บริการ'),
        ),
        body: const Center(child: Text('ไม่พบข้อมูลผู้ให้บริการ')),
      );
    }

    final profile = providerData!['profile']?.toString() ?? '';
    final accountStatus = getAccountStatus(userData?['status_account']);

    final realName = userData?['realname']?.toString() ?? 'ไม่พบรายชื่อ';

    final email = userData?['email']?.toString() ?? 'ไม่พบอีเมล';

    final reportsNum = providerData!['reports_num'];
    final reportCount = reportsNum is num ? reportsNum.toInt() : 0;

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
          'รายละเอียดผู้ให้บริการ',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: loadProviderDetails,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =========================
              // การ์ดโปรไฟล์ผู้ให้บริการ
              // =========================
              Container(
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
                  children: [
                    Row(
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
                                realName,
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
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Divider(
                        height: 1,
                        thickness: 0.6,
                        color: Color(0xFFEEEEEE),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoTile(
                            icon: Icons.star_rounded,
                            iconColor: Colors.amber.shade700,
                            label: 'คะแนนเฉลี่ย',
                            value: isLoadingRating
                                ? 'กำลังโหลด...'
                                : '${averageRating.toStringAsFixed(1)} / 5.0',
                          ),
                        ),
                        Container(
                          height: 30,
                          width: 1,
                          color: Colors.grey[200],
                        ),
                        Expanded(
                          child: _buildInfoTile(
                            icon: Icons.warning_amber_rounded,
                            iconColor: Colors.red.shade700,
                            label: 'การโดนรายงาน',
                            value: '$reportCount ครั้ง',
                          ),
                        ),
                      ],
                    ),
                    if (!isLoadingRating) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'รีวิวทั้งหมด $reviewCount รายการ',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // =========================
              // ข้อมูลยานพาหนะ
              // =========================
              const Text(
                'ข้อมูลยานพาหนะ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 12),

              if (documentData.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.directions_car_outlined,
                        size: 42,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'ยังไม่มีเอกสารยานพาหนะ',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              else
                ...documentData.map(_buildVehicleCard),

              const SizedBox(height: 32),

              // =========================
              // ปุ่มจัดการสำหรับ Admin
              // =========================
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD32F2F),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ProviderReviewHistory(pid: widget.pid),
                          ),
                        );
                      },
                      icon: const Icon(Icons.history),
                      label: const Text(
                        'ประวัติรีวิว',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
