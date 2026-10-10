import 'package:caremate_application/page/status_return_job.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BreakStatusJob extends StatefulWidget {
  String jobId;
  String pid;
  BreakStatusJob({super.key, required this.jobId, required this.pid});

  @override
  State<BreakStatusJob> createState() => _BreakStatusJobState();
}

class _BreakStatusJobState extends State<BreakStatusJob> {
  var db = FirebaseFirestore.instance;
  Map<String, dynamic> detailsJob = {};
  Map<String, dynamic> detailsService = {};
  Map<String, dynamic> detailsUser = {};
  int? statusDrivers;
  bool isLoading = true;
  bool isUpdatingStatus = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    queryJobData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),

      appBar: AppBar(
        title: Row(
          children: [
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              label: Icon(
                Icons.arrow_back_ios,
                color: const Color.fromARGB(255, 255, 255, 255),
              ),
            ),
            Text(
              "สถานะงาน",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: Color.fromARGB(255, 255, 0, 0),
        toolbarHeight: 90,
        automaticallyImplyLeading: false,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 25, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // -------------------------
              // สถานะงาน
              // -------------------------
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.medical_services_outlined,
                        color: Colors.red,
                        size: 28,
                      ),
                    ),

                    const SizedBox(width: 15),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "สถานะปัจจุบัน",
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "อยู่ระหว่างการให้บริการ",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // -------------------------
              // หัวข้อข้อมูลผู้รับบริการ
              // -------------------------
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:
                        detailsService['profile_image'] != null &&
                            detailsService['profile_image']
                                .toString()
                                .isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              detailsService['profile_image'],
                              width: 42,
                              height: 42,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.person_outline,
                                  color: Colors.red,
                                  size: 24,
                                );
                              },
                            ),
                          )
                        : const Icon(
                            Icons.person_outline,
                            color: Colors.red,
                            size: 24,
                          ),
                  ),

                  const SizedBox(width: 12),

                  const Text(
                    "ข้อมูลผู้รับบริการ",
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              // -------------------------
              // Card ข้อมูลผู้รับบริการ
              // -------------------------
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // รูป
                    Container(
                      width: 100,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        Icons.person,
                        color: Colors.grey.shade400,
                        size: 55,
                      ),
                    ),

                    const SizedBox(width: 18),

                    // ข้อมูล
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "ชื่อผู้รับบริการ",
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),

                          const SizedBox(height: 5),

                          Text(
                            detailsUser['username'] ?? "ไม่พบข้อมูล",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 18),

                          const Text(
                            "เบอร์โทรศัพท์",
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),

                          const SizedBox(height: 5),

                          Row(
                            children: [
                              const Icon(
                                Icons.phone,
                                color: Colors.green,
                                size: 18,
                              ),

                              const SizedBox(width: 7),

                              Text(
                                detailsService['phone'] ?? "ไม่พบข้อมูล",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // -------------------------
              // ข้อความแจ้งเตือน
              // -------------------------
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.orange.shade100),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange.shade700,
                      size: 23,
                    ),

                    const SizedBox(width: 10),

                    const Expanded(
                      child: Text(
                        "ขณะนี้อยู่ระหว่างการให้บริการผู้รับบริการ "
                        "เมื่อเสร็จสิ้นการให้บริการแล้ว สามารถเริ่มงานขากลับได้",
                        style: TextStyle(fontSize: 14, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 35),

              // -------------------------
              // ปุ่มเริ่มงานขากลับ
              // -------------------------
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: isUpdatingStatus
                      ? null
                      : () async {
                          await updateStatusJobs(7);
                          print("อัปเดตสถานะงานเป็น 7 สำเร็จ: ${widget.jobId}");
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => StatusReturnJob(
                                jobId: widget.jobId,
                                pid: widget.pid,
                              ),
                            ),
                          );
                        },
                  icon: isUpdatingStatus
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.directions_car, color: Colors.white),
                  label: Text(
                    isUpdatingStatus
                        ? "กำลังเริ่มงานขากลับ..."
                        : "เริ่มงานขากลับ",
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    disabledBackgroundColor: Colors.red,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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

  Future<void> queryJobData() async {
    setState(() {
      isLoading = true;
    });

    try {
      var docSnapshot = await db.collection('jobs').doc(widget.jobId).get();

      if (docSnapshot.exists) {
        var data = docSnapshot.data();

        detailsJob = {...data!, 'job_id': docSnapshot.id};
      }

      if (detailsJob['service_id'] != null) {
        var serviceDoc = await db
            .collection('service')
            .doc(detailsJob['service_id'])
            .get();

        if (serviceDoc.exists) {
          var data = serviceDoc.data();

          detailsService = {...data!, 'sid': serviceDoc.id};
        }
      }

      if (detailsService['service_uid'] != null) {
        var userDoc = await db
            .collection('users')
            .doc(detailsService['service_uid'])
            .get();

        if (userDoc.exists) {
          var data = userDoc.data();

          detailsUser = {...data!, 'uid': userDoc.id};
        }
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching jobs: $e");

      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> updateStatusJobs(int statusJob) async {
    setState(() {
      isUpdatingStatus = true;
    });

    try {
      await db.collection('jobs').doc(widget.jobId).update({
        'job_status': statusJob,
      });

      print("อัปเดต job_status เป็น $statusJob สำเร็จ");
    } catch (e) {
      print("เกิดข้อผิดพลาดในการอัปเดต job_status: $e");
    } finally {
      if (mounted) {
        setState(() {
          isUpdatingStatus = false;
        });
      }
    }
  }
}
