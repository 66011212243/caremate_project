import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:longdo_maps_api3_flutter/longdo.dart';
import 'package:longdo_maps_api3_flutter/view.dart';

class StatusReturnJob extends StatefulWidget {
  final String jobId;
  final String pid;
  StatusReturnJob({super.key, required this.jobId, required this.pid});

  @override
  State<StatusReturnJob> createState() => _StatusReturnJobState();
}

class _StatusReturnJobState extends State<StatusReturnJob> {
  final map = GlobalKey<LongdoMapState>();
  var db = FirebaseFirestore.instance;
  Map<String, dynamic> detailsJob = {};
  Map<String, dynamic> detailsService = {};
  Map<String, dynamic> detailsUser = {};
  Map<String, dynamic> detailsAddress = {};
  int? statusDrivers;
  bool isLoading = true;

  int activeStep = 0;
  int jobStatus = 0;

  bool isUpdatingStatus = false;
  bool _followRider = true;

  bool _mapReady = false;
  Position? _currentPos;

  dynamic _bikeMarker;
  String? _bikeUri;
  String? _carUri;
  StreamSubscription<Position>? _posSub;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    queryJobData();
    getLocationProvider();
  }

  @override
  void dispose() {
    _posSub?.cancel();
    super.dispose();
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
              label: Icon(
                Icons.arrow_back_ios,
                color: const Color.fromARGB(255, 255, 255, 255),
              ),
            ),
            Text(
              "สถานะงาน",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: Color.fromARGB(255, 255, 0, 0),
        toolbarHeight: 90,
        automaticallyImplyLeading: false,
      ),

      body: Stack(
        children: [
          Positioned(
            right: 16,
            bottom: 120,
            child: FloatingActionButton.small(
              onPressed: () {
                setState(() {
                  _followRider = !_followRider;
                });
              },
              child: Icon(
                _followRider ? Icons.my_location : Icons.location_searching,
              ),
            ),
          ),
          Positioned.fill(
            child: LongdoMapWidget(
              apiKey: "57200903bc3dfd00ca50a47c1bd70f30",
              key: map,
              eventName: [
                IJavascriptChannel(
                  name: "ready",
                  onMessageReceived: (message) async {
                    print("Map Loaded");
                    _mapReady = true;

                    try {
                      _currentPos = await _determinePosition();

                      map.currentState?.call(
                        "location",
                        args: [
                          {
                            "lon": _currentPos!.longitude,
                            "lat": _currentPos!.latitude,
                          },
                          true,
                        ],
                      );

                      await Future.delayed(const Duration(milliseconds: 500));
                      map.currentState?.call("zoom", args: [15, true]);
                      await Future.delayed(const Duration(milliseconds: 300));

                      await updateMarkers();
                      startTracking();
                    } catch (e) {
                      print("Error getting current location: $e");
                    }
                  },
                ),
              ],
            ),
          ),

          DraggableScrollableSheet(
            initialChildSize: 0.10,
            minChildSize: 0.08,
            maxChildSize: 0.50,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(25),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),

                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),

                  children: [
                    const SizedBox(height: 12),

                    // แถบสำหรับลาก
                    Center(
                      child: Container(
                        width: 45,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    // ⭐ เพิ่ม Stepper ตรงนี้
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Row(
                        children: [
                          _buildStep(
                            icon: Icons.medical_services_outlined,
                            title: "อยู่ระหว่างให้บริการ",
                            step: 0,
                          ),

                          _buildLine(0),

                          _buildStep(
                            icon: Icons.directions_car_outlined,
                            title: "กำลังเดินทางกลับ",
                            step: 1,
                          ),

                          _buildLine(1),

                          _buildStep(
                            icon: Icons.home_outlined,
                            title: "กลับถึงจุดรับงานแล้ว",
                            step: 2,
                          ),

                          _buildLine(2),

                          _buildStep(
                            icon: Icons.check_circle_outline,
                            title: "งานเสร็จสิ้น",
                            step: 3,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // การ์ดข้อมูลผู้รับบริการ
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F8F8),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 75,
                            height: 75,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              shape: BoxShape.circle,
                            ),
                            child:
                                detailsService['profile_image'] != null &&
                                    detailsService['profile_image']
                                        .toString()
                                        .isNotEmpty
                                ? ClipOval(
                                    child: Image.network(
                                      detailsService['profile'],
                                      width: 75,
                                      height: 75,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Icon(
                                              Icons.person,
                                              color: Colors.grey.shade500,
                                              size: 45,
                                            );
                                          },
                                    ),
                                  )
                                : Icon(
                                    Icons.person,
                                    color: Colors.grey.shade500,
                                    size: 45,
                                  ),
                          ),

                          const SizedBox(width: 16),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "ชื่อผู้รับบริการ",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),

                                SizedBox(height: 4),

                                Text(
                                  detailsUser['username'] ?? "ไม่พบข้อมูล",
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                SizedBox(height: 10),

                                Row(
                                  children: [
                                    Icon(
                                      Icons.phone,
                                      color: Colors.green,
                                      size: 17,
                                    ),

                                    SizedBox(width: 6),

                                    Text(
                                      detailsService['phone'] ?? "ไม่พบข้อมูล",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    if (detailsJob['job_status'] == 7)
                      SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: isUpdatingStatus
                              ? null
                              : () async {
                                  await updateStatusJobs(8);

                                  if (!mounted) return;

                                  setState(() {
                                    detailsJob['job_status'] = 8;
                                  });

                                  setState(() {
                                    detailsJob['job_status'] = 8;
                                    jobStatus = 8;
                                    updateActiveStep(8);
                                  });

                                  print(
                                    "อัปเดตสถานะงานเป็น 8 สำเร็จ: ${widget.jobId}",
                                  );
                                },
                          label: isUpdatingStatus
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  "ถึงจุดรับงานแล้ว",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            disabledBackgroundColor: Colors.green,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),

                    if (detailsJob['job_status'] == 8)
                      SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: isUpdatingStatus
                              ? null
                              : () async {
                                  await updateStatusJobs(9);

                                  if (!mounted) return;
                                  setState(() {
                                    detailsJob['job_status'] = 9;
                                    jobStatus = 9;
                                    updateActiveStep(9);
                                  });
                                },
                          label: isUpdatingStatus
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  "ยืนยันจบงาน",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            disabledBackgroundColor: Colors.green,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 25),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> queryJobData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // 1. ดึงข้อมูล Job
      var docSnapshot = await db.collection('jobs').doc(widget.jobId).get();

      if (docSnapshot.exists) {
        var data = docSnapshot.data();

        detailsJob = {...data!, 'job_id': docSnapshot.id};
      }

      jobStatus = detailsJob['job_status'] ?? 0;
      updateActiveStep(jobStatus);

      // 2. ดึงข้อมูล Service
      if (detailsJob['service_id'] != null) {
        var serviceDoc = await db
            .collection('service')
            .doc(detailsJob['service_id'])
            .get();

        if (serviceDoc.exists) {
          var data = serviceDoc.data();

          detailsService = {...data!, 'sid': serviceDoc.id};
        }
      }

      // 3. ดึงข้อมูล User
      if (detailsService['service_uid'] != null) {
        var userDoc = await db
            .collection('users')
            .doc(detailsService['service_uid'])
            .get();

        if (userDoc.exists) {
          var data = userDoc.data();

          detailsUser = {...data!, 'uid': userDoc.id};
        }
      }

      // 4. ดึงข้อมูล Address
      if (detailsJob['address_id'] != null) {
        var addressDoc = await db
            .collection('address')
            .doc(detailsJob['address_id'])
            .get();

        if (addressDoc.exists) {
          var data = addressDoc.data();

          detailsAddress = {...data!, 'address_id': addressDoc.id};

          print("Address: $detailsAddress");
        } else {
          print("ไม่พบข้อมูล Address");
        }
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

  Future<void> updateStatusJobs(int statusJob) async {
    setState(() {
      isUpdatingStatus = true;
    });

    try {
      await db.collection('jobs').doc(widget.jobId).update({
        'job_status': statusJob,
      });
      if (statusJob == 9) {
        final snapshot = await db
            .collection('all_drivers')
            .where('job_id', isEqualTo: widget.jobId)
            .where('provider_id', isEqualTo: widget.pid)
            .get();

        for (final doc in snapshot.docs) {
          await doc.reference.update({'status_drivers': 5});
        }
      }

      print("อัปเดต job_status เป็น $statusJob สำเร็จ");
    } catch (e) {
      print("เกิดข้อผิดพลาดในการอัปเดต job_status: $e");
    } finally {
      if (mounted) {
        setState(() {
          isUpdatingStatus = false;
        });
      }
    }
  }

  void updateActiveStep(int status) {
    if (status == 6) {
      activeStep = 0;
    } else if (status == 7) {
      activeStep = 1;
    } else if (status == 8) {
      activeStep = 2;
    } else if (status == 9) {
      activeStep = 3;
    }
  }

  Widget _buildStep({
    required IconData icon,
    required String title,
    required int step,
  }) {
    bool finished = step < activeStep;
    bool active = step == activeStep;

    Color color;

    if (finished) {
      color = Colors.green;
    } else if (active) {
      color = Colors.red;
    } else {
      color = Colors.grey.shade300;
    }

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            child: Icon(icon, color: Colors.white, size: 27),
          ),

          const SizedBox(height: 7),

          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
              color: active ? Colors.red : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLine(int step) {
    bool finished = step < activeStep;

    return Expanded(
      child: Container(
        height: 3,
        margin: const EdgeInsets.only(bottom: 25),
        color: finished ? Colors.green : Colors.grey.shade300,
      ),
    );
  }

  Future<void> getLocationProvider() async {
    try {
      Position myPosition = await _determinePosition();

      final providerDoc = db.collection('location_provider').doc(widget.pid);

      final doc = await providerDoc.get();

      if (doc.exists) {
        await providerDoc.update({
          'latitude': myPosition.latitude,
          'longitude': myPosition.longitude,
        });
      } else {
        await providerDoc.set({
          'pid': widget.pid,
          'latitude': myPosition.latitude,
          'longitude': myPosition.longitude,
        });
      }

      print(
        "อัปเดตตำแหน่งสำเร็จ: "
        "${myPosition.latitude}, ${myPosition.longitude}",
      );
    } catch (e) {
      print("เกิดข้อผิดพลาดในการอัปเดตตำแหน่ง: $e");
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<String> assetToDataUri(String path) async {
    final bytes = await rootBundle.load(path);
    final base64Str = base64Encode(bytes.buffer.asUint8List());
    return "data:image/png;base64,$base64Str";
  }

  void startTracking() {
    _posSub?.cancel(); // กันซ้อน

    _posSub =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 2, // อัปเดตเมื่อขยับเกิน 2 เมตร
          ),
        ).listen((pos) async {
          _currentPos = pos;

          // 1. ขยับหมุดรถบนแผนที่
          await updateBikeMarker();

          if (_followRider) {
            map.currentState?.call(
              "location",
              args: [
                {"lon": pos.longitude, "lat": pos.latitude},
                true, // true = เลื่อนแบบมีแอนิเมชัน
              ],
            );
          }

          // 2. ส่งตำแหน่งขึ้น Firestore
          try {
            await db.collection('location_provider').doc(widget.pid).set({
              'pid': widget.pid,
              'latitude': pos.latitude,
              'longitude': pos.longitude,
            }, SetOptions(merge: true));
          } catch (e) {
            log('อัปเดตตำแหน่งไม่สำเร็จ: $e');
          }
        }, onError: (e) => log('Position stream error: $e'));
  }

  Future<void> updateMarkers({int? status}) async {
    if (!_mapReady) return;
    final mapState = map.currentState;
    if (mapState == null) return;

    mapState.call("Overlays.clear");
    mapState.call("Route.clear");
    _bikeMarker = null;

    // ใช้สถานะที่ส่งมาก่อน ถ้าไม่ส่งมาก็ใช้ค่าใน detailsJob
    final currentStatus = status ?? detailsJob['job_status'];

    double? lat;
    double? lon;

    if (currentStatus == 7 || currentStatus == 8 || currentStatus == 9) {
      lat = (detailsAddress['latitude'] as num?)?.toDouble();
      lon = (detailsAddress['longitude'] as num?)?.toDouble();
      log("ที่อยู่ผู้รับบริการ: lat = $lat, lon = $lon");
    }

    if (lat != null && lon != null) {
      final marker = Longdo.LongdoObject(
        "Marker",
        args: [
          {"lon": lon, "lat": lat},
        ],
      );
      mapState.call("Overlays.add", args: [marker]);
    }

    // ลากเส้นทางจากไรเดอร์ไปหาปลายทาง
    if (lat != null && lon != null && _currentPos != null) {
      mapState.call(
        "Route.add",
        args: [
          {"lon": _currentPos!.longitude, "lat": _currentPos!.latitude},
        ],
      );
      mapState.call(
        "Route.add",
        args: [
          {"lon": lon, "lat": lat},
        ],
      );
      mapState.call("Route.search");
    }
    if (_posSub != null) {
      await updateBikeMarker();
    }
  }

  Future<void> updateBikeMarker() async {
    if (!_mapReady) return;
    final mapState = map.currentState;
    final pos = _currentPos;
    if (mapState == null || pos == null) return;

    // ลบหมุดรถอันเก่า (ถ้ามี)
    if (_bikeMarker != null) {
      mapState.call("Overlays.remove", args: [_bikeMarker]);
    }

    _bikeUri ??= await assetToDataUri('assets/images/bike1.png');
    _carUri ??= await assetToDataUri('assets/images/car0.png');

    if (detailsJob['vehicle_type'] == 0) {
      _bikeMarker = Longdo.LongdoObject(
        "Marker",
        args: [
          {"lon": pos.longitude, "lat": pos.latitude},
          {
            "icon": {
              "url": _bikeUri,
              "offset": {"x": 0, "y": 0},
            },
            "size": {"x": 40, "y": 40},
          },
        ],
      );
    }
    if (detailsJob['vehicle_type'] == 1) {
      _bikeMarker = Longdo.LongdoObject(
        "Marker",
        args: [
          {"lon": pos.longitude, "lat": pos.latitude},
          {
            "icon": {
              "url": _carUri,
              "offset": {"x": 0, "y": 0},
            },
            "size": {"x": 40, "y": 40},
          },
        ],
      );
    }

    mapState.call("Overlays.add", args: [_bikeMarker]);
  }
}
