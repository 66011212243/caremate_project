import 'package:flutter/material.dart';

class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: const Icon(Icons.arrow_back, color: Colors.black),
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'แก้ไขโปรไฟล์',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: const [
                  BoxShadow(blurRadius: 3, color: Colors.black12)
                ],
              ),
              child: Stack(
                children: [
                  const Center(
                    child: Icon(Icons.person, size: 90),
                  ),
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: Icon(Icons.edit_square, color: Colors.black),
                  )
                ],
              ),
            ),
            const SizedBox(height: 30),
            Card(
              color: const Color.fromARGB(255, 255, 253, 253), 
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: const [
                    ProfileRow(title: 'ชื่อ:', value: 'นัลลิกา นัลลิกา'),
                    Divider(),
                    ProfileRow(title: 'ชื่อผู้ใช้:', value: 'คุณยายมี'),
                    Divider(),
                    ProfileRow(title: 'เพศ:', value: 'หญิง'),
                    Divider(),
                    ProfileRow(title: 'โทรศัพท์:', value: '0619999999'),
                    Divider(),
                    ProfileRow(title: 'พิกัดที่อยู่ :', value: ''),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {},
              icon: const Icon(Icons.edit, color: Colors.white),
              label: const Text(
                'แก้ไขข้อมูล',
                style: TextStyle(color: Colors.white),
              ),
            )
          ],
        ),
      ),
    );
  }
  }

class ProfileRow extends StatelessWidget {
  final String title;
  final String value;

  const ProfileRow({
    super.key,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              title,
              style: const TextStyle(fontSize: 18),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          )
        ],
      ),
    );
  }
}