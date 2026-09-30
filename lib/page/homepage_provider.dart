import 'dart:developer';

import 'package:caremate_application/page/details_job.dart';
import 'package:caremate_application/page/myJob_povider.dart';
import 'package:caremate_application/page/notification_system.dart';
import 'package:caremate_application/page/notifications_page.dart';
import 'package:caremate_application/page/settings_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
  bool isLoading = true;

  int _selectedIndex = 0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // ตั้งค่า Firebase Messaging
    NotificationSystem().setupNotification(widget.uid);
    loadProviderData();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      Container(),
      MyjobPovider(pid: pid),
      NotificationsPage(),
      SettingsPage(),
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
          ? isLoading
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

                      return Container(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (index == 0) SizedBox(height: 40),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 30),
                              child: Center(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    print('job_id: ${job['job_id']}');
                                    print('pid: ${pid}');
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DetailsJob(
                                          jobId: job['job_id'],
                                          pid: pid,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    height: 160,
                                    width: 380,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(16),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.9),
                                          blurRadius: 5,
                                          spreadRadius: 1,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        left: 30,
                                        top: 5,
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

        // print('Firestore doc.id = ${doc.id}');
        // print('fullData = $fullData');

        tempList.add(fullData);
      }

      allJobs = tempList;

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

      await queryJobData();
    } catch (e) {
      print("Error loading provider data: $e");

      setState(() {
        isLoading = false;
      });
    }
  }
}
