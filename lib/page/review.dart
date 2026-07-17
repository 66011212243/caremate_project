import 'package:flutter/material.dart';

class ReviewPage extends StatelessWidget {
  const ReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        leading: const Icon(Icons.arrow_back, color: Colors.black),

        title: const Text(
          'รีวิว',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),

        backgroundColor: Colors.white,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// ปุ่มรายงาน
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      elevation: 3,
                    ),

                    onPressed: () {},

                    child: const Text("รายงาน"),
                  ),

                  const SizedBox(width: 10),

                  const Icon(Icons.more_vert),
                ],
              ),

              const SizedBox(height: 20),

              /// หัวข้อคนขับ
              const Text(
                "คนขับ",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              /// โปรไฟล์
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.grey.shade300,

                    child: const Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.brown,
                    ),
                  ),

                  const SizedBox(width: 20),

                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            "ชื่อ: ",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text("พิชยกรณ์ ยามรัมย์"),
                        ],
                      ),

                      SizedBox(height: 5),

                      Row(
                        children: [
                          Text(
                            "หมายเลขโทรศัพท์: ",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text("095588291"),
                        ],
                      ),

                      SizedBox(height: 5),

                      Row(
                        children: [
                          Text(
                            "ทะเบียนรถ: ",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text("กข1234"),
                        ],
                      ),

                      SizedBox(height: 5),

                      Row(
                        children: [
                          Text(
                            "เลขบัญชี: ",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text("1234567890"),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 40),

              /// ให้คะแนน
              const Text(
                "ให้คะแนน",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),

                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(15),
                ),

                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star_border, size: 35),
                    SizedBox(width: 10),

                    Icon(Icons.star_border, size: 35),
                    SizedBox(width: 10),

                    Icon(Icons.star_border, size: 35),
                    SizedBox(width: 10),

                    Icon(Icons.star_border, size: 35),
                    SizedBox(width: 10),

                    Icon(Icons.star_border, size: 35),
                  ],
                ),
              ),

              const SizedBox(height: 50),

              /// รายละเอียดเพิ่มเติม
              const Text(
                "รายละเอียดเพิ่มเติม",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 180,

                child: TextField(
                  maxLines: null,
                  expands: true,

                  decoration: InputDecoration(
                    hintText: 'รายละเอียด....',

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 50),

              /// ปุ่มรีวิว
              Center(
                child: SizedBox(
                  width: 120,

                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),

                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),

                    onPressed: () {},

                    child: const Text("รีวิว"),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}