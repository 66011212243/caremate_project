import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.red,
        title: const Text(
          'การแจ้งเตือน',
          style: TextStyle(color: Colors.white),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'หน้าหลัก',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            label: 'ปฏิทิน',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none),
            label: 'ข้อความ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'ตั้งค่า',
          ),
        ],
      ),
      body: ListView(
        children: const [
          NotificationCard(
            title: 'คนขับกำลังเดินทางมาหาคุณ',
            subtitle: 'คนขับ: พิชยาภรณ์ ยามรัมย์\nทะเบียน: กบ 1234',
            date: 'วันที่ 8 สิงหาคม 2568',
          ),
          NotificationCard(
            title: 'คุณได้คนขับแล้ว !',
            subtitle: 'วันที่ 8 / 8 / 2568\nโรงพยาบาลสุราษ',
            date: 'วันที่ 5 สิงหาคม 2568',
          ),
          NotificationCard(
            title: 'คุณได้คนขับแล้ว !',
            subtitle: 'วันที่ 8 / 8 / 2568\nโรงพยาบาลสุราษ',
            date: 'วันที่ 6 สิงหาคม 2568',
          ),
        ],
      ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String date;

  const NotificationCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(subtitle),
          const SizedBox(height: 10),
          Align(alignment: Alignment.bottomRight, child: Text(date)),
        ],
      ),
    );
  }
}
