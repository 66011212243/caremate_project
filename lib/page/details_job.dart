import 'package:flutter/material.dart';

class DetailsJob extends StatefulWidget {
  const DetailsJob({super.key});

  @override
  State<DetailsJob> createState() => _DetailsJobState();
}

class _DetailsJobState extends State<DetailsJob> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            TextButton.icon(
              onPressed: () {},
              label: Icon(Icons.arrow_back_ios, color: Colors.black),
            ),
            Text(
              "รายละเอียดงาน",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        toolbarHeight: 70,
        automaticallyImplyLeading: false,
      ),

      body: SingleChildScrollView(
        child: Container(
          child: Padding(
            padding: const EdgeInsets.only(top: 20, left: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 350,
                  // height: 70,
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "ที่อยู่หลัก :",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 255, 0, 0),
                          ),
                        ),
                        Text(
                          "บ้านเลขที่ 123/4 หมู่ 5 ตำบลบางรัก อำเภอเมือง จังหวัดกรุงเทพมหานคร",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      "สถานที่ :",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 20),
                    SizedBox(
                      width: 220,
                      child: Text("โรงพยาบาล", style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),

                GestureDetector(
                  // onTap: () async {
                  //   print("Container Clicked");
                  //   final result = await Navigator.push(
                  //     context,
                  //     MaterialPageRoute(builder: (context) => const MapPage()),
                  //   );

                  //   if (result != null) {
                  //     setState(() {
                  //       latitudeLocation = result['lat'];
                  //       longitudeLocation = result['lon'];
                  //     });

                  //     print("LatfromMap: $latitudeLocation");
                  //     print("LonfromMap: $longitudeLocation");
                  //   }
                  // },
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 30, top: 30),
                    child: Center(
                      child: Container(
                        height: 150,
                        width: 300,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              blurRadius: 3,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),

                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            "assets/images/map_preview.png",
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      "วันที่ :",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 10),
                    SizedBox(
                      width: 200,
                      child: Text("12/12/2023", style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
                SizedBox(height: 15),
                Row(
                  children: [
                    Text(
                      "เวลางาน :",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 10),
                    Text("จาก", style: TextStyle(fontSize: 14)),
                    SizedBox(width: 10),
                    SizedBox(
                      width: 70,
                      height: 30,
                      child: Text("08:00", style: TextStyle(fontSize: 16)),
                    ),
                    SizedBox(width: 10),
                    Text("ถึง", style: TextStyle(fontSize: 14)),
                    SizedBox(width: 10),
                    SizedBox(
                      width: 70,
                      height: 30,
                      child: Text("08:00", style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
                SizedBox(height: 15),
                Row(
                  children: [
                    Text(
                      "เรทค่าบริการ:",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 10),
                    SizedBox(
                      width: 120,
                      child: Text("1200", style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),

                SizedBox(height: 15),
                Row(
                  children: [
                    Text(
                      "ประเภทรถ:",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 10),
                    // Radio(
                    //   value: 1,
                    //   groupValue: vehicle,
                    //   onChanged: (value) {
                    //     setState(() {
                    //       vehicle = value;
                    //       log(vehicle.toString());
                    //     });
                    //   },
                    // ),
                    Text("Car", style: TextStyle(fontSize: 16)),

                    SizedBox(width: 10),

                    // Radio(
                    //   value: 0,
                    //   groupValue: vehicle,
                    //   onChanged: (value) {
                    //     setState(() {
                    //       vehicle = value;
                    //       log(vehicle.toString());
                    //     });
                    //   },
                    // ),
                    // Text("Bike", style: TextStyle(fontSize: 16)),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      "ลักษณะงาน:",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 10),
                    SizedBox(
                      width: 200,
                      child: Text(
                        "ดุแลผู้สูงอายุ",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 15),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Text(
                          "ข้อมูลพิเศษ:",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "(ไม่จำเป็น)",
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                    SizedBox(width: 10),
                    // Column(
                    //   children: [
                    //     Row(
                    //       children: [
                    //         Radio(
                    //           value: 0,
                    //           groupValue: additionalInfo,
                    //           onChanged: (value) {
                    //             setState(() {
                    //               additionalInfo = value;
                    //               extraPrice = 200;
                    //               updateTotalPrice();
                    //               print(additionalInfo);
                    //             });
                    //           },
                    //         ),
                    //         Text(
                    //           "ผู้ป่วยติดเตียง  (+200 บาท)",
                    //           style: TextStyle(fontSize: 16),
                    //         ),
                    //       ],
                    //     ),
                    //     Row(
                    //       children: [
                    //         Radio(
                    //           value: 1,
                    //           groupValue: additionalInfo,
                    //           onChanged: (value) {
                    //             setState(() {
                    //               additionalInfo = value;
                    //               extraPrice = 100;
                    //               updateTotalPrice();
                    //               print(additionalInfo);
                    //             });
                    //           },
                    //         ),
                    //         Text(
                    //           "ผู้ป่วยนั่งวิลแชร์  (+100 บาท)",
                    //           style: TextStyle(fontSize: 16),
                    //         ),
                    //       ],
                    //     ),
                    //   ],
                    // ),
                  ],
                ),
                SizedBox(height: 30),
                Center(
                  child: TextButton(
                    onPressed: () {
                      print("กดปุ่มสมัครงาน");
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Color.fromARGB(
                        255,
                        255,
                        0,
                        0,
                      ), // สีพื้นหลังปุ่ม
                      foregroundColor: Colors.white, // สีตัวอักษร
                      padding: EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12), // มุมมน
                      ),
                    ),
                    child: Text("สมัครงาน", style: TextStyle(fontSize: 18)),
                  ),
                ),
                SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
