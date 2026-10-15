import 'package:caremate_application/page/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DriversPage extends StatefulWidget {
  String JobId = "";

  DriversPage({super.key, required this.JobId});

  @override
  State<DriversPage> createState() => _DriversPageState();
}

class _DriversPageState extends State<DriversPage> {
  var db = FirebaseFirestore.instance;

  List<Map<String, dynamic>> driverJobs = [];

  bool isLoading = true;
  double averageRating = 0.0;
  int reviewCount = 0;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    queryDriverJobs();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isSubmitting, // กันกดย้อนกลับระหว่างกำลังบันทึก
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F6F6),
        appBar: AppBar(
          title: const Text(
            'ผู้สมัครทั้งหมด',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color.fromARGB(255, 255, 0, 0),
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
        ),
        body: Stack(
          children: [_buildBody(), if (isSubmitting) _buildSubmittingOverlay()],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (driverJobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 70, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'ไม่มีผู้สมัคร',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: driverJobs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) => _buildDriverCard(driverJobs[index]),
    );
  }

  Widget _buildDriverCard(Map<String, dynamic> driver) {
    final double rating = (driver['averageRating'] as num?)?.toDouble() ?? 0.0;
    final String? imageUrl = driver['profile'] as String?;
    final bool hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: hasImage ? () => _showProfileImage(imageUrl) : null,
            child: CircleAvatar(
              radius: 32,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: hasImage ? NetworkImage(imageUrl) : null,
              child: hasImage
                  ? null
                  : Icon(Icons.person, size: 36, color: Colors.grey.shade500),
            ),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driver['realname'] ?? 'ไม่พบชื่อ',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Colors.amber,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        rating == 0.0
                            ? 'ยังไม่มีรีวิว'
                            : rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          ElevatedButton(
            onPressed: isSubmitting
                ? null
                : () async {
                    final canSelect = await canSelectDriver(widget.JobId);

                    if (!mounted) return;

                    if (!canSelect) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'งานนี้เลยเวลาเริ่มงานแล้ว ไม่สามารถเลือกคนขับได้',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // ถ้ายังไม่ถึงเวลาเริ่มงาน ให้ทำงานตามขั้นตอนเดิม
                    await _onSelectPressed(driver);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'เลือก',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmittingOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.red),
              SizedBox(width: 20),
              Text('กำลังเลือกผู้ให้บริการ...', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onSelectPressed(Map<String, dynamic> driver) async {
    if (isSubmitting) return;

    // 1. dialog ยืนยัน คืนค่า true/false
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('ยืนยันการเลือกผู้สมัคร'),
        content: const Text('คุณต้องเลือกผู้สมัครนี้หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(
              'ยกเลิก',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'ยืนยัน',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // 2. เริ่มบันทึก
    setState(() => isSubmitting = true);

    try {
      await chooseDriver(
        driver['provider_id'],
      ).timeout(const Duration(seconds: 20));

      if (!mounted) return;

      // 3. สำเร็จ → ปิด DriversPage กลับ DetailsJobService
      Navigator.of(context).pop(true);
    } catch (e) {
      print('เกิดข้อผิดพลาด: $e');

      if (!mounted) return;
      setState(() => isSubmitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('เลือกผู้ให้บริการไม่สำเร็จ หรืองานนี้ถูกเลือกไปแล้ว'),
        ),
      );
    }
  }

  Future<bool> canSelectDriver(String jobId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('jobs')
          .doc(jobId)
          .get();

      if (!doc.exists) return false;

      final data = doc.data()!;

      // วันที่รูปแบบ dd/MM/yyyy เช่น 14/10/2026
      final dateParts = (data['date'] as String).split('/');

      // เวลาเริ่มงานรูปแบบ HH:mm เช่น 14:30
      final timeParts = (data['start_time'] as String).split(':');

      final startDateTime = DateTime(
        int.parse(dateParts[2]), // ปี
        int.parse(dateParts[1]), // เดือน
        int.parse(dateParts[0]), // วัน
        int.parse(timeParts[0]), // ชั่วโมง
        int.parse(timeParts[1]), // นาที
      );

      // เลือกคนขับได้เฉพาะก่อนเวลาเริ่มงาน
      return DateTime.now().isBefore(startDateTime);
    } catch (e) {
      debugPrint('ตรวจสอบวันเวลาไม่สำเร็จ: $e');
      return false;
    }
  }

  Future<void> queryDriverJobs() async {
    try {
      setState(() {
        isLoading = true;
      });

      final stopwatch = Stopwatch()..start();

      var snapshot = await db
          .collection('all_drivers')
          .where('job_id', isEqualTo: widget.JobId)
          .where('status_drivers', isEqualTo: 0)
          .get();

      List<Map<String, dynamic>> drivers = [];

      // 2. โหลดข้อมูลแต่ละคน
      await Future.wait(
        snapshot.docs.map((doc) async {
          var driverData = doc.data();

          String? providerId = driverData['provider_id'];

          if (providerId == null) {
            return;
          }

          // provider
          var providerDoc = await db
              .collection('provider')
              .doc(providerId)
              .get();

          if (!providerDoc.exists) {
            return;
          }

          var providerData = providerDoc.data();
          if (providerData == null) {
            return;
          }

          double averageRating = await queryProviderRatings(providerId);

          String? uid = providerData['provider_uid'];

          if (uid == null) {
            return;
          }

          // user
          var userDoc = await db.collection('users').doc(uid).get();

          if (!userDoc.exists) {
            return;
          }

          var userData = userDoc.data();

          if (userData == null) {
            return;
          }

          drivers.add({
            'driver_id': doc.id,
            'provider_id': providerId,
            'uid': uid,
            'realname': userData['realname'],
            'profile': providerData['profile'],
            'averageRating': averageRating,
          });
        }),
      );

      if (!mounted) return;

      setState(() {
        driverJobs = drivers;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching driver jobs: $e");

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> chooseDriver(String driverId) async {
    final jobRef = db.collection('jobs').doc(widget.JobId);

    // กันเลือกซ้ำ
    final jobDoc = await jobRef.get();
    if (jobDoc.data()?['job_status'] != 0) {
      throw Exception('งานนี้ถูกเลือกผู้ให้บริการไปแล้ว');
    }

    final snapshot = await db
        .collection('all_drivers')
        .where('job_id', isEqualTo: widget.JobId)
        .get();

    // อัปเดตทั้งหมดในครั้งเดียว
    final batch = db.batch();

    batch.update(jobRef, {'job_status': 1});

    for (var doc in snapshot.docs) {
      final isChosen = doc.data()['provider_id'] == driverId;
      batch.update(doc.reference, {'status_drivers': isChosen ? 1 : 2});
    }

    await batch.commit();

    // ลบใบสมัครอื่นของคนขับคนนี้ที่เวลาชนกัน
    await deleteConflictingApplications(driverId);
    //สร้างการแจ้งเตือน
    await NotificationService().notifyProviderJobAccepted(
      jobId: widget.JobId,
      providerId: driverId,
    );
  }

  Future<void> deleteConflictingApplications(String driverId) async {
    try {
      // ข้อมูลงานที่เพิ่งได้
      final chosenJobDoc = await db.collection('jobs').doc(widget.JobId).get();
      if (!chosenJobDoc.exists) return;

      final chosenJob = chosenJobDoc.data()!;
      final chosenDate = chosenJob['date'];
      final chosenStart = chosenJob['start_time'];
      final chosenEnd = chosenJob['end_time'];

      // ใบสมัครอื่นของคนขับคนนี้ที่ยังรอผล (0) ไม่รวมงานที่เพิ่งเลือก
      final pendingApps = await db
          .collection('all_drivers')
          .where('provider_id', isEqualTo: driverId)
          .where('status_drivers', isEqualTo: 0)
          .get();

      final otherApps = pendingApps.docs
          .where((d) => d.data()['job_id'] != widget.JobId)
          .toList();

      if (otherApps.isEmpty) return;

      // ดึงข้อมูลงานของใบสมัครเหล่านั้นพร้อมกัน
      final jobDocs = await Future.wait(
        otherApps.map(
          (d) => db.collection('jobs').doc(d.data()['job_id']).get(),
        ),
      );

      final batch = db.batch();
      int deleteCount = 0;

      for (int i = 0; i < otherApps.length; i++) {
        final jobDoc = jobDocs[i];
        if (!jobDoc.exists) continue;

        final job = jobDoc.data()!;

        // คนละวัน → ผ่าน ไม่ต้องลบ
        if (job['date'] != chosenDate) continue;

        // วันเดียวกัน → เช็คเวลาซ้อน/ระยะห่าง 2 ชม.
        final conflict = isTimeConflict(
          startA: chosenStart,
          endA: chosenEnd,
          startB: job['start_time'],
          endB: job['end_time'],
        );

        if (conflict) {
          batch.delete(otherApps[i].reference);
          deleteCount++;
        }
      }

      if (deleteCount > 0) {
        await batch.commit();
      }
    } catch (e) {
      print("deleteConflictingApplications error: $e");
    }
  }

  // แปลงเวลา เช่น 08:30 → 510 นาที
  int timeToMinutes(String time) {
    final parts = time.split(':');
    return (int.parse(parts[0]) * 60) + int.parse(parts[1]);
  }

  /// true = ชนกัน (เวลาซ้อน หรือห่างกันน้อยกว่า minGap นาที)
  bool isTimeConflict({
    required String startA,
    required String endA,
    required String startB,
    required String endB,
    int minGapMinutes = 120,
  }) {
    final aStart = timeToMinutes(startA);
    var aEnd = timeToMinutes(endA);
    final bStart = timeToMinutes(startB);
    var bEnd = timeToMinutes(endB);

    if (aEnd <= aStart) aEnd += 1440; // ข้ามเที่ยงคืน
    if (bEnd <= bStart) bEnd += 1440;

    return aStart < bEnd + minGapMinutes && bStart < aEnd + minGapMinutes;
  }

  Future<double> queryProviderRatings(String providerId) async {
    var ratingsSnapshot = await db
        .collection('review')
        .where('provider_id', isEqualTo: providerId)
        .get();

    if (ratingsSnapshot.docs.isEmpty) {
      return 0.0;
    }

    double totalRating = 0.0;
    int reviewCount = 0;

    for (var doc in ratingsSnapshot.docs) {
      var data = doc.data();
      var rating = data['rating'];

      if (rating != null) {
        totalRating += (rating as num).toDouble();
        reviewCount++;
      }
    }

    if (reviewCount == 0) {
      return 0.0;
    }

    double averageRating = totalRating / reviewCount;

    print('provider_id: $providerId');
    print('จำนวนรีวิว: $reviewCount');
    print('คะแนนเฉลี่ย: $averageRating');

    return averageRating;
  }

  void _showProfileImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              // รูปใหญ่ ซูมเข้า-ออกได้
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const SizedBox(
                        height: 250,
                        child: Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 250,
                        color: Colors.white,
                        child: const Center(
                          child: Icon(Icons.broken_image, size: 60),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // ปุ่มปิด
              Padding(
                padding: const EdgeInsets.all(8),
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(dialogContext),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
