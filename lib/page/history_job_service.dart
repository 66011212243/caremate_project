import 'package:flutter/material.dart';

class HistoryJobService extends StatefulWidget {
  const HistoryJobService({super.key});

  @override
  State<HistoryJobService> createState() => _HistoryJobServiceState();
}

class _HistoryJobServiceState extends State<HistoryJobService> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        title: Row(
          children: [
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              label: Icon(Icons.arrow_back_ios, color: Colors.black),
            ),
            Text(
              "ประวัติงาน",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        toolbarHeight: 70,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Center(
            child: Container(
              height: 160,
              width: 380,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.all(Radius.circular(16)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.9),
                    blurRadius: 5,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 30, top: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'โรงพยาบาลจุฬาลงกรณ์',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        const Icon(Icons.calendar_month),
                        const SizedBox(width: 5),
                        const Text(
                          '25/09/2026',
                          style: TextStyle(fontSize: 16),
                        ),

                        const SizedBox(width: 40),

                        const Icon(Icons.access_time),
                        const SizedBox(width: 5),
                        const Text('08:00', style: TextStyle(fontSize: 16)),
                        const Text(' - ', style: TextStyle(fontSize: 16)),
                        const Text('12:00', style: TextStyle(fontSize: 16)),
                      ],
                    ),

                    const SizedBox(height: 10),

                    const Row(
                      children: [
                        Icon(Icons.motorcycle),
                        SizedBox(width: 5),
                        Text('Bike', style: TextStyle(fontSize: 16)),
                      ],
                    ),

                    const SizedBox(height: 10),

                    const Row(
                      children: [
                        Icon(Icons.money),
                        SizedBox(width: 5),
                        Text('500 บาท', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
