import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HomepageProvider extends StatefulWidget {
  String pid = '';
  HomepageProvider({super.key, required this.pid});

  @override
  State<HomepageProvider> createState() => _HomepageProviderState();
}

class _HomepageProviderState extends State<HomepageProvider> {
  var db = FirebaseFirestore.instance;
  List<Map<String, dynamic>> allJobs = [];
  bool isLoading = true;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    queryJobData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Text(
            "ประกาศจ้าง",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: Color.fromARGB(255, 255, 0, 0),
        toolbarHeight: 90,
        automaticallyImplyLeading: false,
      ),

      body: isLoading
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
                      SizedBox(height: 40),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 30),
                        child: Center(
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
                              padding: const EdgeInsets.only(left: 30),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                  SizedBox(height: 15),
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      backgroundColor: Color.fromARGB(
                                        255,
                                        255,
                                        0,
                                        0,
                                      ),
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () {},
                                    child: Text(
                                      "สมัคร",
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ],
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

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color.fromARGB(255, 255, 0, 0),
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

      allJobs = querySnapshot.docs.map((doc) => doc.data()).toList();

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
}
