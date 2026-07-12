import 'dart:convert';
import 'dart:developer';
// import 'dart:nativewrappers/_internal/vm/lib/developer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:longdo_maps_api3_flutter/longdo_maps_api3_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final map = GlobalKey<LongdoMapState>();

  TextEditingController locationController = TextEditingController();

  String? selectedlocation;
  double? latitude;
  double? longitude;

  var markerMap = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [Text("เลือกสถานที่"), SizedBox(height: 8)],
        ),
        //toolbarHeight: 100,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10, left: 25),
            child: Row(
              children: [
                SizedBox(
                  width: 320,
                  height: 50,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "ค้นหาสถานที่...",
                      // prefixIcon: Icon(Icons.search, color: Colors.black),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.black,
                        ), // สีกรอบปกติ
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.search, color: Colors.black),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 10, left: 25),
            child: Row(
              children: [
                SizedBox(
                  width: 230,
                  height: 40,
                  child: TextField(
                    readOnly: true,
                    controller: locationController,
                    decoration: InputDecoration(hintText: "สถานที่ปัจจุบัน"),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, // สีปุ่ม
                    foregroundColor: Colors.white, // สีตัวหนังสือ
                  ),
                  onPressed: () {
                    Navigator.pop(context, {"lat": latitude, "lon": longitude});
                  },
                  child: const Text("ยืนยันตำแหน่ง"),
                ),
              ],
            ),
          ),

          Expanded(
            child: LongdoMapWidget(
              apiKey: "57200903bc3dfd00ca50a47c1bd70f30",
              key: map,
              eventName: [
                IJavascriptChannel(
                  name: "ready",
                  onMessageReceived: (message) async {
                    print("Map Loaded");

                    try {
                      // Position pos =
                      //     await _determinePosition(); // ไม่ต้องเป็น nullable
                      // log("lat: ${pos.latitude}, lon: ${pos.longitude}");

                      // //วาง marker
                      // var marker = Longdo.LongdoObject(
                      //   "Marker",
                      //   args: [
                      //     {"lon": pos.longitude, "lat": pos.latitude},
                      //   ],
                      // );
                      // map.currentState?.call("Overlays.add", args: [marker]);

                      // // เลื่อน map ไปตำแหน่งปัจจุบัน
                      // map.currentState?.call(
                      //   "location",
                      //   args: [
                      //     {"lon": pos.longitude, "lat": pos.latitude},
                      //   ],
                      // );

                      //วาง marker
                      var marker = Longdo.LongdoObject(
                        "Marker",
                        args: [
                          {"lon": 103.251827, "lat": 16.246373},
                        ],
                      );
                      map.currentState?.call("Overlays.add", args: [marker]);

                      // เลื่อน map ไปตำแหน่งปัจจุบัน
                      map.currentState?.call(
                        "location",
                        args: [
                          {"lon": 103.251827, "lat": 16.246373},
                        ],
                      );
                      map.currentState?.call("zoom", args: [14]);
                    } catch (e) {
                      print("Error getting location: $e");
                    }
                  },
                ),
                IJavascriptChannel(
                  name: "click",
                  onMessageReceived: (message) async {
                    var jsonObj = json.decode(message.message);
                    var lat = jsonObj['data']['lat'];
                    var lon = jsonObj['data']['lon'];

                    // ลบหมุดเก่า
                    map.currentState?.call("Overlays.clear");

                    var marker = Longdo.LongdoObject(
                      "Marker",
                      args: [
                        {"lon": lon, "lat": lat},
                        {"draggable": true},
                      ],
                    );
                    log(lon.toString());
                    log(lat.toString());

                    // เพิ่มหมุดใหม่
                    map.currentState?.call("Overlays.add", args: [marker]);
                    try {
                      final location = await getLocationFromLatLng(lat, lon);

                      setState(() {
                        selectedlocation = location;
                        log(selectedlocation.toString());
                        locationController.text = selectedlocation!;
                        latitude = lat;
                        longitude = lon;
                      });
                    } catch (e) {
                      log("reverse geocode error: $e");
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;
    // Test if location services are enabled.
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

  Future<String> getLocationFromLatLng(double lat, double lon) async {
    // if (latLng == null) return "ไม่พบพิกัด";
    //log("getLocationFromLatLng");

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return "${place.name},  ${place.administrativeArea}";
      }
      return "ไม่พบที่อยู่";
    } catch (e) {
      return "เกิดข้อผิดพลาด: $e";
    }
  }
}
