import 'dart:developer';

import 'package:caremate_application/page/break_status_job.dart';
import 'package:caremate_application/page/calendar_page.dart';
import 'package:caremate_application/page/details_job.dart';
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
                  isLoading
                      ? Center(child: CircularProgressIndicator())
                      : allJobs.isEmpty
                      ? Center(
                          child: Text(
                            'ไม่มีรายการ',
                            style: TextStyle(
                              color: Color.fromARGB(255, 81, 81, 81),
                              fontSize: 16,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: allJobs.length,
                          itemBuilder: (context, index) {
                            var job = allJobs[index];

                            return Padding(
                              padding: EdgeInsets.only(
                                top: index == 0 ? 40 : 0,
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
                                  child: Container(
                                    height: 220,
                                    width: 380,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(16),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.5),
                                          blurRadius: 3,
                                          offset: Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        left: 30,
                                        top: 10,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // สถานที่
                                          Text(
                                            job['place_name'],
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),

                                          SizedBox(height: 10),

                                          // วันที่ + เวลา
                                          Row(
                                            children: [
                                              Icon(Icons.calendar_month),
                                              SizedBox(width: 5),

                                              Text(
                                                job['date'],
                                                style: TextStyle(fontSize: 16),
                                              ),

                                              SizedBox(width: 40),

                                              Icon(Icons.access_time),
                                              SizedBox(width: 5),

                                              Text(
                                                job['start_time'],
                                                style: TextStyle(fontSize: 16),
                                              ),

                                              Text(
                                                " - ",
                                                style: TextStyle(fontSize: 16),
                                              ),

                                              Text(
                                                job['end_time'],
                                                style: TextStyle(fontSize: 16),
                                              ),
                                            ],
                                          ),

                                          SizedBox(height: 10),

                                          // ประเภทรถ
                                          Row(
                                            children: [
                                              Icon(
                                                job['vehicle_type'] == 0
                                                    ? Icons.motorcycle
                                                    : Icons.time_to_leave,
                                              ),

                                              SizedBox(width: 5),

                                              Text(
                                                job['vehicle_type'] == 0
                                                    ? "Bike"
                                                    : "Car",
                                                style: TextStyle(fontSize: 16),
                                              ),
                                            ],
                                          ),

                                          SizedBox(height: 10),

                                          // ค่าบริการ
                                          Row(
                                            children: [
                                              Icon(Icons.money),
                                              SizedBox(width: 5),

                                              Text(
                                                "${job['service_fee']} บาท",
                                                style: TextStyle(fontSize: 16),
                                              ),
                                            ],
                                          ),

                                          SizedBox(height: 15),

                                          // ปุ่ม
                                          TextButton(
                                            style: TextButton.styleFrom(
                                              backgroundColor:
                                                  job['status_drivers'] == 0
                                                  ? Colors.grey
                                                  : job['status_drivers'] == 1
                                                  ? Color.fromARGB(
                                                      255,
                                                      15,
                                                      221,
                                                      0,
                                                    )
                                                  : job['status_drivers'] == 2
                                                  ? const Color.fromARGB(
                                                      255,
                                                      220,
                                                      109,
                                                      102,
                                                    )
                                                  : job['status_drivers'] == 3
                                                  ? Color.fromARGB(
                                                      255,
                                                      15,
                                                      221,
                                                      0,
                                                    )
                                                  : Color.fromARGB(
                                                      255,
                                                      15,
                                                      221,
                                                      0,
                                                    ),
                                              foregroundColor: Colors.white,
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 20,
                                                vertical: 8,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            onPressed: () async {
                                              //print("ได้งาน: ${job['job_id']}");

                                              if (job['status_drivers'] == 3) {
                                                await updateStatusJobs(
                                                  job['job_id'],
                                                  job['all_driver_id'],
                                                );

                                                print(
                                                  "เริ่มทำงาน: ${job['job_id']}",
                                                );

                                                await Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        StatusJob(
                                                          jobId: job['job_id'],
                                                          pid: widget.pid,
                                                        ),
                                                  ),
                                                );

                                                if (!mounted) return;

                                                await queryMyJobs();
                                              }

                                              if (job['status_drivers'] == 4) {
                                                if (job['job_status'] == 3 ||
                                                    job['job_status'] == 4 ||
                                                    job['job_status'] == 5) {
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
                                                } else if (job['job_status'] ==
                                                    6) {
                                                  await Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          BreakStatusJob(
                                                            jobId:
                                                                job['job_id'],
                                                            pid: widget.pid,
                                                          ),
                                                    ),
                                                  );

                                                  if (!mounted) return;

                                                  await queryMyJobs();
                                                } else if (job['job_status'] ==
                                                        7 ||
                                                    job['job_status'] == 8 ||
                                                    job['job_status'] == 9) {
                                                  await Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          StatusReturnJob(
                                                            jobId:
                                                                job['job_id'],
                                                            pid: widget.pid,
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
                                                  ? "รอคัดเลือก"
                                                  : job['status_drivers'] == 1
                                                  ? "ได้รับงานแล้ว"
                                                  : job['status_drivers'] == 2
                                                  ? "ตำแหน่งเต็ม"
                                                  : job['status_drivers'] == 3
                                                  ? "เริ่มทำงาน"
                                                  : "ทำงานต่อ",
                                              style: TextStyle(fontSize: 16),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
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
        if (statusDrivers == 6) {
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
    } catch (e) {
      print("เกิดข้อผิดพลาด: $e");
    }
  }
}
