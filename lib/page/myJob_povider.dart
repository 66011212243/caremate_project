import 'dart:developer';

import 'package:caremate_application/page/break_status_job.dart';
import 'package:caremate_application/page/calendar_page.dart';
import 'package:caremate_application/page/details_job.dart';
import 'package:caremate_application/page/notification_service.dart';
import 'package:caremate_application/page/status_job.dart';
import 'package:caremate_application/page/status_return_job.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyjobPovider extends StatefulWidget {
  String pid = "";
  MyjobPovider({super.key, required this.pid});

  @override
  State<MyjobPovider> createState() => _MyjobPoviderState();
}

class _MyjobPoviderState extends State<MyjobPovider> {
  int _selectedIndex = 1;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  var db = FirebaseFirestore.instance;
  List<Map<String, dynamic>> allJobs = [];
  bool isLoading = true;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    queryMyJobs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: TabBar(
                indicatorColor: Color.fromARGB(255, 255, 0, 0),
                indicatorSize: TabBarIndicatorSize.tab,

                tabs: [
                  Tab(
                    child: Text(
                      "งานทั้งหมด",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Tab(
                    child: Text(
                      "ปฏิทิน",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  //tap 1
                  RefreshIndicator(
                    onRefresh: queryMyJobs,
                    child: isLoading
                        ? Center(child: CircularProgressIndicator())
                        : allJobs.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height: 400, // ปรับตามความสูงพื้นที่แสดงรายการ
                                child: const Center(
                                  child: Text(
                                    'ไม่มีรายการ',
                                    style: TextStyle(
                                      color: Color.fromARGB(255, 81, 81, 81),
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: allJobs.length,
                            itemBuilder: (context, index) {
                              var job = allJobs[index];

                              return Padding(
                                padding: EdgeInsets.only(
                                  top: index == 0 ? 20 : 0,
                                  bottom: 30,
                                ),
                                child: Center(
                                  child: InkWell(
                                    onTap: () async {
                                      print('job_id: ${job['job_id']}');
                                      print('pid: ${widget.pid}');

                                      final result = await Navigator.of(context)
                                          .push(
                                            MaterialPageRoute(
                                              builder: (context) => DetailsJob(
                                                jobId: job['job_id'],
                                                pid: widget.pid,
                                              ),
                                            ),
                                          );

                                      print('กลับมาจาก DetailsJob: $result');

                                      if (result == true) {
                                        await queryMyJobs();
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      child: Container(
                                        width: 380,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.06,
                                              ),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // --- Header: ชื่อสถานที่ ---
                                              Text(
                                                job['place_name'] ??
                                                    'ไม่ระบุสถานที่',
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),

                                              const Divider(
                                                height: 17,
                                                thickness: 0.8,
                                              ),

                                              // --- Body: วันที่ และเวลา ---
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.calendar_month,
                                                    size: 18,
                                                    color: Colors.redAccent,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    job['date'] ?? '',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 20),
                                                  const Icon(
                                                    Icons.access_time,
                                                    size: 18,
                                                    color: Colors.redAccent,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    "${job['start_time']} - ${job['end_time']}",
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),

                                              const SizedBox(height: 6),

                                              // --- Vehicle: ประเภทรถ ---
                                              Row(
                                                children: [
                                                  Icon(
                                                    job['vehicle_type'] == 0
                                                        ? Icons.two_wheeler
                                                        : Icons.directions_car,
                                                    size: 18,
                                                    color: Colors.grey.shade700,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    job['vehicle_type'] == 0
                                                        ? "Bike"
                                                        : "Car",
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),

                                              const SizedBox(height: 10),

                                              // --- Footer: ค่าบริการ ---
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.payments_outlined,
                                                    size: 18,
                                                    color: Colors.green,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    " ${job['service_fee']} บาท",
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color.fromARGB(
                                                        255,
                                                        220,
                                                        0,
                                                        0,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),

                                              const SizedBox(height: 12),

                                              // --- ปุ่ม ---
                                              SizedBox(
                                                width: double.infinity,
                                                child: TextButton(
                                                  style: TextButton.styleFrom(
                                                    backgroundColor:
                                                        job['status_drivers'] ==
                                                            0
                                                        ? Colors.grey
                                                        : job['status_drivers'] ==
                                                              1
                                                        ? const Color.fromARGB(
                                                            255,
                                                            15,
                                                            221,
                                                            0,
                                                          )
                                                        : job['status_drivers'] ==
                                                              2
                                                        ? const Color.fromARGB(
                                                            255,
                                                            220,
                                                            109,
                                                            102,
                                                          )
                                                        : const Color.fromARGB(
                                                            255,
                                                            15,
                                                            221,
                                                            0,
                                                          ),
                                                    foregroundColor:
                                                        Colors.white,
                                                    minimumSize: const Size(
                                                      double.infinity,
                                                      44,
                                                    ),
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 20,
                                                          vertical: 10,
                                                        ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                    ),
                                                  ),
                                                  onPressed: () async {
                                                    // เริ่มทำงาน
                                                    if (job['status_drivers'] ==
                                                        3) {
                                                      await updateStatusJobs(
                                                        job['job_id'],
                                                        job['all_driver_id'],
                                                      );

                                                      print(
                                                        'เริ่มทำงาน: ${job['job_id']}',
                                                      );

                                                      await Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              StatusJob(
                                                                jobId:
                                                                    job['job_id'],
                                                                pid: widget.pid,
                                                              ),
                                                        ),
                                                      );

                                                      if (!mounted) return;

                                                      await queryMyJobs();
                                                    }

                                                    // ทำงานต่อ
                                                    if (job['status_drivers'] ==
                                                        4) {
                                                      if (job['job_status'] ==
                                                              3 ||
                                                          job['job_status'] ==
                                                              4 ||
                                                          job['job_status'] ==
                                                              5) {
                                                        await Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder:
                                                                (
                                                                  context,
                                                                ) => StatusJob(
                                                                  jobId:
                                                                      job['job_id'],
                                                                  pid: widget
                                                                      .pid,
                                                                ),
                                                          ),
                                                        );

                                                        if (!mounted) return;

                                                        await queryMyJobs();
                                                      } else if (job['job_status'] ==
                                                          6) {
                                                        await Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                BreakStatusJob(
                                                                  jobId:
                                                                      job['job_id'],
                                                                  pid: widget
                                                                      .pid,
                                                                ),
                                                          ),
                                                        );

                                                        if (!mounted) return;

                                                        await queryMyJobs();
                                                      } else if (job['job_status'] ==
                                                              7 ||
                                                          job['job_status'] ==
                                                              8 ||
                                                          job['job_status'] ==
                                                              9) {
                                                        await Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                StatusReturnJob(
                                                                  jobId:
                                                                      job['job_id'],
                                                                  pid: widget
                                                                      .pid,
                                                                ),
                                                          ),
                                                        );

                                                        if (!mounted) return;

                                                        await queryMyJobs();
                                                      }
                                                    }
                                                  },
                                                  child: Text(
                                                    job['status_drivers'] == 0
                                                        ? 'รอคัดเลือก'
                                                        : job['status_drivers'] ==
                                                              1
                                                        ? 'ได้รับงานแล้ว'
                                                        : job['status_drivers'] ==
                                                              2
                                                        ? 'ตำแหน่งเต็ม'
                                                        : job['status_drivers'] ==
                                                              3
                                                        ? 'เริ่มทำงาน'
                                                        : 'ทำงานต่อ',
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  //tap 2
                  CalendarPage(pid: widget.pid),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> queryMyJobs() async {
    setState(() {
      isLoading = true;
    });

    try {
      // 1. หางานทั้งหมดที่ provider คนนี้สมัคร
      var applicationSnapshot = await db
          .collection('all_drivers')
          .where('provider_id', isEqualTo: widget.pid)
          .get();

      List<Map<String, dynamic>> tempList = [];

      // 2. เอา job_id ไปค้นรายละเอียดงาน
      for (var doc in applicationSnapshot.docs) {
        var applicationData = doc.data();

        // แปลง status_drivers ให้เป็น int
        final statusDrivers =
            int.tryParse('${applicationData['status_drivers']}') ?? 0;

        // ไม่เอางานที่ status_drivers = 6
        if (statusDrivers == 6 || statusDrivers == 7) {
          continue;
        }

        String jobId = applicationData['job_id'];

        var jobDoc = await db.collection('jobs').doc(jobId).get();

        log("jobDoc for jobId $jobId: ${jobDoc.data()}");
        log("applicationData for jobId $jobId: $applicationData");

        // 3. ถ้ามีงานนี้อยู่
        if (jobDoc.exists) {
          var jobData = jobDoc.data()!;

          // ไม่เอางานที่ job_status = 9 (ยกเลิก/เสร็จตาม logic ที่กำหนด)
          if (jobData['job_status'] != 9) {
            tempList.add({
              ...jobData,
              'job_id': jobDoc.id,
              'all_driver_id': doc.id,
              'status_drivers': statusDrivers,
            });
          }
        }
      }

      setState(() {
        allJobs = tempList;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching my jobs: $e");

      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> updateStatusJobs(String jobId, String statusId) async {
    try {
      await db.collection('jobs').doc(jobId).update({'job_status': 3});

      await db.collection('all_drivers').doc(statusId).update({
        'status_drivers': 4,
      });

      print("อัปเดตสถานะงานสำเร็จ");
      await NotificationService().notifyServiceProviderStartedJob(jobId: jobId);
    } catch (e) {
      print("เกิดข้อผิดพลาด: $e");
    }
  }
}
