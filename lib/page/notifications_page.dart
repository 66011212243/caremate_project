import 'package:flutter/material.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  // ข้อมูลแจ้งเตือน
  final List<Map<String, String>> notifications = [
    {
      'title': 'คนขับกำลังเดินทางมาหาคุณ',
      'subtitle': 'คนขับ: พิชยาภรณ์ ยามรัมย์\nทะเบียน: กบ 1234',
      'date': 'วันที่ 8 สิงหาคม 2568',
    },
    {
      'title': 'คุณได้คนขับแล้ว !',
      'subtitle': 'วันที่ 8 / 8 / 2568\nโรงพยาบาลสุราษ',
      'date': 'วันที่ 5 สิงหาคม 2568',
    },
    {
      'title': 'คุณได้คนขับแล้ว !',
      'subtitle': 'วันที่ 8 / 8 / 2568\nโรงพยาบาลสุราษ',
      'date': 'วันที่ 6 สิงหาคม 2568',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,

        title: const Row(
          children: [
            Icon(Icons.notifications_outlined, color: Colors.black, size: 28),
            SizedBox(width: 10),
            Text(
              'การแจ้งเตือน',
              style: TextStyle(
                color: Colors.black,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),

      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 70,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'ยังไม่มีการแจ้งเตือน',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),

                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ไอคอนแจ้งเตือน
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications,
                          color: Colors.red,
                          size: 24,
                        ),
                      ),

                      const SizedBox(width: 14),

                      // เนื้อหาแจ้งเตือน
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notification['title'] ?? '',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 7),

                            Text(
                              notification['subtitle'] ?? '',
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: Colors.grey.shade700,
                              ),
                            ),

                            const SizedBox(height: 10),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 15,
                                  color: Colors.grey.shade500,
                                ),

                                const SizedBox(width: 5),

                                Expanded(
                                  child: Text(
                                    notification['date'] ?? '',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
