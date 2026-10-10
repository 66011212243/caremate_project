import 'package:flutter/material.dart';
import 'package:longdo_maps_api3_flutter/longdo_maps_api3_flutter.dart';

class MapDetailsPage extends StatefulWidget {
  final double latitude;
  final double longitude;
  MapDetailsPage({super.key, required this.latitude, required this.longitude});

  @override
  State<MapDetailsPage> createState() => _MapDetailsPageState();
}

class _MapDetailsPageState extends State<MapDetailsPage> {
  final map = GlobalKey<LongdoMapState>();
  bool _initialized = false;

  Future<void> _setupMap() async {
    if (_initialized) return;
    _initialized = true;

    final lat = widget.latitude;
    final lon = widget.longitude;
    debugPrint("Target => lat: $lat, lon: $lon");

    // รอให้แผนที่ตั้งค่าเริ่มต้นของตัวเองเสร็จก่อน
    await Future.delayed(const Duration(milliseconds: 1000));

    try {
      // 1) ย้ายแผนที่ก่อน
      map.currentState?.call(
        "location",
        args: [
          {"lon": lon, "lat": lat},
          true,
        ],
      );
      await Future.delayed(const Duration(milliseconds: 500));

      // 2) ซูม
      map.currentState?.call("zoom", args: [14, true]);
      await Future.delayed(const Duration(milliseconds: 300));

      // 3) ปักหมุด
      final marker = Longdo.LongdoObject(
        "Marker",
        args: [
          {"lon": lon, "lat": lat},
        ],
      );
      map.currentState?.call("Overlays.add", args: [marker]);
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              "สถานที่",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        toolbarHeight: 70,
        automaticallyImplyLeading: false,
      ),
      body: LongdoMapWidget(
        apiKey: "57200903bc3dfd00ca50a47c1bd70f30",
        key: map,
        eventName: [
          IJavascriptChannel(
            name: "ready",
            onMessageReceived: (message) => _setupMap(),
          ),
        ],
      ),
    );
  }
}
