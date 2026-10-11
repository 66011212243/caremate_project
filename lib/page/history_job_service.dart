import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryJobService extends StatefulWidget {
  final String sid;
  const HistoryJobService({super.key, required this.sid});

  @override
  State<HistoryJobService> createState() => _HistoryJobServiceState();
}

class _HistoryJobServiceState extends State<HistoryJobService> {
  // ฟังก์ชันสำหรับเลือก Icon ตามรหัสประเภทรถ (0 = มอเตอร์ไซค์, 1 = รถยนต์)
  int? jobStatus;
  IconData _getVehicleIcon(dynamic vehicleType) {
    final type = vehicleType?.toString();
    if (type == '1') {
      return Icons.directions_car;
    } else {
      return Icons.motorcycle;
    }
  }

  // ฟังก์ชันสำหรับข้อความชื่อประเภทรถ
  String _getVehicleName(dynamic vehicleType) {
    final type = vehicleType?.toString();
    if (type == '1') {
      return 'รถยนต์';
    } else if (type == '0') {
      return 'มอเตอร์ไซค์';
    }
    return 'ไม่ระบุ';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        title: Row(
          children: [
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
              label: const Text(''),
            ),
            const Text(
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

      // ดึงตรงจาก jobs เทเบิลเดียวโดยใช้ sid และ job_status == 9
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('jobs')
            .where(
              'service_id',
              isEqualTo: widget.sid,
            ) // หรือใช้ 'provider_id' ให้ตรงกับ Firestore ของคุณ
            .where('job_status', whereIn: [9, 10]) // กรองเฉพาะงานที่เสร็จแล้ว
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('ไม่พบประวัติการทำงาน'));
          }

          final jobDocs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: jobDocs.length,
            itemBuilder: (context, index) {
              final jobData = jobDocs[index].data() as Map<String, dynamic>;

              // ดึงและแปลงประเภทข้อมูลให้อยู่ในรูปแบบ String เพื่อป้องกัน Error
              final hospitalName =
                  jobData['place_name']?.toString() ?? 'ไม่ระบุ';
              final date = jobData['date']?.toString() ?? '-';
              final timeStart = jobData['start_time']?.toString() ?? '-';
              final timeEnd = jobData['end_time']?.toString() ?? '-';
              final price = jobData['service_fee']?.toString() ?? '0';
              final int? jobStatus = (jobData['job_status'] as num?)?.toInt();

              final rawVehicleType = jobData['vehicle_type'];
              final vehicleIcon = _getVehicleIcon(rawVehicleType);
              final vehicleName = _getVehicleName(rawVehicleType);

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Center(
                  child: Container(
                    width: 380,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.all(Radius.circular(16)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          blurRadius: 5,
                          spreadRadius: 1,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hospitalName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.calendar_month, size: 20),
                            const SizedBox(width: 5),
                            Text(date, style: const TextStyle(fontSize: 15)),
                            const SizedBox(width: 20),
                            const Icon(Icons.access_time, size: 20),
                            const SizedBox(width: 5),
                            Text(
                              '$timeStart - $timeEnd',
                              style: const TextStyle(fontSize: 15),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(vehicleIcon, size: 20),
                            const SizedBox(width: 5),
                            Text(
                              vehicleName,
                              style: const TextStyle(fontSize: 15),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.money, size: 20),
                            const SizedBox(width: 5),
                            Text(
                              '$price บาท',
                              style: const TextStyle(fontSize: 15),
                            ),
                          ],
                        ),
                        if (jobStatus == 9 || jobStatus == 10)
                          Row(
                            children: [
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: jobStatus == 9
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      jobStatus == 9
                                          ? Icons.check_circle
                                          : Icons.cancel_outlined,
                                      size: 16,
                                      color: jobStatus == 9
                                          ? Colors.green
                                          : Colors.orange.shade700,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      jobStatus == 9 ? "สำเร็จ" : "ยกเลิก",
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: jobStatus == 9
                                            ? Colors.green
                                            : Colors.orange.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
