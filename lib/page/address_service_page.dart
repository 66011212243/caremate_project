import 'package:caremate_application/page/add_address_page.dart';
import 'package:caremate_application/page/edit_address_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddressServicePage extends StatefulWidget {
  String sid = '';
  AddressServicePage({super.key, required this.sid});

  @override
  State<AddressServicePage> createState() => _AddressServicePageState();
}

class _AddressServicePageState extends State<AddressServicePage> {
  var db = FirebaseFirestore.instance;
  List<Map<String, dynamic>> allAddress = [];
  bool isLoading = true;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    queryAddress();
  }

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
              "ที่อยู่ของฉัน",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        toolbarHeight: 70,
        automaticallyImplyLeading: false,
        backgroundColor: Color.fromARGB(255, 255, 255, 255),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : allAddress.isEmpty
          ? Column(
              children: [
                const Expanded(
                  child: Center(
                    child: Text(
                      "ยังไม่มีที่อยู่",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                ),

                // ปุ่มเพิ่มที่อยู่
                InkWell(
                  onTap: () {
                    print("เพิ่มที่อยู่");

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddAddressPage(sid: widget.sid),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          blurRadius: 5,
                          spreadRadius: 1,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          color: Colors.red,
                          size: 25,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "เพิ่มที่อยู่",
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: allAddress.length,
                    itemBuilder: (context, index) {
                      final fullData = allAddress[index];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (fullData['main_ad_status'] == 1)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Text(
                                        "ที่อยู่หลัก",
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),

                                  const Spacer(),

                                  TextButton(
                                    onPressed: () async {
                                      print("แก้ไข ${fullData['address_id']}");

                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => EditAddressPage(
                                            sid: widget.sid,
                                            addressId: fullData['address_id'],
                                          ),
                                        ),
                                      );

                                      // ถ้าแก้ไขสำเร็จ ให้โหลดข้อมูลใหม่
                                      if (result == true) {
                                        queryAddress();
                                      }
                                    },
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      "แก้ไข",
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),

                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Text(
                                      "|",
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),

                                  TextButton(
                                    onPressed: () {
                                      print("ลบ ${fullData['address_id']}");
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: Text("ยืนยันการลบที่อยู่"),
                                            content: Text(
                                              "คุณต้องการลบที่อยู่นี้ใช่หรือไม่?",
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                                child: Text(
                                                  "ยกเลิก",
                                                  style: TextStyle(
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ),

                                              TextButton(
                                                onPressed: () async {
                                                  await deleteAddress(
                                                    fullData['address_id'],
                                                  );

                                                  setState(() {
                                                    allAddress.removeWhere(
                                                      (address) =>
                                                          address['address_id'] ==
                                                          fullData['address_id'],
                                                    );
                                                  });
                                                  Navigator.of(context).pop();
                                                },
                                                child: Text(
                                                  "ยืนยัน",
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      "ลบ",
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              // =========================
                              // ข้อมูลที่อยู่
                              // =========================
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    color: Colors.red,
                                    size: 28,
                                  ),

                                  const SizedBox(width: 10),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          fullData['address_details'] ?? '-',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),

                                        const SizedBox(height: 5),

                                        Text(
                                          "อ.${fullData['district'] ?? '-'} "
                                          "จ.${fullData['province'] ?? '-'}",
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: Colors.grey.shade700,
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
                      );
                    },
                  ),
                ),

                // =========================
                // ปุ่มเพิ่มที่อยู่
                // =========================
                InkWell(
                  onTap: () {
                    print("เพิ่มที่อยู่");

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddAddressPage(sid: widget.sid),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          blurRadius: 5,
                          spreadRadius: 1,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          color: Colors.red,
                          size: 25,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "เพิ่มที่อยู่",
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> queryAddress() async {
    setState(() {
      isLoading = true;
    });
    try {
      var queryAddress = await db
          .collection('address')
          .where('service_id', isEqualTo: widget.sid)
          .get();

      List<Map<String, dynamic>> tempList = [];

      for (var doc in queryAddress.docs) {
        var data = doc.data();

        var fullData = {...data, 'address_id': doc.id};

        print('Firestore doc.id = ${doc.id}');
        print('fullData = $fullData');

        tempList.add(fullData);
      }
      // ที่อยู่หลัก (1) ขึ้นก่อน
      tempList.sort((a, b) {
        return (b['main_ad_status'] ?? 0).compareTo(a['main_ad_status'] ?? 0);
      });
      setState(() {
        allAddress = tempList;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching address: $e");

      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> deleteAddress(String addressId) async {
    try {
      await db.collection('address').doc(addressId).delete();
    } catch (e) {
      print("Error deleting address: $e");
    }
  }
}
