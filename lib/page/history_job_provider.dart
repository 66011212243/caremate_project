import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryJobProvider extends StatefulWidget {
  final String pid;
  const HistoryJobProvider({super.key, required this.pid});

  @override
  State<HistoryJobProvider> createState() => _HistoryJobProviderState();
}

class _HistoryJobProviderState extends State<HistoryJobProvider> {
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
              "ประวัติการทำงาน",
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

      body: StreamBuilder<QuerySnapshot>(
        // 1. ดึงรายการงานจาก all_drivers ที่ตรงกับ provider_id
        stream: FirebaseFirestore.instance
            .collection('all_drivers')
            .where('provider_id', isEqualTo: widget.pid)
            .snapshots(),
        builder: (context, driverSnapshot) {
          if (driverSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (driverSnapshot.hasError) {
            return Center(
              child: Text('เกิดข้อผิดพลาด: ${driverSnapshot.error}'),
            );
          }

          if (!driverSnapshot.hasData || driverSnapshot.data!.docs.isEmpty) {
            return const Center(child: Text('ไม่พบประวัติการทำงาน'));
          }

          final driverDocs = driverSnapshot.data!.docs;

          // ดึงเฉพาะ job_id ออกมาจากเอกสารใน all_drivers (แปลงเป็น String ให้ปลอดภัย)
          final List<String> jobIds = driverDocs
              .map((doc) => doc['job_id']?.toString() ?? '')
              .where((id) => id.isNotEmpty)
              .toList();

          if (jobIds.isEmpty) {
            return const Center(child: Text('ไม่พบประวัติการทำงาน'));
          }

          // 2. นำ List ของ job_id ไปดึงข้อมูลจากคอลเลกชัน jobs
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('jobs')
                .where(FieldPath.documentId, whereIn: jobIds)
                .where(
                  'job_status',
                  isEqualTo: 9,
                ) // กรองเฉพาะงานที่เสร็จสิ้นแล้ว (job_status == 9)
                .snapshots(),
            builder: (context, jobSnapshot) {
              if (jobSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (jobSnapshot.hasError) {
                return Center(
                  child: Text('เกิดข้อผิดพลาด: ${jobSnapshot.error}'),
                );
              }

              if (!jobSnapshot.hasData || jobSnapshot.data!.docs.isEmpty) {
                return const Center(child: Text('ไม่มีงานที่เสร็จสิ้นแล้ว'));
              }

              final jobDocs = jobSnapshot.data!.docs;
              // ฟังก์ชันสำหรับเลือก Icon ตามรหัสประเภทรถ (0 = มอเตอร์ไซค์, 1 = รถยนต์)
              IconData _getVehicleIcon(dynamic vehicleType) {
                final type = vehicleType?.toString();
                if (type == '1') {
                  return Icons.directions_car; // ไอคอนรถยนต์
                } else {
                  return Icons
                      .motorcycle; // ไอคอนมอเตอร์ไซค์ (ค่าเริ่มต้น หรือเป็น 0)
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
                return 'ไม่ระบุ'; // หรือคืนค่าเป็น 'มอเตอร์ไซค์' ตามต้องการ
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 10),
                itemCount: jobDocs.length,
                itemBuilder: (context, index) {
                  final jobData = jobDocs[index].data() as Map<String, dynamic>;

                  // ✅ แก้ไข: แปลงทุกค่าให้อยู่ในรูปแบบ String ด้วย .toString() ป้องกัน type 'int' Error
                  final hospitalName =
                      jobData['place_name']?.toString() ?? 'ไม่ระบุ';
                  final date = jobData['date']?.toString() ?? '-';
                  final timeStart = jobData['start_time']?.toString() ?? '-';
                  final timeEnd = jobData['end_time']?.toString() ?? '-';
                  final vehicleType =
                      jobData['vehicle_type']?.toString() ?? 'Bike';
                  final price = jobData['service_fee']?.toString() ?? '0';

                  // ดึงค่า vehicle_type มาใช้
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
                          borderRadius: const BorderRadius.all(
                            Radius.circular(16),
                          ),
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
                                Text(
                                  date,
                                  style: const TextStyle(fontSize: 15),
                                ),
                                const SizedBox(width: 20),
                                const Icon(Icons.access_time, size: 20),
                                const SizedBox(width: 5),
                                // ✅ แก้ไขการแสดงผลเวลาให้อยู่ในบรรทัดเดียวกัน
                                Text(
                                  '$timeStart - $timeEnd',
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ],
                            ),

                            Row(
                              children: [
                                Icon(
                                  vehicleIcon,
                                  size: 20,
                                ), // ไอคอนเปลี่ยนตามรหัส (0 หรือ 1)
                                const SizedBox(width: 5),
                                Text(
                                  vehicleName,
                                  style: const TextStyle(fontSize: 15),
                                ), // ข้อความเปลี่ยนตามรหัส
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
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
