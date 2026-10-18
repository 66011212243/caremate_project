import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:longdo_maps_api3_flutter/longdo_maps_api3_flutter.dart';

// รันแอปด้วย: flutter run --dart-define=LONGDO_KEY=คีย์ของคุณ
const String _apiKey = "57200903bc3dfd00ca50a47c1bd70f30";

// คำค้นกว้างๆ -> รายการ tag (ค้นแบบใกล้ตัวก่อน)
const Map<String, List<String>> _tagMap = {
  'hospital': ['hospital'],
  'โรงพยาบาล': ['hospital'],
  'school': ['school', 'โรงเรียน'],
  'โรงเรียน': ['school', 'โรงเรียน'],
  'hotel': ['hotel'],
  'โรงแรม': ['hotel'],
  'bank': ['bank', 'ธนาคาร'],
  'ธนาคาร': ['bank', 'ธนาคาร'],
};

// ขยายระยะค้นหาเป็นขั้น (กม.) หยุดเมื่อเจอผลลัพธ์พอ
const List<int> _spansKm = [3, 10, 20];
const int _enoughResults = 5;

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final map = GlobalKey<LongdoMapState>();

  final TextEditingController locationController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  String? selectedlocation;
  double? latitude;
  double? longitude;

  List<Map<String, dynamic>> searchResults = [];
  bool isSearching = false;

  @override
  void dispose() {
    locationController.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("เลือกสถานที่")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10, left: 25, right: 15),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: TextField(
                      controller: searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => searchPlace(),
                      decoration: InputDecoration(
                        hintText: "ค้นหาสถานที่...",
                        suffixIcon:
                            (searchController.text.isNotEmpty ||
                                searchResults.isNotEmpty)
                            ? IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  searchController.clear();
                                  setState(() => searchResults = []);
                                },
                              )
                            : null,
                        // ...enabledBorder / focusedBorder เดิม
                      ),
                      onChanged: (_) =>
                          setState(() {}), // ให้ปุ่ม X โผล่ตอนพิมพ์
                    ),
                  ),
                ),
                IconButton(
                  onPressed: searchPlace,
                  icon: const Icon(Icons.search, color: Colors.black),
                ),
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
                boxShadow: const [
                  BoxShadow(blurRadius: 5, color: Colors.black26),
                ],
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: searchResults.length,
                itemBuilder: (context, index) {
                  final place = searchResults[index];
                  final distance = place['distance_m'] as double?;
                  final address = (place['address'] ?? '').toString();
                  final subtitle = [
                    if (distance != null) _formatDistance(distance),
                    if (address.isNotEmpty) address,
                  ].join(' • ');

                  return ListTile(
                    leading: const Icon(Icons.location_on, color: Colors.red),
                    title: Text(
                      place['name']?.toString() ?? 'ไม่พบชื่อสถานที่',
                    ),
                    subtitle: Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => selectSearchResult(place),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(bottom: 10, left: 25, right: 15),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: TextField(
                      readOnly: true,
                      controller: locationController,
                      decoration: const InputDecoration(
                        hintText: "สถานที่ปัจจุบัน",
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
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
                    Navigator.pop(context, {
                      "lat": latitude,
                      "lon": longitude,
                      "address": selectedlocation,
                    });
                  },
                  child: const Text("ยืนยันตำแหน่ง"),
                ),
              ],
            ),
          ),
          Expanded(
            child: LongdoMapWidget(
              apiKey: _apiKey,
              key: map,
              eventName: [
                IJavascriptChannel(
                  name: "ready",
                  onMessageReceived: (message) async {
                    debugPrint("Map Loaded");
                    try {
                      final pos = await _determinePosition();
                      // รอให้แมปตั้งค่าเริ่มต้นเสร็จก่อน ไม่งั้นโดนรีเซ็ตทับ
                      await Future.delayed(const Duration(milliseconds: 800));
                      await _moveMapTo(pos.latitude, pos.longitude, zoom: 15);
                    } catch (e) {
                      debugPrint("Error getting current location: $e");
                    }
                  },
                ),
                IJavascriptChannel(
                  name: "click",
                  onMessageReceived: (message) async {
                    final jsonObj = json.decode(message.message);
                    // แปลงเป็น double กันกรณีค่าที่ส่งมาเป็น int
                    final lat = (jsonObj['data']['lat'] as num).toDouble();
                    final lon = (jsonObj['data']['lon'] as num).toDouble();

                    _placeMarker(lat, lon);

                    final location = await getLocationFromLatLng(lat, lon);
                    if (!mounted) return;

                    setState(() {
                      selectedlocation = location;
                      locationController.text = location;
                      latitude = lat;
                      longitude = lon;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // ควบคุมแมป
  // ---------------------------------------------------------------

  /// เลื่อนแมปไปที่พิกัด แล้วซูม
  /// (ไม่ส่ง argument ตัวที่ 2 ของ location/zoom เพื่อกันค่า null ที่ทำให้
  /// แมปขึ้น error "Expected value to be of type number")
  Future<void> _moveMapTo(double lat, double lon, {int zoom = 16}) async {
    final state = map.currentState;
    if (state == null) return;

    state.call(
      "location",
      args: [
        {"lon": lon, "lat": lat},
      ],
    );
    await Future.delayed(const Duration(milliseconds: 300));
    state.call("zoom", args: [zoom]);
  }

  /// ลบหมุดเก่า แล้วปักหมุดใหม่
  void _placeMarker(double lat, double lon) {
    final state = map.currentState;
    if (state == null) return;

    state.call("Overlays.clear");
    final marker = Longdo.LongdoObject(
      "Marker",
      args: [
        {"lon": lon, "lat": lat},
        {"draggable": true},
      ],
    );
    state.call("Overlays.add", args: [marker]);
  }

  // ---------------------------------------------------------------
  // ตำแหน่งปัจจุบัน
  // ---------------------------------------------------------------
  Future<Position> _determinePosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }
    return Geolocator.getCurrentPosition();
  }

  // ---------------------------------------------------------------
  // พิกัด -> ชื่อสถานที่ (ใช้ตอนผู้ใช้กดปักหมุดเอง)
  // ลำดับ: Longdo (ไทย) -> geocoding ของระบบ -> แสดงพิกัดดิบ
  // ---------------------------------------------------------------
  Future<String> getLocationFromLatLng(double lat, double lon) async {
    try {
      final uri = Uri.https('api.longdo.com', '/map/services/address', {
        'lon': '$lon',
        'lat': '$lat',
        'noelevation': '1',
        'locale': 'th',
        'key': _apiKey,
      });

      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        debugPrint("Longdo address response: $data");

        final parts = <String>[
          for (final key in [
            'poi',
            'aoi',
            'road',
            'subdistrict',
            'district',
            'province',
          ])
            if (data[key] != null && data[key].toString().trim().isNotEmpty)
              data[key].toString().trim(),
        ];

        if (parts.isNotEmpty) return parts.join(' ');
      }
    } catch (e) {
      log("Longdo reverse geocode error: $e");
    }

    return _fallbackAddress(lat, lon);
  }

  Future<String> _fallbackAddress(double lat, double lon) async {
    try {
      await setLocaleIdentifier('th_TH');
      final placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = <String>[
          for (final s in [
            p.name,
            p.street,
            p.subLocality,
            p.locality,
            p.administrativeArea,
          ])
            // ตัด Plus Code (เช่น 7727+J9C) และค่าซ้ำออก
            if (s != null && s.isNotEmpty && !_isPlusCode(s)) s,
        ];
        final unique = parts.toSet().toList();
        if (unique.isNotEmpty) return unique.join(' ');
      }
    } catch (e) {
      log("System geocoding error: $e");
    }
    return '${lat.toStringAsFixed(5)}, ${lon.toStringAsFixed(5)}';
  }

  bool _isPlusCode(String s) =>
      RegExp(r'^[0-9A-Z]{4,8}\+[0-9A-Z]{2,3}').hasMatch(s);

  // ---------------------------------------------------------------
  // ค้นหา
  // ---------------------------------------------------------------
  Future<dynamic> _getJson(Uri uri) async {
    final res = await http.get(uri).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) {
      throw Exception('Search error: ${res.statusCode}');
    }
    // decode จาก bytes กันภาษาไทยเพี้ยน
    return jsonDecode(utf8.decode(res.bodyBytes));
  }

  /// แปลงผลดิบจาก API
  /// - [sortByDistance] true  = เรียงใกล้ -> ไกล (ใช้กับการค้นตาม tag)
  ///                    false = คงลำดับความเกี่ยวข้องของ API (ใช้กับการค้นชื่อ)
  List<Map<String, dynamic>> _parseResults(
    dynamic raw,
    double lat,
    double lon, {
    bool filterRoads = false,
    bool sortByDistance = true,
  }) {
    final results = <Map<String, dynamic>>[];

    for (final item in (raw ?? [])) {
      final iLat = (item['lat'] as num?)?.toDouble();
      final iLon = (item['lon'] as num?)?.toDouble();
      if (iLat == null || iLon == null) continue;

      // ข้ามสถานที่ที่ถูกยกเลิกแล้ว
      if (item['obsoleted'] == true) continue;

      // ตัดเฉพาะถนน (ไม่ตัด 'other' เพราะสถานที่จริงหลายแห่งโดนจัดเป็น other)
      if (filterRoads && item['type'] == 'road') continue;

      final entry = Map<String, dynamic>.from(item);
      // คำนวณระยะเองเป็นเมตร (คนละ key กับ 'distance' ของ API ที่เป็น String)
      entry['distance_m'] = Geolocator.distanceBetween(lat, lon, iLat, iLon);
      results.add(entry);
    }

    if (sortByDistance) {
      results.sort(
        (a, b) =>
            (a['distance_m'] as double).compareTo(b['distance_m'] as double),
      );
    }
    return results;
  }

  String _placeKey(Map<String, dynamic> p) =>
      (p['id'] ?? '${p['name']}|${p['lat']}|${p['lon']}').toString();

  /// ค้นตาม tag: ขยายระยะทีละขั้น รวมผลจากทุก tag ตัดซ้ำ แล้วเรียงใกล้ก่อน
  Future<List<Map<String, dynamic>>> _searchByTags(
    List<String> tags,
    double lat,
    double lon,
  ) async {
    var best = <Map<String, dynamic>>[];

    for (final spanKm in _spansKm) {
      final merged = <String, Map<String, dynamic>>{};

      for (final tag in tags) {
        try {
          final uri = Uri.https('api.longdo.com', '/POIService/json/search', {
            'tag': tag,
            'lon': '$lon',
            'lat': '$lat',
            'span': '${spanKm}km',
            'limit': '20',
            'locale': 'th',
            'key': _apiKey,
          });

          final data = await _getJson(uri);
          final results = _parseResults(data['data'], lat, lon);
          debugPrint("tag=$tag span=${spanKm}km -> ${results.length} results");

          for (final r in results) {
            merged.putIfAbsent(_placeKey(r), () => r);
          }
        } catch (e) {
          debugPrint("tag=$tag span=${spanKm}km error: $e");
        }
      }

      final list = merged.values.toList()
        ..sort(
          (a, b) =>
              (a['distance_m'] as double).compareTo(b['distance_m'] as double),
        );

      if (list.length > best.length) best = list;
      if (best.length >= _enoughResults) return best;
    }
    return best;
  }

  /// ค้นด้วยชื่อ: ไม่จำกัดระยะ ใช้ lat/lon เป็นแค่ตัวช่วยจัดอันดับ
  Future<List<Map<String, dynamic>>> _searchByKeyword(
    String keyword,
    double lat,
    double lon,
  ) async {
    final uri = Uri.https('search.longdo.com', '/mapsearch/json/search', {
      'keyword': keyword,
      'lon': '$lon',
      'lat': '$lat',
      'limit': '30',
      'locale': 'th',
      'key': _apiKey,
    });

    final data = await _getJson(uri);
    final raw = data['data'] as List? ?? [];

    // log ดูว่า API คืนอะไร และโดนกรองเหลือเท่าไร
    debugPrint("keyword=$keyword raw=${raw.length}");
    for (final i in raw.take(5)) {
      debugPrint(
        "  ${i['name']} type=${i['type']} obsoleted=${i['obsoleted']}",
      );
    }

    final parsed = _parseResults(
      raw,
      lat,
      lon,
      filterRoads: true,
      sortByDistance: false,
    );
    debugPrint("keyword=$keyword after filter=${parsed.length}");
    return parsed;
  }

  Future<void> searchPlace() async {
    final keyword = searchController.text.trim();
    if (keyword.isEmpty) return;

    FocusScope.of(context).unfocus();

    if (_apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ยังไม่ได้ตั้งค่า LONGDO_KEY")),
      );
      return;
    }

    setState(() {
      isSearching = true;
      searchResults = [];
    });

    try {
      final pos = await _determinePosition();
      final tags = _tagMap[keyword.toLowerCase()];

      var results = <Map<String, dynamic>>[];

      if (tags != null) {
        // คำกว้างๆ เช่น "โรงพยาบาล" -> ใกล้ตัวก่อน แล้วต่อด้วยผลค้นชื่อ
        final byTag = await _searchByTags(tags, pos.latitude, pos.longitude);
        List<Map<String, dynamic>> byKeyword = [];
        try {
          byKeyword = await _searchByKeyword(
            keyword,
            pos.latitude,
            pos.longitude,
          );
        } catch (e) {
          debugPrint("keyword search failed: $e");
        }

        final seen = <String>{};
        results = [
          for (final r in [...byTag, ...byKeyword])
            if (seen.add(_placeKey(r))) r,
        ];
      } else {
        // ชื่อเฉพาะ -> ค้นด้วยชื่อ ไม่จำกัดระยะ
        results = await _searchByKeyword(keyword, pos.latitude, pos.longitude);
      }

      if (!mounted) return;
      setState(() {
        searchResults = results;
        isSearching = false;
      });

      if (results.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('ไม่พบ "$keyword"')));
      }
    } catch (e) {
      debugPrint("Search exception: $e");
      if (!mounted) return;
      setState(() => isSearching = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ค้นหาไม่สำเร็จ กรุณาลองใหม่อีกครั้ง")),
      );
    }
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()} ม.';
    return '${(meters / 1000).toStringAsFixed(1)} กม.';
  }

  // ---------------------------------------------------------------
  // เลือกผลการค้นหา
  // ---------------------------------------------------------------
  Future<void> selectSearchResult(Map<String, dynamic> place) async {
    final double lat = (place['lat'] as num).toDouble();
    final double lon = (place['lon'] as num).toDouble();

    try {
      _placeMarker(lat, lon);
      await _moveMapTo(lat, lon, zoom: 16);
    } catch (e) {
      log("selectSearchResult map error: $e");
    }

    if (!mounted) return;
    setState(() {
      latitude = lat;
      longitude = lon;
      selectedlocation = place['name']?.toString() ?? 'ไม่พบชื่อสถานที่';
      locationController.text = selectedlocation!;
      searchResults = [];
    });
  }
}
