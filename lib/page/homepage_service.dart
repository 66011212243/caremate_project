import 'package:caremate_application/page/calendar_service_page.dart';
import 'package:caremate_application/page/create_job.dart';
import 'package:caremate_application/page/details_job_service.dart';
import 'package:caremate_application/page/notification_system.dart';
import 'package:caremate_application/page/notifications_page.dart';
import 'package:caremate_application/page/search_location_page.dart';
import 'package:caremate_application/page/settings_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HomepageService extends StatefulWidget {
  final String uid;

  const HomepageService({super.key, required this.uid});

  @override
  State<HomepageService> createState() => _HomepageServiceState();
}

class _HomepageServiceState extends State<HomepageService> {
  var db = FirebaseFirestore.instance;
  String sid = "";
  List<Map<String, dynamic>> serviceJobs = [];
  bool isLoading = true;

  int _selectedIndex = 0;
  bool isServiceDataComplete = false;

  @override
  void initState() {
    super.initState();
    NotificationSystem().setupNotification(widget.uid);
    loadServiceData();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      Container(),
      CalendarServicePage(sid: sid),
      NotificationsPage(uid: widget.uid),
      SettingsService(sid: sid),
    ];
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 248, 249, 250),
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0
              ? "หน้าหลัก"
              : _selectedIndex == 1
              ? "ปฏิทินงาน"
              : _selectedIndex == 2
              ? "ข้อความ"
              : "ตั้งค่า",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 255, 0, 0),
        toolbarHeight: 70,
        automaticallyImplyLeading: false,
      ),
      body: _selectedIndex == 0
          ? isLoading
                ? const Center(child: CircularProgressIndicator())
                : serviceJobs.isEmpty
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
                      padding: const EdgeInsets.only(bottom: 30),
                      itemCount: serviceJobs.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return const Padding(
                            padding: EdgeInsets.only(
                              top: 20,
                              left: 20,
                              right: 20,
                              bottom: 15,
                            ),
                            child: Text(
                              "งานของฉัน",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }
                        var job = serviceJobs[index - 1];
                        final int status = job['job_status'] ?? 0;
                        final statusInfo = getJobStatusInfo(status);
                        final Color statusColor = statusInfo['color'];

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () async {
                                  final selectedJobId = job['job_id'];

                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DetailsJobService(
                                        jobId: selectedJobId,
                                      ),
                                    ),
                                  );

                                  if (result == true) {
                                    setState(() {
                                      serviceJobs.removeWhere(
                                        (item) =>
                                            item['job_id'] == selectedJobId,
                                      );
                                    });
                                  } else if (result == 'edited') {
                                    await queryJobData();
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // --- Header: ชื่อสถานที่ + Status Badge (อยู่ภายในกรอบ) ---
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
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
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: statusColor.withOpacity(
                                                0.12,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  statusInfo['icon'],
                                                  size: 14,
                                                  color: statusColor,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  statusInfo['title'],
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: statusColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),

                                      const Divider(height: 20, thickness: 0.8),

                                      // --- Body: วันที่ และ เวลา ---
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

                                      const SizedBox(height: 10),

                                      // --- Footer: รถ และ ราคาสุทธิ ---
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
                                            job['vehicle_type'] == 1
                                                ? "Car"
                                                : "Bike",
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 10),

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
                                              fontWeight: FontWeight.bold,
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
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  )
          : pages[_selectedIndex],
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                if (sid.isEmpty) {
                  print('ยังไม่มี sid');
                  return;
                }

                if (!isServiceDataComplete) {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text(
                          'กรุณากรอกข้อมูลให้ครบ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        content: const Text(
                          'ก่อนสร้างงาน กรุณากรอกข้อมูลต่อไปนี้ให้ครบถ้วน\n\n'
                          '• เบอร์โทรศัพท์\n'
                          '• เพศ\n'
                          '• ที่อยู่หลักสำหรับรับบริการ\n\n'
                          'เมื่อกรอกข้อมูลครบแล้ว จึงจะสามารถสร้างงานได้',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('ตกลง'),
                          ),
                        ],
                      );
                    },
                  );

                  return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateJob(sid: sid, uid: widget.uid),
                  ),
                );
              },
              backgroundColor: const Color.fromARGB(255, 255, 0, 0),
              shape: const CircleBorder(),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color.fromARGB(255, 255, 0, 0),
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "หน้าหลัก"),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: "ปฏิทิน",
          ),
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
          .where('service_id', isEqualTo: sid)
          .where('job_status', whereNotIn: [9, 10])
          .get();

      serviceJobs = querySnapshot.docs.map((doc) {
        return {...doc.data(), 'job_id': doc.id};
      }).toList();

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

  Future<void> loadServiceData() async {
    try {
      final result = await db
          .collection('service')
          .where('service_uid', isEqualTo: widget.uid)
          .limit(1)
          .get();

      if (result.docs.isEmpty) {
        print("ไม่พบข้อมูล service ของ uid: ${widget.uid}");

        setState(() {
          isServiceDataComplete = false;
          isLoading = false;
        });

        return;
      }

      final serviceDoc = result.docs.first;
      sid = serviceDoc.id;
      final data = serviceDoc.data();

      final isServiceComplete =
          data['phone'] != null &&
          data['phone'].toString().trim().isNotEmpty &&
          data['gender'] != null;

      final address = await db
          .collection('address')
          .where('service_id', isEqualTo: sid)
          .where('main_ad_status', isEqualTo: 1)
          .limit(1)
          .get();

      final isAddressComplete = address.docs.isNotEmpty;

      setState(() {
        isServiceDataComplete = isServiceComplete && isAddressComplete;
      });

      await queryJobData();
    } catch (e) {
      print("Error loading service data: $e");

      setState(() {
        isServiceDataComplete = false;
        isLoading = false;
      });
    }
  }

  // =========================================================
  // ฟังก์ชันจับคู่ข้อความ สี และไอคอนตามสถานะงาน (0-9)
  // =========================================================
  Map<String, dynamic> getJobStatusInfo(int status) {
    switch (status) {
      case 0:
        return {
          'title': 'รอผู้สมัคร',
          'color': Colors.amber.shade800,
          'icon': Icons.hourglass_empty_rounded, // นาฬิกาทราย = รอผู้สมัคร
        };
      case 1:
        return {
          'title': 'ได้ผู้ให้บริการแล้ว',
          'color': Colors.blue.shade700,
          'icon': Icons.person_add_alt_1_rounded, // ได้ผู้ให้บริการ
        };
      case 2:
        return {
          'title': 'ได้ผู้ให้บริการแล้ว',
          'color': Colors.indigo.shade600,
          'icon': Icons.assignment_ind_rounded, // แสดงสถานะผู้ให้บริการ
        };
      case 3:
        return {
          'title': 'กำลังเดินทาง',
          'color': Colors.lightBlue.shade800,
          'icon': Icons.directions_car_rounded, // รถยนต์ = เดินทาง
        };
      case 4:
        return {
          'title': 'ถึงผู้รับบริการ',
          'color': Colors.teal.shade700,
          'icon': Icons.medical_services_rounded, // บริการ/ดูแลผู้รับบริการ
        };
      case 5:
        return {
          'title': 'ถึงปลายทาง',
          'color': Colors.cyan.shade800,
          'icon': Icons.where_to_vote_rounded, // หมุดปลายทาง
        };
      case 6:
        return {
          'title': 'กำลังให้บริการ',
          'color': Colors.orange.shade800,
          'icon': Icons.miscellaneous_services_rounded, // กำลังให้บริการ
        };
      case 7:
        return {
          'title': 'กำลังเดินทาง',
          'color': Colors.lightGreen.shade800,
          'icon': Icons.navigation_rounded, // นำทาง/เดินทาง
        };
      case 8:
        return {
          'title': 'ถึงจุดรับงาน',
          'color': Colors.purple.shade700,
          'icon': Icons.location_on_rounded, // หมุดจุดรับงาน
        };
      case 9:
        return {
          'title': 'สำเร็จ',
          'color': Colors.green.shade700,
          'icon': Icons.check_circle_rounded, // สำเร็จ
        };
      default:
        return {
          'title': 'ไม่ทราบสถานะ',
          'color': Colors.grey.shade600,
          'icon': Icons.help_outline_rounded,
        };
    }
  }
}
