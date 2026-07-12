import 'package:flutter/material.dart';
import 'package:longdo_maps_api3_flutter/view.dart';

class StatusJob extends StatefulWidget {
  const StatusJob({super.key});

  @override
  State<StatusJob> createState() => _StatusJobState();
}

class _StatusJobState extends State<StatusJob> {
  final map = GlobalKey<LongdoMapState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Text(
            "สถานะงาน",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: Color.fromARGB(255, 255, 0, 0),
        toolbarHeight: 90,
        automaticallyImplyLeading: false,
      ),

      body: Stack(
        children: [
          Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 20,
                ),

                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 255, 254, 251),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5), // สีเงา
                      spreadRadius: 2, // ความกว้างเงา
                      blurRadius: 6, // ความฟุ้งของเงา
                      offset: Offset(0, 3), // แนวเงา (x, y)
                    ),
                  ],
                ),
                // child: EasyStepper(
                //   activeStep: activeStep,
                //   lineStyle: LineStyle(
                //     lineType: LineType.normal,
                //     lineThickness: 2,
                //     activeLineColor: Colors.yellow[700],
                //     finishedLineColor: Colors.yellow[700],
                //     unreachedLineColor: Colors.grey[300],
                //   ),
                //   activeStepTextColor: Colors.black,
                //   finishedStepTextColor: Colors.grey[300],
                //   internalPadding: 5,
                //   showLoadingAnimation: false,
                //   stepRadius: 25,
                //   showStepBorder: false,
                //   steps: [
                //     EasyStep(
                //       icon: Icon(Icons.inventory_2_outlined, size: 50),
                //       customTitle: Text(
                //         'ที่อยู่ไรเดอร์',
                //         style: TextStyle(
                //           fontSize: 9, // ✅ ปรับขนาดฟอนต์ได้เอง
                //         ),
                //       ),
                //     ),
                //     EasyStep(
                //       icon: Icon(Icons.delivery_dining_outlined, size: 50),
                //       customTitle: Text(
                //         'บ้านลูกค้า',
                //         style: TextStyle(
                //           fontSize: 9, // ✅ ปรับขนาดฟอนต์ได้เอง
                //         ),
                //       ),
                //     ),
                //     EasyStep(
                //       icon: Icon(Icons.local_shipping_outlined, size: 50),
                //       customTitle: Text(
                //         'ปลางทาง',
                //         style: TextStyle(
                //           fontSize: 9, // ✅ ปรับขนาดฟอนต์ได้เอง
                //         ),
                //       ),
                //     ),
                //
                //   ],
                // ),
              ),
            ],
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

                    // try {
                    //   // Position pos =
                    //   //     await _determinePosition(); // ไม่ต้องเป็น nullable
                    //   // log("lat: ${pos.latitude}, lon: ${pos.longitude}");

                    //   // //วาง marker
                    //   // var marker = Longdo.LongdoObject(
                    //   //   "Marker",
                    //   //   args: [
                    //   //     {"lon": pos.longitude, "lat": pos.latitude},
                    //   //   ],
                    //   // );
                    //   // map.currentState?.call("Overlays.add", args: [marker]);

                    //   // // เลื่อน map ไปตำแหน่งปัจจุบัน
                    //   // map.currentState?.call(
                    //   //   "location",
                    //   //   args: [
                    //   //     {"lon": pos.longitude, "lat": pos.latitude},
                    //   //   ],
                    //   // );

                    //   //วาง marker
                    //   var marker = Longdo.LongdoObject(
                    //     "Marker",
                    //     args: [
                    //       {"lon": 103.251827, "lat": 16.246373},
                    //     ],
                    //   );
                    //   map.currentState?.call("Overlays.add", args: [marker]);

                    //   // เลื่อน map ไปตำแหน่งปัจจุบัน
                    //   map.currentState?.call(
                    //     "location",
                    //     args: [
                    //       {"lon": 103.251827, "lat": 16.246373},
                    //     ],
                    //   );
                    //   map.currentState?.call("zoom", args: [14]);
                    // } catch (e) {
                    //   print("Error getting location: $e");
                    // }
                  },
                ),
                // IJavascriptChannel(
                //   name: "click",
                //   onMessageReceived: (message) async {
                //     var jsonObj = json.decode(message.message);
                //     var lat = jsonObj['data']['lat'];
                //     var lon = jsonObj['data']['lon'];

                //     // ลบหมุดเก่า
                //     map.currentState?.call("Overlays.clear");

                //     var marker = Longdo.LongdoObject(
                //       "Marker",
                //       args: [
                //         {"lon": lon, "lat": lat},
                //         {"draggable": true},
                //       ],
                //     );
                //     log(lon.toString());
                //     log(lat.toString());

                //     // เพิ่มหมุดใหม่
                //     map.currentState?.call("Overlays.add", args: [marker]);
                //     try {
                //       final location = await getLocationFromLatLng(lat, lon);

                //       setState(() {
                //         selectedlocation = location;
                //         log(selectedlocation.toString());
                //         locationController.text = selectedlocation!;
                //         latitude = lat;
                //         longitude = lon;
                //       });
                //     } catch (e) {
                //       log("reverse geocode error: $e");
                //     }
                //   },
                // ),
              ],
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.2,
            minChildSize: 0.05,
            maxChildSize: 0.5,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: ListView(
                  controller: scrollController,
                  children: [
                    const SizedBox(height: 10),

                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Center(
                      child: Text(
                        "ข้อมูลผู้รับบริการ",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 255, 0, 0),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(30.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              SizedBox(
                                child: Container(
                                  width: 130,
                                  height: 170,
                                  color: Colors.grey,
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 50,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(width: 30),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              Text(
                                "ชื่อ: สมหมาย ใจดี",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "เบอร์โทร: 0614723778",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
