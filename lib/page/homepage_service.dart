import 'package:caremate_application/page/calendar_service_page.dart';
import 'package:caremate_application/page/create_job.dart';
import 'package:caremate_application/page/details_job_service.dart';
import 'package:caremate_application/page/notification_system.dart';
import 'package:caremate_application/page/search_location_page.dart';
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

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    NotificationSystem().setupNotification(widget.uid);
    loadServiceData();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      Container(),
      CalendarServicePage(sid: sid),
      //MyjobPovider(pid: widget.pid),
      // NotificationsPage(),
      // SettingsPage(),
    ];
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        title: _selectedIndex == 0
            ? GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SearchLocationPage(),
                    ),
                  );
                },
                child: Container(
                  width: 380,
                  height: 50,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(width: 12),

                      Icon(Icons.search, color: Colors.white),

                      SizedBox(width: 10),

                      Text(
                        "ไปที่ไหน ?",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              )
            : Text(
                _selectedIndex == 1
                    ? "ปฏิทินงาน"
                    : _selectedIndex == 2
                    ? "ข้อความ"
                    : "ตั้งค่า",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),

        backgroundColor: Color.fromARGB(255, 255, 0, 0),
        toolbarHeight: 90,
        automaticallyImplyLeading: false,
      ),
      body: _selectedIndex == 0
          ? isLoading
                ? Center(child: CircularProgressIndicator())
                : serviceJobs.isEmpty
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
                    itemCount: serviceJobs.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(
                            top: 30,
                            left: 30,
                            bottom: 20,
                          ),
                          child: Text(
                            "งานของฉัน",
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }
                      var job = serviceJobs[index - 1];
                      return Container(
                        color: Color.fromARGB(255, 255, 255, 255),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: Center(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () async {
                                    print('job_id: ${job['job_id']}');
                                    print('sid: ${sid}');

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
                                      // แก้ไขงาน
                                      await queryJobData();
                                    }
                                  },
                                  child: Container(
                                    height: 170,
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
                                        top: 15,
                                        left: 30,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            job['place_name'],
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 10),
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
                                          Row(
                                            children: [
                                              Icon(
                                                job['vehicle_type'] == 0
                                                    ? Icons.motorcycle
                                                    : Icons.time_to_leave,
                                              ),
                                              SizedBox(width: 5),
                                              Text(
                                                job['vehicle_type'] == 1
                                                    ? "Car"
                                                    : "Bike",
                                                style: TextStyle(fontSize: 16),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 10),
                                          Row(
                                            children: [
                                              Icon(Icons.money),
                                              SizedBox(width: 5),
                                              Text(
                                                " ${job['service_fee']} บาท",
                                                style: TextStyle(fontSize: 16),
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
                          ],
                        ),
                      );
                    },
                  )
          : pages[_selectedIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (sid.isEmpty) {
            print('ยังไม่มี sid');
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateJob(sid: sid, uid: widget.uid),
            ),
          );
        },
        backgroundColor: Color.fromARGB(255, 255, 0, 0),
        shape: CircleBorder(),
        child: Icon(Icons.add, color: Colors.white),
      ),

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color.fromARGB(255, 255, 0, 0),
        currentIndex: _selectedIndex,

        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },

        items: [
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
          .get();

      serviceJobs = querySnapshot.docs.map((doc) {
        //print("job_id: ${doc.id}");
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
          isLoading = false;
        });

        return;
      }

      final serviceDoc = result.docs.first;

      // นี่คือ sid
      sid = serviceDoc.id;

      print("uid: ${widget.uid}");
      print("sid: $sid");

      // โหลดงานของ service คนนี้
      await queryJobData();
    } catch (e) {
      print("Error loading service data: $e");

      setState(() {
        isLoading = false;
      });
    }
  }
}
