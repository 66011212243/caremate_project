import 'package:caremate_application/page/details_provider.dart';
import 'package:caremate_application/page/drivers_page.dart';
import 'package:caremate_application/page/edit_job.dart';
import 'package:caremate_application/page/map_details_page.dart';
import 'package:caremate_application/page/map_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:longdo_maps_api3_flutter/longdo_maps_api3_flutter.dart';

class DetailsJobService extends StatefulWidget {
  String jobId = '';
  DetailsJobService({super.key, required this.jobId});

  @override
  State<DetailsJobService> createState() => _DetailsJobServiceState();
}

class _DetailsJobServiceState extends State<DetailsJobService> {
  bool isLoading = true;
  var db = FirebaseFirestore.instance;
  Map<String, dynamic> detailsJob = {};
  double? latitudeLocation;
  double? longitudeLocation;
  bool isEdited = false;

  final _map = GlobalKey<LongdoMapState>();
  bool _ready = false;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    queryJobDetails();
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
                //Navigator.pop(context, isEdited);
                Navigator.pop(context, 'edited');
              },
              label: Icon(Icons.arrow_back_ios, color: Colors.black),
            ),
            Text(
              "รายละเอียดงาน",
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
          ? Center(child: CircularProgressIndicator())
          : detailsJob.isEmpty
          ? Center(
              child: Text(
                'ไม่มีรายการ',
                style: TextStyle(
                  color: Color.fromARGB(255, 81, 81, 81),
                  fontSize: 16,
                ),
              ),
            )
          : SingleChildScrollView(
              child: Container(
                child: Padding(
                  padding: const EdgeInsets.only(top: 20, left: 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 15),
                      Row(
                        children: [
                          Text(
                            "สถานที่ :",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 10),
                          SizedBox(
                            width: 220,
                            child: Text(
                              detailsJob['place_name'],
                              style: TextStyle(fontSize: 20),
                            ),
                          ),
                        ],
                      ),

                      Padding(
                        padding: const EdgeInsets.only(bottom: 30, top: 30),
                        child: Center(
                          child: SizedBox(
                            width: 300,
                            height: 150,
                            child: Stack(
                              children: [
                                // Longdo Map
                                MapPreview(
                                  latitude: (detailsJob['latitude'] as num)
                                      .toDouble(),
                                  longitude: (detailsJob['longitude'] as num)
                                      .toDouble(),
                                ),

                                // ปุ่มใสครอบ Map
                                Positioned.fill(
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        print("Map Clicked");
                                        print("=== ก่อนเปิด Map ===");
                                        print("Lat: ${detailsJob['latitude']}");
                                        print(
                                          "Lon: ${detailsJob['longitude']}",
                                        );

                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                MapDetailsPage(
                                                  latitude:
                                                      detailsJob['latitude'],
                                                  longitude:
                                                      detailsJob['longitude'],
                                                ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      Row(
                        children: [
                          Text(
                            "วันที่ :",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 10),
                          SizedBox(
                            width: 200,
                            child: Text(
                              detailsJob['date'],
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 15),
                      Row(
                        children: [
                          Text(
                            "เวลางาน :",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text("จาก", style: TextStyle(fontSize: 14)),
                          SizedBox(width: 10),
                          SizedBox(
                            child: Text(
                              detailsJob['start_time'],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Text("ถึง", style: TextStyle(fontSize: 14)),
                          SizedBox(width: 10),
                          SizedBox(
                            child: Text(
                              detailsJob['end_time'],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 15),
                      Row(
                        children: [
                          Text(
                            "เรทค่าบริการ:",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 10),
                          SizedBox(
                            width: 120,
                            child: Text(
                              "${detailsJob['service_fee']} บาท",
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 15),
                      Row(
                        children: [
                          Text(
                            "ประเภทรถ:",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 10),

                          Text(
                            detailsJob['vehicle_type'] == 0
                                ? "Bike (มอเตอร์ไซค์)"
                                : "Car (รถยนต์)",
                            style: TextStyle(fontSize: 16),
                          ),

                          SizedBox(width: 10),
                        ],
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            "ลักษณะงาน:",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 10),
                          SizedBox(
                            width: 200,
                            child: Text(
                              detailsJob['job_type'],
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 15),
                      if (detailsJob['additional_info'] != null)
                        Row(
                          children: [
                            Text(
                              "ข้อมูลพิเศษ:",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              detailsJob['additional_info'] == 0
                                  ? "ผู้ป่วยติดเตียง"
                                  : "ผู้ป่วยนั่งวิลแชร์",
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      SizedBox(height: 30),

                      const SizedBox(height: 30),

                      // ส่วนจัดการประกาศงาน
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(right: 30),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "จัดการประกาศงาน",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 15),

                            // ดูผู้สมัคร / ดูผู้ให้บริการ
                            if (detailsJob['job_status'] == 0)
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            DriversPage(JobId: widget.jobId),
                                      ),
                                    );

                                    if (result == true) {
                                      await queryJobDetails();
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.people_outline,
                                    size: 22,
                                  ),
                                  label: const Text(
                                    "ดูผู้สมัครงาน",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),

                            if (detailsJob['job_status'] == 1)
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    print("ดูข้อมูลผู้ให้บริการ");

                                    String? providerId = await queryDriver();

                                    if (providerId == null) {
                                      print("ไม่พบผู้ให้บริการ");
                                      return;
                                    }

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DetailsProvider(
                                          pid: providerId,
                                          vehicle_type:
                                              detailsJob['vehicle_type'],
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.person_outline,
                                    size: 22,
                                  ),
                                  label: const Text(
                                    "ดูข้อมูลผู้ให้บริการ",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),

                            const SizedBox(height: 12),

                            // แก้ไข / ลบ
                            Row(
                              children: [
                                // ปุ่มแก้ไข
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      print("แก้ไขงาน ${widget.jobId}");
                                      if (detailsJob['job_status'] != 0) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "ไม่สามารถแก้ไขงานได้ เนื่องจากงานอยู่ระหว่างดำเนินการ",
                                            ),
                                          ),
                                        );

                                        return;
                                      }

                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => EditJob(
                                            sid: detailsJob['service_id']
                                                .toString(),
                                            jobId: widget.jobId,
                                          ),
                                        ),
                                      );

                                      // ถ้าแก้ไขสำเร็จ ให้โหลดข้อมูลใหม่
                                      if (result == 'edited') {
                                        
                                        queryJobDetails();
                                      }
                                    },
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 20,
                                    ),
                                    label: const Text(
                                      "แก้ไขงาน",
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.black87,
                                      side: const BorderSide(
                                        color: Colors.grey,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 10),

                                // ปุ่มลบ
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      print("ลบงาน ${widget.jobId}");
                                      if (detailsJob['job_status'] != 0) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "ไม่สามารถลบงานได้ เนื่องจากงานอยู่ระหว่างดำเนินการ",
                                            ),
                                          ),
                                        );

                                        return;
                                      }

                                      // ถ้า status == 0 ค่อยเปิด Popup ยืนยัน
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                            title: const Text("ยืนยันการลบงาน"),
                                            content: const Text(
                                              "คุณต้องการลบประกาศงานนี้ใช่หรือไม่?",
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                                child: const Text(
                                                  "ยกเลิก",
                                                  style: TextStyle(
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ),

                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);

                                                  print(
                                                    "ยืนยันลบงาน ${widget.jobId}",
                                                  );

                                                  deleteJob(widget.jobId);
                                                },
                                                child: const Text(
                                                  "ยืนยันการลบ",
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 20,
                                    ),
                                    label: const Text(
                                      "ลบงาน",
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Future<void> queryJobDetails() async {
    setState(() {
      isLoading = true;
    });

    try {
      var docSnapshot = await db.collection('jobs').doc(widget.jobId).get();

      if (docSnapshot.exists) {
        var data = docSnapshot.data();

        detailsJob = {...data!, 'job_id': docSnapshot.id};

        // print('job_id: ${docSnapshot.id}');
        // print('detailsJob: $detailsJob');
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching jobs: $e");

      setState(() {
        isLoading = false;
      });
    }
  }

  Future<String?> queryDriver() async {
    var snapshot = await db
        .collection('all_drivers')
        .where('job_id', isEqualTo: widget.jobId)
        .where('status_drivers', isEqualTo: 1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      var data = snapshot.docs.first.data();

      print("ข้อมูล: $data");

      return data['provider_id'];
    }

    return null;
  }

  Future<void> deleteJob(String addressId) async {
    try {
      await db.collection('jobs').doc(addressId).delete();
      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      print("Error deleting address: $e");
    }
  }
}

class MapPreview extends StatefulWidget {
  final double latitude;
  final double longitude;

  const MapPreview({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<MapPreview> createState() => _MapPreviewState();
}

class _MapPreviewState extends State<MapPreview> {
  final _map = GlobalKey<LongdoMapState>();
  bool _ready = false;

  Future<void> _moveToJob() async {
    final lat = widget.latitude;
    final lon = widget.longitude;
    debugPrint('Longdo target => lat: $lat, lon: $lon');

    try {
      // ย้ายแผนที่
      _map.currentState?.call(
        "location",
        args: [
          {"lon": lon, "lat": lat},
          true,
        ],
      );
      await Future.delayed(const Duration(milliseconds: 400));

      // ซูม
      _map.currentState?.call("zoom", args: [14]);
      await Future.delayed(const Duration(milliseconds: 300));

      // ล้างหมุดเก่า (กันหมุดซ้อนเวลาพิกัดเปลี่ยน) แล้วปักใหม่
      _map.currentState?.call("Overlays.clear");
      final marker = Longdo.LongdoObject(
        "Marker",
        args: [
          {"lon": lon, "lat": lat},
        ],
      );
      _map.currentState?.call("Overlays.add", args: [marker]);
    } catch (e) {
      debugPrint("Longdo Map Error: $e");
    }
  }

  @override
  void didUpdateWidget(covariant MapPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ถ้าพิกัดเปลี่ยนหลังแผนที่พร้อมแล้ว (เช่น ข้อมูลงานโหลดมาทีหลัง) ให้ย้ายตาม
    if (_ready &&
        (oldWidget.latitude != widget.latitude ||
            oldWidget.longitude != widget.longitude)) {
      _moveToJob();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      width: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            blurRadius: 3,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: LongdoMapWidget(
          apiKey: "57200903bc3dfd00ca50a47c1bd70f30",
          key: _map,
          eventName: [
            IJavascriptChannel(
              name: "ready",
              onMessageReceived: (message) async {
                if (_ready) return;
                _ready = true;
                await Future.delayed(const Duration(milliseconds: 1000));
                await _moveToJob();
              },
            ),
          ],
        ),
      ),
    );
  }
}
