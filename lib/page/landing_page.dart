
import 'package:caremate_application/page/login.dart';
import 'package:flutter/material.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ส่วน Header สีแดงพร้อมความเว้าล่าง
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // ตัดขอบสีแดงให้โค้งเว้าเข้าด้านล่าง
                ClipPath(
                  clipper: CurvedHeaderClipper(
                    curveHeight: 55,
                  ),
                  child: Container(
                    width: double.infinity,
                    height: 230,
                    color: Colors.red,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Image.asset(
                          'assets/images/caremateV2.png',
                          width: 250,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Text(
                            'Caremate',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ปุ่มเข้าสู่ระบบแบบลอย
                Positioned(
                  bottom: -25,
                  child: SizedBox(
                    width: 280,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 4,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
                        );
                      },
                      child: const Text(
                        'เข้าสู่ระบบ',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 50),

            // Section 1: สิทธิประโยชน์ผู้รับบริการ
            _buildBenefitSection(
              title: 'สิทธิประโยชน์ผู้รับบริการ',
              items: [
                _BenefitItem(
                  iconPath: 'assets/images/car.png',
                  label: 'เรียกผู้ดูแลพร้อมรถรับ-ส่ง',
                ),
                _BenefitItem(
                  iconPath: 'assets/images/care.png',
                  label: 'มีผู้ช่วยดูแลระหว่างเดินทาง',
                ),
                _BenefitItem(
                  iconPath: 'assets/images/map.png',
                  label: 'ติดตามการเดินทางแบบเรียลไทม์',
                ),
              ],
              onStartTap: () {
                // Action เมื่อกด "เริ่มต้นใช้งาน" ฝั่งผู้รับบริการ
              },
            ),

            const SizedBox(height: 30),

            // Section 2: สิทธิประโยชน์ผู้ให้บริการ
            _buildBenefitSection(
              title: 'สิทธิประโยชน์ผู้ให้บริการ',
              items: [
                _BenefitItem(
                  iconPath: 'assets/images/calendar.png',
                  label: 'จัดการเวลาทำงานได้ด้วยตัวเอง',
                ),
                _BenefitItem(
                  iconPath: 'assets/images/payment.png',
                  label: 'ได้รับค่าตอบแทนชัดเจนและโปร่งใส',
                ),
                _BenefitItem(
                  iconPath: 'assets/images/car.png',
                  label: 'ไม่จำเป็นต้องมีตารางประจำเหมาะกับอาชีพอิสระ',
                ),
              ],
              onStartTap: () {
                // Action เมื่อกด "เริ่มต้นใช้งาน" ฝั่งผู้ให้บริการ
              },
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Widget สร้างโซนสิทธิประโยชน์
  Widget _buildBenefitSection({
    required String title,
    required List<_BenefitItem> items,
    required VoidCallback onStartTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items.map((item) {
              return Expanded(
                child: Column(
                  children: [
                    // ปรับขนาดไอคอนตรงนี้
                    Image.asset(
                      item.iconPath,
                      width: 70,
                      height: 70,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(
                        Icons.image,
                        size: 50,
                        color: Colors.red,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      item.label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 15),

          GestureDetector(
            onTap: onStartTap,
            child: const Text(
              'เริ่มต้นใช้งาน',
              style: TextStyle(
                fontSize: 14,
                color: Colors.red,
                decoration: TextDecoration.underline,
                decorationColor: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// CustomClipper สร้างส่วนโค้งเว้าเข้าด้านล่าง
class CurvedHeaderClipper extends CustomClipper<Path> {
  final double curveHeight;

  CurvedHeaderClipper({this.curveHeight = 25});

  @override
  Path getClip(Size size) {
    Path path = Path();

    path.lineTo(0, size.height);

    var controlPoint = Offset(
      size.width / 2,
      size.height - (curveHeight * 2),
    );

    var endPoint = Offset(
      size.width,
      size.height,
    );

    path.quadraticBezierTo(
      controlPoint.dx,
      controlPoint.dy,
      endPoint.dx,
      endPoint.dy,
    );

    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CurvedHeaderClipper oldClipper) {
    return oldClipper.curveHeight != curveHeight;
  }
}

class _BenefitItem {
  final String iconPath;
  final String label;

  _BenefitItem({
    required this.iconPath,
    required this.label,
  });
}
