import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../link_service.dart';
import '../lodash_service.dart';
import '../parse_service.dart';

class MapIt extends StatefulWidget {
  double mapWidth;
  double mapHeight;
  Function(Map<String, dynamic>)? onChange;
  int debounceChange;
  double latitude;
  double longitude;
  double zoom;
  List<double> markerLngLat;
  String markerImage;
  // TODO?
  // var polygons = [];
  // var coordinatesDraw;

  MapIt({ this.mapHeight = 300, this.mapWidth = 300,
    this.onChange = null, this.debounceChange = 1000, this.latitude = 0,
    this.longitude = 0, this.zoom = 13.0, this.markerLngLat = const [],
    this.markerImage = 'assets/images/map-marker.png' });

  @override
  _MapItState createState() => _MapItState();
}

class _MapItState extends State<MapIt> {
  LinkService _linkService = LinkService();
  LodashService _lodashService = LodashService();
  ParseService _parseService = ParseService();

  bool _zoomInited = false;
  double _latitude = 0;
  double _longitude = 0;
  Timer? _debounceOnChange = null;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.latitude != _latitude || widget.longitude != _longitude) {
      _latitude = widget.latitude;
      _longitude = widget.longitude;
      // _checkUpdateLocation();
    }

    double height = widget.mapHeight;
    LatLng center = LatLng(widget.latitude, widget.longitude);
    List<Marker> markers = [];
    if (widget.markerLngLat.length > 0) {
      markers.add(
        Marker(
          point: LatLng(widget.markerLngLat[1], widget.markerLngLat[0]),
          width: 80,
          height: 80,
          // child: FlutterLogo(),
          child: Image.asset(widget.markerImage),
        )
      );
    }

    return Container(
      width: widget.mapWidth,
      height: height,
      child: FlutterMap(
        options: MapOptions(
          initialCenter: center,
          initialZoom: widget.zoom,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.app',
          ),
          RichAttributionWidget(
            attributions: [
              TextSourceAttribution(
                'OpenStreetMap contributors',
                // onTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright')),
                onTap: () => _linkService.LaunchURL('https://openstreetmap.org/copyright'),
              ),
            ],
          ),
          MarkerLayer(
            markers: markers,
          ),
        ],
      )
    );
  }

}
