import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.red,
        title: const Text('การตั้งค่า', style: TextStyle(color: Colors.white)),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3, // ตอนนี้อยู่หน้า "ตั้งค่า"
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
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'ตั้งค่า'),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const CircleAvatar(radius: 28, child: Icon(Icons.person)),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('ขยัน คงรวย')),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'โปรไฟล์',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            //const Text('ทั่วไป', style: TextStyle(color: Colors.black)),
            const SizedBox(height: 20),
            buildMenu('ประวัติงาน'),

            const Divider(
              color: Colors.grey,
              thickness: 1, // ความหนา
              height: 30,
            ),
            buildMenu('ประวัติรีวิว'),
            const Divider(
              color: Colors.grey,
              thickness: 1, // ความหนา
              height: 30,
            ),
            buildMenu('เปลี่ยนรหัสผ่าน'),
            const Divider(
              color: Colors.grey,
              thickness: 1, // ความหนา
              height: 30,
            ),
            buildMenu('วิธีการใช้งาน'),
            const Divider(
              color: Colors.grey,
              thickness: 1, // ความหนา
              height: 30,
            ),
            buildMenu('สมัครเป็นผู้ให้บริการ'),
            const Divider(
              color: Colors.grey,
              thickness: 1, // ความหนา
              height: 30,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {},
                child: const Text(
                  'ออกจากระบบ',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildMenu(String title) {
    return ListTile(
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
