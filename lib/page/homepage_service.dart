import 'package:caremate_application/page/create_job.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HomepageService extends StatefulWidget {
  String sid = "";
  HomepageService({super.key, required this.sid});

  @override
  State<HomepageService> createState() => _HomepageServiceState();
}

class _HomepageServiceState extends State<HomepageService> {
  var db = FirebaseFirestore.instance;
  List<Map<String, dynamic>> serviceJobs = [];
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
        title: Container(
          width: 380,
          height: 50,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "ไปที่ไหน ?",
                    hintStyle: TextStyle(color: Colors.white),
                    prefixIcon: Icon(Icons.search, color: Colors.white),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white), // สีกรอบปกติ
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text("ค้นหา", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
        backgroundColor: Color.fromARGB(255, 255, 0, 0),
        toolbarHeight: 90,
        automaticallyImplyLeading: false,
      ),
      body: isLoading
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
                              padding: const EdgeInsets.only(top: 15, left: 30),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreateJob(sid: widget.sid)),
          );
        },
        backgroundColor: Color.fromARGB(255, 255, 0, 0),
        shape: CircleBorder(),
        child: Icon(Icons.add, color: Colors.white),
      ),

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color.fromARGB(255, 255, 0, 0),
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

  // void queryJobData() async {
  //   var querySnapshot = await db
  //       .collection('jobs')
  //       .where('service_id', isEqualTo: sid) // เงื่อนไขผู้ใช้
  //       .get();

  //   for (var doc in querySnapshot.docs) {
  //     print(doc.data()); // แสดงข้อมูลแต่ละงาน
  //   }
  // }

  Future<void> queryJobData() async {
    setState(() {
      isLoading = true;
    });
    try {
      var querySnapshot = await db
          .collection('jobs')
          .where('service_id', isEqualTo: widget.sid) 
          .get();
      serviceJobs = querySnapshot.docs.map((doc) => doc.data()).toList();
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
