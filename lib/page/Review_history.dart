import 'package:flutter/material.dart';

class ReviewhistoryPage extends StatelessWidget {
  const ReviewhistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        leading: const Icon(Icons.arrow_back, color: Colors.black),
        title: const Text(
          'ประวัติรีวิว',
           style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "นายขยัน มากมาย ",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: const [
                      SizedBox(width: 5),
                      Text(
                        "5",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(Icons.star, color: Colors.amber),
                    ],
                  ),
                  const Text("ขับรถดีมาก ดูแลระหว่างการรักษาก็ดี มีประสบการณ์"),
                ],
              ),
              const Divider(
                color: Colors.grey,
                thickness: 2, // ความหนา
                height: 30,
              ),

               Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "นายขยัน มากมาย ",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: const [
                      SizedBox(width: 5),
                      Text(
                        "5",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(Icons.star, color: Colors.amber),
                    ],
                  ),
                  const Text("ขับรถดีมาก ดูแลระหว่างการรักษาก็ดี มีประสบการณ์"),
                ],
              ),
              const Divider(
                color: Colors.grey,
                thickness: 2, // ความหนา
                height: 30,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
