import 'package:flutter/material.dart';

class MyjobPovider extends StatefulWidget {
  const MyjobPovider({super.key});

  @override
  State<MyjobPovider> createState() => _MyjobPoviderState();
}

class _MyjobPoviderState extends State<MyjobPovider> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Text(
            "งานของฉัน",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: Color.fromARGB(255, 255, 0, 0),
        toolbarHeight: 90,
        automaticallyImplyLeading: false,
      ),
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
                  Container(
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
                                      "โรงพยาบาลสุทธาเวช",
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
                                          "12 / 8 / 68",
                                          style: TextStyle(fontSize: 16),
                                        ),

                                        SizedBox(width: 40),

                                        Icon(Icons.access_time),
                                        SizedBox(width: 5),
                                        Text(
                                          "09:00 น.",
                                          style: TextStyle(fontSize: 16),
                                        ),
                                        Text(
                                          " - ",
                                          style: TextStyle(fontSize: 16),
                                        ),
                                        Text(
                                          "17:00 น.",
                                          style: TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Icon(Icons.motorcycle),
                                        SizedBox(width: 5),
                                        Text(
                                          "Bike",
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
                                          " 500บาท",
                                          style: TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 15),
                                    TextButton(
                                      style: TextButton.styleFrom(
                                        backgroundColor: Color.fromARGB(
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
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      onPressed: () {},
                                      child: Text(
                                        "ได้งานนี้",
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
                  ),

                  //tap 2
                  Center(child: Text("ปฏิทิน")),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
