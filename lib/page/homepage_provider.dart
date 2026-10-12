import 'dart:developer';

import 'package:caremate_application/page/details_job.dart';
import 'package:caremate_application/page/document.dart';
import 'package:caremate_application/page/myJob_povider.dart';
import 'package:caremate_application/page/notification_system.dart';
import 'package:caremate_application/page/notifications_page.dart';
import 'package:caremate_application/page/setting_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../functions/details_job_functions.dart';

class HomepageProvider extends StatefulWidget {
  final String uid;

  const HomepageProvider({super.key, required this.uid});

  @override
  State<HomepageProvider> createState() => _HomepageProviderState();
}

class _HomepageProviderState extends State<HomepageProvider> {
  var db = FirebaseFirestore.instance;
  String pid = '';
  List<Map<String, dynamic>> allJobs = [];
  List<Map<String, dynamic>> filteredJobs = [];
  int? selectedHour;
  bool isLoading = true;
  bool isAccountLoaded = false;

  int _selectedIndex = 0;
  int? statusAccount;

  int? statusDoc;
  String? rejectReason;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // ตั้งค่า Firebase Messaging
    NotificationSystem().setupNotification(widget.uid);
    loadData();
  }

  Future<void> loadData() async {
    await loadProviderData(); // ได้ pid
    await loadUserData(); // ได้ statusAccount
    await loadDocumentData(); // ได้ rejectReason

    // โหลดงานเฉพาะบัญชีที่อนุมัติแล้ว (ผมสมมติว่า 1 = อนุมัติ)
    if (statusAccount == 1) {
      await queryJobData();
    }

    if (!mounted) return;

    setState(() {
      isAccountLoaded = true;
    });

    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   if (!mounted) return;

    //   if (statusAccount == 0) {
    //     showAccountPendingDialog(context, pid);
    //   } else if (statusAccount == 2) {
    //     showAccountApproveDialog(context);
    //   } else if (statusAccount == 3) {
    //     showAccountRejectDialog(context, rejectReason, pid);
    //   } else if (statusAccount == 4) {
    //     showAccountDisableDialog(context);
    //   }
    // });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      Container(),
      MyjobPovider(pid: pid),
      NotificationsPage(uid: widget.uid),
      SettingsProvider(pid: pid),
    ];
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 255, 255),

      appBar: AppBar(
        title: Text(
          _selectedIndex == 0
              ? "ประกาศจ้าง"
              : _selectedIndex == 1
              ? "งานของฉัน"
              : _selectedIndex == 2
              ? "การแจ้งเตือน"
              : "การตั้งค่า",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color.fromARGB(255, 255, 0, 0),
        toolbarHeight: 90,
        automaticallyImplyLeading: false,
      ),

      body: _selectedIndex == 0
          ? !isAccountLoaded
                ? Center(child: CircularProgressIndicator())
                : statusAccount == 4
                ? const Center(
                    child: Text(
                      'บัญชีของคุณถูกระงับการใช้งานชั่วคราว\n'
                      'ไม่สามารถสมัครงานได้ในขณะนี้',
                    ),
                  )
                : Column(
                    children: [
                      // =========================
                      // ปุ่มกรองเวลา
                      // =========================
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Container(
                          height: 40,
                          color: Colors.white,
                          child: Row(
                            children: [
                              // ปุ่มทั้งหมด ล็อกอยู่ด้านซ้าย
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 15,
                                  right: 8,
                                ),
                                child: SizedBox(
                                  width: 100,
                                  height: 42,
                                  child: ElevatedButton(
                                    onPressed: showAllJobs,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: selectedHour == null
                                          ? Colors.red
                                          : Colors.white,
                                      foregroundColor: selectedHour == null
                                          ? Colors.white
                                          : Colors.red,
                                      elevation: 0,
                                      side: const BorderSide(color: Colors.red),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      'ทั้งหมด',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // =========================
                              // ปุ่มเวลา เลื่อนได้
                              // =========================
                              Expanded(
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: 24,
                                  itemBuilder: (context, index) {
                                    final hour = index;

                                    final isSelected = selectedHour == hour;

                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: SizedBox(
                                        width: 90,
                                        height: 42,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            filterJobsByStartHour(hour);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isSelected
                                                ? Colors.red
                                                : Colors.white,
                                            foregroundColor: isSelected
                                                ? Colors.white
                                                : Colors.red,
                                            elevation: 0,
                                            side: const BorderSide(
                                              color: Colors.red,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: Text(
                                            '${hour.toString().padLeft(2, '0')}:00',
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // เส้นคั่นบาง ๆ
                      Container(height: 1, color: Colors.grey.shade200),

                      // =========================
                      // รายการงาน
                      // =========================
                      Expanded(
                        child: filteredJobs.isEmpty
                            ? const Center(
                                child: Text(
                                  'ไม่มีรายการ',
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 81, 81, 81),
                                    fontSize: 16,
                                  ),
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: queryJobData,
                                child: ListView.builder(
                                  itemCount: filteredJobs.length,
                                  itemBuilder: (context, index) {
                                    var job = filteredJobs[index];

                                    return Container(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (index == 0)
                                            const SizedBox(height: 20),

                                          Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 10,
                                            ),
                                            child: Center(
                                              child: InkWell(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                onTap: () async {
                                                  print(
                                                    'job_id: ${job['job_id']}',
                                                  );
                                                  print('pid: $pid');

                                                  await Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          DetailsJob(
                                                            jobId:
                                                                job['job_id'],
                                                            pid: pid,
                                                          ),
                                                    ),
                                                  );

                                                  // กลับมาแล้วโหลดใหม่
                                                  if (!mounted) return;
                                                  await queryJobData();
                                                },
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 8,
                                                      ),
                                                  child: Container(
                                                    height: 160,
                                                    width: 380,
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            16,
                                                          ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black
                                                              .withOpacity(
                                                                0.06,
                                                              ),
                                                          blurRadius: 10,
                                                          offset: const Offset(
                                                            0,
                                                            4,
                                                          ),
                                                        ),
                                                      ],
                                                    ),

                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            16,
                                                          ),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          // --- Header: ชื่อสถานที่ ---
                                                          Text(
                                                            job['place_name'] ??
                                                                'ไม่ระบุสถานที่',
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 18,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: Colors
                                                                      .black87,
                                                                ),
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),

                                                          const Divider(
                                                            height: 17,
                                                            thickness: 0.8,
                                                          ),

                                                          // --- Body: วันที่ และเวลา ---
                                                          Row(
                                                            children: [
                                                              const Icon(
                                                                Icons
                                                                    .calendar_month,
                                                                size: 18,
                                                                color: Colors
                                                                    .redAccent,
                                                              ),
                                                              const SizedBox(
                                                                width: 6,
                                                              ),
                                                              Text(
                                                                job['date'] ??
                                                                    '',
                                                                style:
                                                                    const TextStyle(
                                                                      fontSize:
                                                                          14,
                                                                    ),
                                                              ),
                                                              const SizedBox(
                                                                width: 20,
                                                              ),
                                                              const Icon(
                                                                Icons
                                                                    .access_time,
                                                                size: 18,
                                                                color: Colors
                                                                    .redAccent,
                                                              ),
                                                              const SizedBox(
                                                                width: 6,
                                                              ),
                                                              Text(
                                                                "${job['start_time']} - ${job['end_time']}",
                                                                style:
                                                                    const TextStyle(
                                                                      fontSize:
                                                                          14,
                                                                    ),
                                                              ),
                                                            ],
                                                          ),

                                                          const SizedBox(
                                                            height: 6,
                                                          ),

                                                          // --- Vehicle: ประเภทรถ ---
                                                          Row(
                                                            children: [
                                                              Icon(
                                                                job['vehicle_type'] ==
                                                                        0
                                                                    ? Icons
                                                                          .two_wheeler
                                                                    : Icons
                                                                          .directions_car,
                                                                size: 18,
                                                                color: Colors
                                                                    .grey
                                                                    .shade700,
                                                              ),
                                                              const SizedBox(
                                                                width: 6,
                                                              ),
                                                              Text(
                                                                job['vehicle_type'] ==
                                                                        1
                                                                    ? 'Car'
                                                                    : 'Bike',
                                                                style: const TextStyle(
                                                                  fontSize: 14,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                ),
                                                              ),
                                                            ],
                                                          ),

                                                          const SizedBox(
                                                            height: 10,
                                                          ),

                                                          // --- Footer: ค่าบริการ ---
                                                          Row(
                                                            children: [
                                                              const Icon(
                                                                Icons
                                                                    .payments_outlined,
                                                                size: 18,
                                                                color: Colors
                                                                    .green,
                                                              ),
                                                              const SizedBox(
                                                                width: 4,
                                                              ),
                                                              Text(
                                                                " ${job['service_fee']} บาท",
                                                                style: const TextStyle(
                                                                  fontSize: 16,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color:
                                                                      Color.fromARGB(
                                                                        255,
                                                                        220,
                                                                        0,
                                                                        0,
                                                                      ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                      ),
                    ],
                  )
          : pages[_selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color.fromARGB(255, 255, 0, 0),
        currentIndex: _selectedIndex,

        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });

          if (index == 0 && statusAccount != null) {
            loadData();
          }
        },

        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "หน้าหลัก"),
          BottomNavigationBarItem(icon: Icon(Icons.work), label: "งาน"),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: "ข้อความ",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "ตั้งค่า"),
        ],
      ),
    );
  }

  Future<void> queryJobData() async {
    setState(() {
      isLoading = true;
    });

    try {
      var querySnapshot = await db
          .collection('jobs')
          .where('job_status', isEqualTo: 0)
          .get();

      List<Map<String, dynamic>> tempList = [];

      for (var doc in querySnapshot.docs) {
        var data = doc.data();

        var fullData = {...data, 'job_id': doc.id};

        tempList.add(fullData);
      }

      setState(() {
        allJobs = tempList;
        filteredJobs = tempList;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching jobs: $e");

      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> loadProviderData() async {
    try {
      final result = await db
          .collection('provider')
          .where('provider_uid', isEqualTo: widget.uid)
          .limit(1)
          .get();

      if (result.docs.isEmpty) {
        print("ไม่พบข้อมูล provider ของ uid: ${widget.uid}");

        setState(() {
          isLoading = false;
        });

        return;
      }

      final providerDoc = result.docs.first;

      // provider.doc.id = pid
      pid = providerDoc.id;

      print("uid: ${widget.uid}");
      print("pid: $pid");
    } catch (e) {
      print("Error loading provider data: $e");

      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> loadUserData() async {
    try {
      final result = await db.collection('users').doc(widget.uid).get();

      if (result.exists) {
        final data = result.data();

        setState(() {
          statusAccount = data?['status_account'] ?? 0;
        });

        print("status_account: $statusAccount");
      } else {
        print("ไม่พบข้อมูล user: ${widget.uid}");

        setState(() {
          statusAccount = null;
        });
      }
    } catch (e) {
      print("Error loading user data: $e");

      setState(() {
        statusAccount = null;
      });
    }
  }

  Future<void> loadDocumentData() async {
    try {
      final result = await db
          .collection('document')
          .where('pid', isEqualTo: pid)
          .limit(1)
          .get();

      if (result.docs.isEmpty) {
        return;
      }

      final data = result.docs.first.data();

      setState(() {
        statusDoc = data['status_doc'] ?? 0;
        rejectReason = data['reject_reason'];
      });

      print('status_doc: $statusDoc');
      print('reject_reason: $rejectReason');
    } catch (e) {
      print('Error loading document: $e');
    }
  }

  void showAllJobs() {
    setState(() {
      selectedHour = null;
      filteredJobs = allJobs;
    });
  }

  void filterJobsByStartHour(int selectedHour) {
    setState(() {
      filteredJobs = allJobs.where((job) {
        final startTime = job['start_time'];

        if (startTime == null) {
          return false;
        }

        final timeParts = startTime.toString().split(':');

        if (timeParts.isEmpty) {
          return false;
        }

        final hour = int.tryParse(timeParts[0]);

        return hour == selectedHour;
      }).toList();
    });
  }
}
