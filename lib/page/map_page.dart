import 'dart:convert';
import 'dart:developer';
// import 'dart:nativewrappers/_internal/vm/lib/developer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:longdo_maps_api3_flutter/longdo_maps_api3_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

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

  final searchController = TextEditingController();

  List<Map<String, dynamic>> searchResults = [];

  bool isSearching = false;

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
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: "ค้นหาสถานที่...",
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.black),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.red),
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    onSubmitted: (_) {
                      searchPlace();
                    },
                  ),
                ),
                IconButton(
                  onPressed: searchPlace,
                  icon: const Icon(Icons.search, color: Colors.black),
                ),
                // IconButton(
                //   onPressed: () {},
                //   icon: Icon(Icons.search, color: Colors.black),
                // ),
              ],
            ),
          ),
          if (isSearching)
            const Padding(
              padding: EdgeInsets.only(left: 25, right: 25),
              child: LinearProgressIndicator(),
            ),

          if (searchResults.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(left: 25, right: 25, bottom: 10),
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(blurRadius: 5, color: Colors.black26)],
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: searchResults.length,
                itemBuilder: (context, index) {
                  final place = searchResults[index];

                  return ListTile(
                    leading: const Icon(Icons.location_on, color: Colors.red),
                    title: Text(place['name'] ?? 'ไม่พบชื่อสถานที่'),
                    subtitle: Text(
                      place['address'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      selectSearchResult(place);
                    },
                  );
                },
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
                    if (latitude == null || longitude == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("กรุณาเลือกตำแหน่งบนแผนที่ก่อน"),
                        ),
                      );
                      return;
                    }
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
                      // ดึงตำแหน่งปัจจุบัน
                      Position pos = await _determinePosition();

                      print("Current latitude: ${pos.latitude}");
                      print("Current longitude: ${pos.longitude}");

                      // เลื่อนแผนที่ไปตำแหน่งปัจจุบัน
                      map.currentState?.call(
                        "location",
                        args: [
                          {"lon": pos.longitude, "lat": pos.latitude},
                        ],
                      );

                      // กำหนดระดับ Zoom
                      map.currentState?.call("zoom", args: [15]);
                    } catch (e) {
                      print("Error getting current location: $e");
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

  Future<void> searchPlace() async {
    final keyword = searchController.text.trim();

    if (keyword.isEmpty) {
      return;
    }

    setState(() {
      isSearching = true;
      searchResults = [];
    });

    try {
      // ดึงตำแหน่งปัจจุบัน
      Position currentPosition = await _determinePosition();

      final double currentLat = currentPosition.latitude;

      final double currentLon = currentPosition.longitude;

      print("Current lat: $currentLat");
      print("Current lon: $currentLon");

      // ------------------------------------------
      // กำหนด tag จากคำค้น
      // ------------------------------------------

      String? tag;

      if (keyword.toLowerCase() == 'hospital' || keyword == 'โรงพยาบาล') {
        tag = 'hospital';
      } else if (keyword.toLowerCase() == 'school' || keyword == 'โรงเรียน') {
        tag = 'school';
      } else if (keyword.toLowerCase() == 'hotel' || keyword == 'โรงแรม') {
        tag = 'hotel';
      }

      // ------------------------------------------
      // ถ้าเป็นหมวดที่รู้จัก
      // ใช้ Nearby POI API
      // ------------------------------------------

      if (tag != null) {
        final url = Uri.parse(
          'https://api.longdo.com/POIService/json/search'
          '?tag=$tag'
          '&lon=$currentLon'
          '&lat=$currentLat'
          '&span=20km'
          '&limit=20'
          '&locale=th'
          '&key=57200903bc3dfd00ca50a47c1bd70f30',
        );

        print("POI Search URL: $url");

        final response = await http.get(url);

        print(
          "POI Search response: "
          "${response.body}",
        );

        if (response.statusCode != 200) {
          throw Exception('Search error: ${response.statusCode}');
        }

        final data = jsonDecode(response.body);

        final List<Map<String, dynamic>> results = [];

        for (var item in (data['data'] ?? [])) {
          final lat = item['lat'];
          final lon = item['lon'];

          // ต้องมีพิกัด
          if (lat == null || lon == null) {
            continue;
          }

          results.add(Map<String, dynamic>.from(item));
        }

        print("Filtered POI results: $results");

        setState(() {
          searchResults = results;
          isSearching = false;
        });

        if (results.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("ไม่พบ$keyword ในบริเวณใกล้เคียง")),
          );
        }

        return;
      }

      // ------------------------------------------
      // ถ้าไม่ใช่หมวดที่กำหนดไว้
      // ใช้ Search API ปกติ
      // ------------------------------------------

      final url = Uri.parse(
        'https://search.longdo.com/mapsearch/json/search'
        '?keyword=${Uri.encodeComponent(keyword)}'
        '&dataset=poi_p'
        '&limit=20'
        '&locale=th'
        '&key=57200903bc3dfd00ca50a47c1bd70f30',
      );

      print("Normal Search URL: $url");

      final response = await http.get(url);

      print(
        "Normal Search response: "
        "${response.body}",
      );

      if (response.statusCode != 200) {
        throw Exception('Search error: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);

      final List<Map<String, dynamic>> results = [];

      for (var item in (data['data'] ?? [])) {
        final type = item['type'];
        final lat = item['lat'];
        final lon = item['lon'];

        if (lat == null || lon == null) {
          continue;
        }

        // ไม่เอาถนน
        if (type == 'road') {
          continue;
        }

        // ไม่เอา tag
        if (type == 'other') {
          continue;
        }

        results.add(Map<String, dynamic>.from(item));
      }

      print("Filtered normal results: $results");

      setState(() {
        searchResults = results;
        isSearching = false;
      });

      if (results.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("ไม่พบสถานที่ที่ค้นหา")));
      }
    } catch (e) {
      print("Search exception: $e");

      setState(() {
        isSearching = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("เกิดข้อผิดพลาดในการค้นหา: $e")));
    }
  }

  void selectSearchResult(Map<String, dynamic> place) async {
    final double lat = (place['lat'] as num).toDouble();
    final double lon = (place['lon'] as num).toDouble();

    print("Selected: ${place['name']}");
    print("lat: $lat, lon: $lon");

    try {
      // 1. เลื่อนแผนที่ไปตำแหน่งที่เลือกก่อน
      map.currentState?.call(
        "location",
        args: [
          {"lon": lon, "lat": lat},
          true, // animate
        ],
      );
      await Future.delayed(const Duration(milliseconds: 300));

      // 2. ค่อย Zoom
      map.currentState?.call("zoom", args: [16]);
      await Future.delayed(const Duration(milliseconds: 300));

      // 3. ลบหมุดเก่า แล้วปักหมุดใหม่
      map.currentState?.call("Overlays.clear");
      final marker = Longdo.LongdoObject(
        "Marker",
        args: [
          {"lon": lon, "lat": lat},
          {"draggable": true},
        ],
      );
      map.currentState?.call("Overlays.add", args: [marker]);
    } catch (e) {
      log("selectSearchResult map error: $e");
    }

    setState(() {
      latitude = lat;
      longitude = lon;
      selectedlocation = place['name'] ?? 'ไม่พบชื่อสถานที่';
      locationController.text = selectedlocation!;
      searchResults = [];
    });
  }
}
