import 'package:flutter/material.dart';

class AdminPricePage extends StatefulWidget {
  const AdminPricePage({super.key});

  @override
  State<AdminPricePage> createState() => _AdminPricePageState();
}

class _AdminPricePageState extends State<AdminPricePage> {

  double hourlyPrice = 60;
  double distancePrice = 10;


  final TextEditingController hourlyController =
      TextEditingController(text: '60');

  final TextEditingController distanceController =
      TextEditingController(text: '10');

  @override
  void dispose() {
    hourlyController.dispose();
    distanceController.dispose();
    super.dispose();
  }


  void savePrice() {
    final double? newHourlyPrice =
        double.tryParse(hourlyController.text.trim());

    final double? newDistancePrice =
        double.tryParse(distanceController.text.trim());

    if (newHourlyPrice == null || newHourlyPrice <= 0) {
      showMessage('กรุณากรอกค่าบริการรายชั่วโมงให้ถูกต้อง');
      return;
    }

    if (newDistancePrice == null || newDistancePrice <= 0) {
      showMessage('กรุณากรอกค่าบริการตามระยะทางให้ถูกต้อง');
      return;
    }

    setState(() {
      hourlyPrice = newHourlyPrice;
      distancePrice = newDistancePrice;
    });

    showMessage('บันทึกอัตราค่าบริการเรียบร้อยแล้ว');
  }

  void cancelEdit() {
    setState(() {
      hourlyController.text = hourlyPrice.toStringAsFixed(0);
      distanceController.text = distancePrice.toStringAsFixed(0);
    });
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {


    // 3 ชั่วโมง
    const double exampleHours = 3;

    // 10 กิโลเมตร
    const double exampleDistance = 10;

    final double hourlyTotal =
        hourlyPrice * exampleHours;

    final double distanceTotal =
        distancePrice * exampleDistance;

    return Scaffold(
      backgroundColor: Colors.white,

      // =========================
      // APP BAR
      // =========================
      appBar: AppBar(
        backgroundColor: Colors.red,
        toolbarHeight: 80,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          'จัดการอัตราค่าบริการ',
          style: TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              'อัตราค่าบริการรายชั่วโมง',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),

              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(15),
              ),

              child: Row(
                children: [

                  const Icon(
                    Icons.access_time,
                    color: Colors.red,
                    size: 38,
                  ),

                  const SizedBox(width: 15),

                  const Expanded(
                    child: Text(
                      'ราคาปัจจุบัน\nต่อชั่วโมง',
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ),

                  Text(
                    '${hourlyPrice.toStringAsFixed(0)} บาท',
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            const Text(
              'แก้ไขอัตราค่าบริการรายชั่วโมง',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: hourlyController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                prefixIcon: const Icon(
                  Icons.monetization_on_outlined,
                  color: Colors.grey,
                ),
                suffixText: 'บาท/ชั่วโมง',
                hintText: 'กรอกราคา',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Colors.red,
                    width: 2,
                  ),
                ),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),

            const SizedBox(height: 35),

            const Text(
              'อัตราค่าบริการตามระยะทาง',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),

              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(15),
              ),

              child: Row(
                children: [

                  const Icon(
                    Icons.location_on_outlined,
                    color: Colors.red,
                    size: 38,
                  ),

                  const SizedBox(width: 15),

                  const Expanded(
                    child: Text(
                      'ราคาปัจจุบัน\nตามระยะทาง',
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ),

                  Text(
                    '${distancePrice.toStringAsFixed(0)} บาท',
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            const Text(
              'แก้ไขอัตราค่าบริการตามระยะทาง',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: distanceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                prefixIcon: const Icon(
                  Icons.monetization_on_outlined,
                  color: Colors.grey,
                ),
                suffixText: 'บาท/กิโลเมตร',
                hintText: 'กรอกราคา',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Colors.red,
                    width: 2,
                  ),
                ),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),

            const SizedBox(height: 35),

            Row(
              children: [

                // ยกเลิก
                Expanded(
                  child: OutlinedButton(
                    onPressed: cancelEdit,

                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(
                        double.infinity,
                        50,
                      ),
                      side: const BorderSide(
                        color: Colors.red,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),

                    child: const Text(
                      'ยกเลิก',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 15),

                // บันทึก
                Expanded(
                  child: ElevatedButton(
                    onPressed: savePrice,

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(
                        double.infinity,
                        50,
                      ),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),

                    child: const Text(
                      'บันทึกการแก้ไข',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}