import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:longdo_maps_api3_flutter/longdo_maps_api3_flutter.dart';

class Longdoomap extends StatefulWidget {
  const Longdoomap({super.key});

  @override
  State<Longdoomap> createState() => _LongdoomapState();
}

class _LongdoomapState extends State<Longdoomap> {
  final map = GlobalKey<LongdoMapState>();
  final GlobalKey<ScaffoldMessengerState> messenger =
      GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    var marker;
    var markerMap = {};
    var isAddSourceAnimatedRouting = false;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: messenger,
      home: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                flex: 2,
                child: LongdoMapWidget(
                  apiKey: "",
                  key: map,
                  eventName: [
                    IJavascriptChannel(
                      name: "ready",
                      onMessageReceived: (message) {
                        var marker = Longdo.LongdoObject(
                          "Marker",
                          args: [
                            {"lon": 100.56, "lat": 13.74},
                          ],
                        );
                        map.currentState?.call("Overlays.add", args: [marker]);
                        var id = marker["\$id"];
                        print(id);
                        markerMap[id] = marker;
                        marker["\$id"] = "TEST";
                        id = marker["\$id"];
                        print(id);
                      },
                    ),
                    IJavascriptChannel(
                      name: "click",
                      onMessageReceived: (message) {
                        var jsonObj = json.decode(message.message);
                        var lat = jsonObj['data']['lat'];
                        var lon = jsonObj['data']['lon'];
                        var marker = Longdo.LongdoObject(
                          "Marker",
                          args: [
                            {"lon": lon, "lat": lat},
                            {"draggable": true},
                          ],
                        );
                        map.currentState?.call("Overlays.add", args: [marker]);

                        final id = marker["\$id"];
                        markerMap[id] = marker;
                      },
                    ),
                    IJavascriptChannel(
                      name: "overlayClick",
                      onMessageReceived: (message) {
                        var jsonObj = json.decode(message.message);
                        map.currentState?.call(
                          "Overlays.remove",
                          args: [jsonObj["data"]],
                        );
                        final id = jsonObj["data"]["\$id"];
                        markerMap.remove(id);
                      },
                    ),
                    IJavascriptChannel(
                      name: "overlayDrop",
                      onMessageReceived: (message) async {
                        var obj = json.decode(message.message);
                        final location = await map.currentState?.objectCall(
                          obj["data"],
                          "location",
                        );
                        print(location);
                      },
                    ),
                  ],
                  options: {
                    // "ui": Longdo.LongdoStatic(
                    //   "UiComponent",
                    //   "None",
                    // )
                    // "zoom": 9
                    // "layer": Longdo.LongdoStatic("Layers", "POLITICAL")
                  },
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListView(
                    children: [
                      Text(
                        "Layers",
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Wrap(
                        spacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed: () {
                              var layer = Longdo.LongdoStatic(
                                "Layers",
                                "TRAFFIC",
                              );
                              map.currentState?.call(
                                "Layers.add",
                                args: [layer],
                              );
                            },
                            child: const Text("Traffic"),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              var layer = map.currentState?.LongdoStatic(
                                "Layers",
                                "THAICHOTE",
                              );
                              if (layer != null) {
                                map.currentState?.call(
                                  "Layers.add",
                                  args: [layer],
                                );
                              }
                            },
                            child: const Text("Thaichote"),
                          ),
                        ],
                      ),
                      Text(
                        "LayerType",
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Wrap(
                        spacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed: () {
                              var layer = Longdo.LongdoObject(
                                "Layer",
                                args: [
                                  "bluemarble_terrain",
                                  {
                                    "type": map.currentState?.LongdoStatic(
                                      "LayerType",
                                      "WMS",
                                    ),
                                    "url":
                                        'https://ms.longdo.com/mapproxy/service',
                                    "zoomRange": {"min": 1, "max": 9},
                                    "opacity": 0.5,
                                    "weight": 10,
                                    "bound": {
                                      "minLon": 100,
                                      "minLat": 10,
                                      "maxLon": 101,
                                      "maxLat": 20,
                                    },
                                  },
                                ],
                              );
                              map.currentState?.call(
                                "Layers.add",
                                args: [layer],
                              );
                            },
                            child: const Text("WMS"),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              var layer = Longdo.LongdoObject(
                                "Layer",
                                args: [
                                  "bluemarble_terrain/EPSG3857",
                                  {
                                    "type": map.currentState?.LongdoStatic(
                                      "LayerType",
                                      "TMS",
                                    ),
                                    "url":
                                        "https://ms.longdo.com/mapproxy/tms/1.0.0",
                                  },
                                ],
                              );
                              map.currentState?.call(
                                "Layers.add",
                                args: [layer],
                              );
                            },
                            child: const Text("TMS"),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              var layer = Longdo.LongdoObject(
                                "Layer",
                                args: [
                                  "bluemarble_terrain",
                                  {
                                    "type": map.currentState?.LongdoStatic(
                                      "LayerType",
                                      "WMTS_REST",
                                    ),
                                    "url":
                                        "https://ms.longdo.com/mapproxy/wmts",
                                    "srs": "GLOBAL_WEBMERCATOR",
                                  },
                                ],
                              );
                              map.currentState?.call(
                                "Layers.add",
                                args: [layer],
                              );
                            },
                            child: const Text("WMTS REST"),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              map.currentState?.call("Layers.clear");
                            },
                            child: const Text("Clear layer"),
                          ),
                        ],
                      ),
                      Text(
                        "Marker",
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Wrap(
                        spacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed: () {
                              marker ??= Longdo.LongdoObject(
                                "Marker",
                                args: [
                                  {"lon": 100.56, "lat": 13.74},
                                ],
                              );
                              if (marker != null) {
                                map.currentState?.call(
                                  "Overlays.add",
                                  args: [marker!],
                                );
                              }
                            },
                            child: const Text("Add"),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              if (marker != null) {
                                map.currentState?.call(
                                  "Overlays.remove",
                                  args: [marker!],
                                );
                              }
                            },
                            child: const Text("Remove"),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              map.currentState?.call("Overlays.clear");
                            },
                            child: const Text("Clear"),
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed: () {
                              var marker = Longdo.LongdoObject(
                                "Popup",
                                args: [
                                  {"lon": 100.56, "lat": 13.74},
                                  {
                                    "title": "Popup",
                                    "detail": "This is a pop up",
                                  },
                                ],
                              );
                              map.currentState?.call(
                                "Overlays.add",
                                args: [marker],
                              );
                            },
                            child: const Text("PopUp"),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              var marker = Longdo.LongdoObject(
                                "Marker",
                                args: [
                                  {"lon": 101.2, "lat": 12.8},
                                  {
                                    "title": "Marker",
                                    "detail": "Drag me",
                                    "visibleRange": {"min": 7, "max": 9},
                                    "draggable": true,
                                  },
                                ],
                              );
                              map.currentState?.call(
                                "Overlays.add",
                                args: [marker],
                              );
                            },
                            child: const Text("Draggable Marker"),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              var marker = Longdo.LongdoObject(
                                "Marker",
                                args: [
                                  {"lon": 99.35, "lat": 14.25},
                                  {
                                    "title": "Custom Marker",
                                    "icon": {
                                      "html": "This is a HTML Marker",
                                      "offset": {"x": 18, "y": 21},
                                    },
                                  },
                                ],
                              );
                              map.currentState?.call(
                                "Overlays.add",
                                args: [marker],
                              );
                            },
                            child: const Text("HTML Marker"),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              var marker = Longdo.LongdoObject(
                                "Marker",
                                args: [
                                  {"lon": 100.41, "lat": 13.84},
                                  {"title": "Rotate Marker", "rotate": 90},
                                ],
                              );
                              map.currentState?.call(
                                "Overlays.add",
                                args: [marker],
                              );
                            },
                            child: const Text("Rotated Marker"),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              var marker = Longdo.LongdoObject(
                                "Marker",
                                args: [
                                  {
                                    "type": "Feature",
                                    "properties": [],
                                    "geometry": {
                                      "type": "Point",
                                      "coordinates": [
                                        100.49477577209473,
                                        13.752891404314328,
                                      ],
                                    },
                                  },
                                ],
                              );
                              map.currentState?.call(
                                "Overlays.add",
                                args: [marker],
                              );
                            },
                            child: const Text("GeoJson"),
                          ),
                        ],
                      ),
                      Text(
                        "Geometry",
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Wrap(
                        spacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed: () {
                              var polyline = Longdo.LongdoObject(
                                "Polyline",
                                args: [
                                  [
                                    {"lon": 100, "lat": 14},
                                    {"lon": 101, "lat": 15},
                                    {"lon": 102, "lat": 14},
                                  ],
                                  {
                                    "title": "Polyline",
                                    "detail": "-",
                                    "label": "Polyline",
                                    "lineWidth": 4,
                                    "lineColor": "rgba(255, 0, 0, 0.8)",
                                  },
                                ],
                              );
                              map.currentState?.call(
                                "Overlays.add",
                                args: [polyline],
                              );
                            },
                            child: const Text("Polyline"),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              var dashline = Longdo.LongdoObject(
                                "Polyline",
                                args: [
                                  [
                                    {"lon": 99, "lat": 14},
                                    {"lon": 100, "lat": 15},
                                    {"lon": 101, "lat": 14},
                                  ],
                                  {
                                    "title": "Dashline",
                                    "detail": "-",
                                    "label": "Dashline",
                                    "lineWidth": 4,
                                    "lineColor": "rgba(255, 0, 0, 0.8)",
                                    "lineStyle": map.currentState?.LongdoStatic(
                                      "LineStyle",
                                      "Dashed",
                                    ),
                                    "pointer": true,
                                  },
                                ],
                              );
                              map.currentState?.call(
                                "Overlays.add",
                                args: [dashline],
                              );
                            },
                            child: const Text("Dashline"),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              var polygon = Longdo.LongdoObject(
                                "Polygon",
                                args: [
                                  [
                                    {"lon": 99, "lat": 14},
                                    {"lon": 100, "lat": 13},
                                    {"lon": 102, "lat": 13},
                                    {"lon": 103, "lat": 14},
                                  ],
                                  {
                                    "title": "Polygon",
                                    "detail": "-",
                                    "label": "Polygon",
                                    "lineWidth": 2,
                                    "lineColor": "rgba(0, 0, 0, 1)",
                                    "fillColor": "rgba(255, 0, 0, 0.4)",
                                    "visibleRange": {"min": 5, "max": 18},
                                    "editable": true,
                                    "weight": map.currentState?.LongdoStatic(
                                      "OverlayWeight",
                                      "Top",
                                    ),
                                  },
                                ],
                              );
                              map.currentState?.call(
                                "Overlays.add",
                                args: [polygon],
                              );
                            },
                            child: const Text("Polygon"),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              var circle = Longdo.LongdoObject(
                                "Circle",
                                args: [
                                  {"lon": 101, "lat": 15},
                                  1,
                                  {
                                    "title": "Geom 3",
                                    "detail": "-",
                                    "lineWidth": 2,
                                    "lineColor": "rgba(255, 0, 0, 0.8)",
                                    "fillColor": "rgba(255, 0, 0, 0.4)",
                                  },
                                ],
                              );
                              map.currentState?.call(
                                "Overlays.add",
                                args: [circle],
                              );
                            },
                            child: const Text("Circle"),
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed: () {
                              var dot = Longdo.LongdoObject(
                                "Dot",
                                args: [
                                  {"lon": 100.540574, "lat": 13.714765},
                                  {"lineWidth": 20, "draggable": true},
                                ],
                              );
                              map.currentState?.call(
                                "Overlays.add",
                                args: [dot],
                              );
                            },
                            child: const Text("Dot"),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              var donut = Longdo.LongdoObject(
                                "Polygon",
                                args: [
                                  [
                                    {"lon": 101, "lat": 15},
                                    {"lon": 105, "lat": 15},
                                    {"lon": 103, "lat": 12},
                                    null,
                                    {"lon": 103, "lat": 14.9},
                                    {"lon": 102.1, "lat": 13.5},
                                    {"lon": 103.9, "lat": 13.5},
                                  ],
                                  {"lon": 100.540574, "lat": 13.714765},
                                  {"label": true, "clickable": true},
                                ],
                              );
                              map.currentState?.call(
                                "Overlays.add",
                                args: [donut],
                              );
                            },
                            child: const Text("Donut"),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              var rectangle = Longdo.LongdoObject(
                                "Rectangle",
                                args: [
                                  {"lon": 100.617, "lat": 13.896},
                                  {"width": 2, "height": 1},
                                  {"editable": true},
                                ],
                              );
                              map.currentState?.call(
                                "Overlays.add",
                                args: [rectangle],
                              );
                            },
                            child: const Text("Rectangle"),
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed: () async {
                              var polygon = Longdo.LongdoObject(
                                "Polygon",
                                args: [
                                  [
                                    {"lon": 99, "lat": 14},
                                    {"lon": 100, "lat": 13},
                                    {"lon": 102, "lat": 13},
                                    {"lon": 103, "lat": 14},
                                  ],
                                ],
                              );
                              var result = await map.currentState?.objectCall(
                                polygon,
                                "size",
                                args: ["en"],
                              );
                              print("size of polygon is $result");
                            },
                            child: const Text("Geometry Area"),
                          ),
                          OutlinedButton(
                            onPressed: () async {
                              var polyline = Longdo.LongdoObject(
                                "Polyline",
                                args: [
                                  [
                                    {"lon": 100, "lat": 14},
                                    {"lon": 101, "lat": 15},
                                    {"lon": 102, "lat": 14},
                                  ],
                                  {
                                    "title": "Polyline",
                                    "detail": '-',
                                    "label": "Polyline",
                                    "lineWidth": 4,
                                    "lineColor": "rgba(255, 0, 0, 0.8)",
                                  },
                                ],
                              );
                              var result = await map.currentState?.objectCall(
                                polyline,
                                "size",
                                args: ["en"],
                              );
                              print("length of polyline is $result");
                            },
                            child: const Text("Format Distance Polyline"),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Routing",
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Wrap(
                            spacing: 8.0,
                            children: [
                              OutlinedButton(
                                onPressed: () {
                                  var addSourceJS = """
                              map.Renderer.loadImage(
                                      'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1c/Truck_font_awesome.svg/640px-Truck_font_awesome.svg.png',
                                      (error, image) => {
                                        map.Renderer.addImage('truck', image);
                                      }
                                    );
                                    // Add a source and layer displaying a point which will be animated in a circle.
                                    map.Renderer.addSource('route', {
                                'type': 'geojson',
                                'data': {
                                  'type': 'FeatureCollection',
                                  'features': []
                                }
                              });

                                    map.Renderer.addSource('point', {
                                'type': 'geojson',
                                'data': {
                                  'type': 'FeatureCollection',
                                  'features': []
                                }
                              });
                              """;

                                  if (!isAddSourceAnimatedRouting) {
                                    map.currentState?.run(addSourceJS);
                                  }

                                  var animateFunction = """
                              let animation;
                              function animateRouting(event) {
                                var point = {
                                      type: 'FeatureCollection',
                                      features: [
                                        {
                                          type: 'Feature',
                                          properties: {},
                                          geometry: {
                                            type: 'Point',
                                            coordinates: event[0].path[0]._geojson.geometry.coordinates[0]
                                          }
                                        }
                                      ]
                              };
                                var path = event[0].path;
                                var pathGeoJSON = {
                                  type: 'FeatureCollection',
                                  features: path.map((x) => {
                                    return x._geojson;
                                  })
                                };
                                
                                map.Renderer.getSource('point').setData(point);
                                map.Renderer.getSource('route').setData(pathGeoJSON);
                                
                                
                                var in_path_counter = 0;
                                var path_counter = 0;
                                function animate() {
                                    point.features[0].geometry.coordinates =
                                      pathGeoJSON.features[path_counter].geometry.coordinates[
                                      in_path_counter
                                      ];
                                    map.Renderer.getSource('point').setData(point);

                                    const pathLength =
                                      pathGeoJSON.features[path_counter].geometry.coordinates.length;
                                    if (in_path_counter >= pathLength - 1) {
                                      path_counter++;
                                      in_path_counter = 0;
                                    } else {
                                      in_path_counter++;
                                    }

                                    // Request the next frame of animation so long the end has not been reached.
                                    if (path_counter < pathGeoJSON.features.length - 1) {
                                      //dont use last one เพราะว่ามันเป็น path เส้นประเชื่อมจุด start กับ path ที่แนะนำอันแรก
                                      //อันก่อนท้ายเป็น path ที่เป็นเส้นประไป marker ที่เป็น destination
                                      animation = requestAnimationFrame(animate);
                                    } else {
                                      pathGeoJSON.features[path_counter - 1].geometry.coordinates;
                                    }
                                  }
                                animate();
                              }
                              """;
                                  if (!isAddSourceAnimatedRouting) {
                                    map.currentState?.run(animateFunction);
                                    isAddSourceAnimatedRouting = true;
                                  }
                                },
                                child: const Text("init animated routing"),
                              ),
                              OutlinedButton(
                                onPressed: () {
                                  const bindAnimate = """
                              map.Event.bind('pathComplete', animateRouting );
                              var point = {
                                  'type': 'FeatureCollection',
                                  'features': []
                              }
                              map.Renderer.getSource('point').setData(point);
                                map.Renderer.addLayer({
                                      id: 'point',
                                      source: 'point',
                                      type: 'symbol',
                                      layout: {
                                        'icon-image': 'truck',
                                        'icon-rotate': ['get', 'bearing'],
                                        'icon-rotation-alignment': 'map',
                                        'icon-overlap': 'always',
                                        'icon-ignore-placement': true,
                                        'icon-size': 0.1
                                      }
                            });""";
                                  map.currentState?.run(bindAnimate);
                                },
                                child: const Text("enable animate routing"),
                              ),
                              OutlinedButton(
                                onPressed: () {
                                  const unbindAnimate = """
                              map.Renderer.removeLayer('point');
                              cancelAnimationFrame(animation);
                              map.Event.unbind('pathComplete', animateRouting );
                            """;
                                  map.currentState?.run(unbindAnimate);
                                },
                                child: const Text("disable animate routing"),
                              ),
                              OutlinedButton(
                                onPressed: () async {
                                  var start = {"lon": 101.2, "lat": 12.8};
                                  var end = {"lon": 99.5, "lat": 13.2};
                                  map.currentState?.call(
                                    "Route.clear",
                                    args: [],
                                  );
                                  map.currentState?.call(
                                    "Route.add",
                                    args: [start],
                                  );
                                  map.currentState?.call(
                                    "Route.add",
                                    args: [end],
                                  );
                                  map.currentState?.call(
                                    "Route.search",
                                    args: [],
                                  );
                                },
                                child: const Text("Routing"),
                              ),
                              OutlinedButton(
                                onPressed: () {
                                  map.currentState?.call(
                                    "Route.clear",
                                    args: [],
                                  );
                                },
                                child: const Text("Clear Routing"),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Ui.Components",
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Wrap(
                            spacing: 8.0,
                            children:
                                [
                                      "DPad",
                                      "Zoombar",
                                      "Toolbar",
                                      "LayerSelector",
                                      "Fullscreen",
                                      "Scale",
                                      "ContextMenu",
                                      "Keyboard",
                                      "Mouse",
                                      "Crosshair",
                                      "Cursor",
                                      "Terrain",
                                      "Toast",
                                      "Tooltip",
                                    ]
                                    .map(
                                      (it) => OutlinedButton(
                                        onPressed: () {
                                          map.currentState?.call(
                                            "Ui.$it.visible",
                                            args: [false],
                                          );
                                        },
                                        child: Text(it),
                                      ),
                                    )
                                    .toList(),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Map",
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Wrap(
                            spacing: 8.0,
                            children: [
                              OutlinedButton(
                                onPressed: () {
                                  const location = {
                                    "lon": 100.5384,
                                    "lat": 13.7649,
                                  };
                                  map.currentState?.call(
                                    "location",
                                    args: [location],
                                  );
                                },
                                child: const Text("Victory Monument"),
                              ),
                              OutlinedButton(
                                onPressed: () {
                                  map.currentState?.call(
                                    "zoom",
                                    args: [true, true],
                                  );
                                },
                                child: const Text("Zoom In"),
                              ),
                              OutlinedButton(
                                onPressed: () {
                                  map.currentState?.call(
                                    "zoom",
                                    args: [10, true],
                                  );
                                },
                                child: const Text("Zoom 10"),
                              ),
                              OutlinedButton(
                                onPressed: () {
                                  map.currentState?.call(
                                    "zoom",
                                    args: [false, true],
                                  );
                                },
                                child: const Text("Zoom Out"),
                              ),
                              OutlinedButton(
                                onPressed: () {
                                  map.currentState?.call(
                                    "zoomRange",
                                    args: [
                                      {"min": 5, "max": 10},
                                    ],
                                  );
                                },
                                child: const Text("Zoom range 5-10"),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "RunJS",
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Wrap(
                            spacing: 8.0,
                            children: [
                              OutlinedButton(
                                onPressed: () {
                                  map.currentState?.run(
                                    '''
                                      map.Layers.add(longdo.Layers.TRAFFIC);''',
                                  );
                                },
                                child: const Text("Add Traffic layer"),
                              ),
                              OutlinedButton(
                                onPressed: () async {
                                  map.currentState?.run(
                                    '''map.location({ lon:100, lat:16 }, true);''',
                                  );
                                },
                                child: const Text("Move to 100,16"),
                              ),
                              OutlinedButton(
                                onPressed: () async {
                                  map.currentState?.run(
                                    '''map.Layers.setBase(longdo.Layers.POLITICAL);''',
                                  );
                                },
                                child: const Text("​Change base to Political"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
