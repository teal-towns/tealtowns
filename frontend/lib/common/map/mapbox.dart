import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:mapbox_gl/mapbox_gl.dart';

import '../lodash_service.dart';
import '../parse_service.dart';
import './mapbox_draw_service.dart';

class Mapbox extends StatefulWidget {
  var polygons = [];
  double mapWidth;
  double mapHeight;
  Function(Map<String, dynamic>)? onChange;
  int debounceChange;
  double latitude;
  double longitude;
  double zoom;
  var coordinatesDraw;
  List<double> markerLngLat;
  String markerImage;

  Mapbox({ this.polygons = const [], this.mapHeight = 300, this.mapWidth = 300,
    this.onChange = null, this.debounceChange = 1000, this.latitude = 0,
    this.longitude = 0, this.zoom = 13.0, this.coordinatesDraw = const [], this.markerLngLat = const [],
    this.markerImage = 'assets/images/map-marker.png' });

  @override
  _MapboxState createState() => _MapboxState();
}

class _MapboxState extends State<Mapbox> {
  LodashService _lodashService = LodashService();
  MapboxDrawService _mapboxDrawService = MapboxDrawService();
  ParseService _parseService = ParseService();

  bool _zoomInited = false;
  MapboxMap? _map;
  bool _mapReady = false;
  late MapboxMapController _mapController;
  // static CameraPosition _initialPosition = CameraPosition(
  //   target: LatLng(0, 0),
  //   zoom: 13.0,
  // );
  //CameraPosition _position = _initialPosition;

  int _polygonsCount = 0;
  double _latitude = 0;
  double _longitude = 0;
  Timer? _debounceOnChange = null;
  List<String> _drawnSourceIds = [];
  int _coordinatesDrawCount = 0;

  @override
  void initState() {
    super.initState();

    // Not working..
    //CameraPosition _initialPosition = CameraPosition(
    //  target: LatLng(widget.latitude, widget.longitude),
    //  zoom: widget.zoom,
    //);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.polygons.length != _polygonsCount) {
      _polygonsCount = widget.polygons.length;
      if (widget.polygons.length > 0) {
        _checkLoadPolygons();
      }
    }
    if (widget.coordinatesDraw.length != _coordinatesDrawCount) {
      _coordinatesDrawCount = widget.coordinatesDraw.length;
      if (widget.coordinatesDraw.length > 0) {
        _checkDrawCoordinates();
      }
    }
    if (widget.latitude != _latitude || widget.longitude != _longitude) {
      _latitude = widget.latitude;
      _longitude = widget.longitude;
      _checkUpdateLocation();
    }

    CameraPosition initialPosition = CameraPosition(
      target: LatLng(widget.latitude, widget.longitude),
      zoom: widget.zoom,
    );

    double height = widget.mapHeight;
    _map = MapboxMap(
      accessToken: dotenv.env['MAPBOX_ACCESS_TOKEN'],
      styleString: MapboxStyles.SATELLITE,
      onMapCreated: onMapCreated,
      onStyleLoadedCallback: () => onStyleLoaded(),
      initialCameraPosition: initialPosition,
      onMapClick: (point, latLng) async {
        //print ('onMapClick ${latLng}');
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: widget.mapWidth,
          height: height,
          child: _map,
        )
      ]
    );
  }

  void onMapCreated(MapboxMapController controller) {
    _mapController = controller;
    _mapController.addListener(_onMapChanged);
  }

  void _onMapChanged() {
    if (_parseService.Precision(_latitude, 6) != _parseService.Precision(_mapController.cameraPosition!.target.latitude, 6) ||
      _parseService.Precision(_longitude, 6) != _parseService.Precision(_mapController.cameraPosition!.target.longitude, 6)) {
      _latitude = _mapController.cameraPosition!.target.latitude;
      _longitude = _mapController.cameraPosition!.target.longitude;
      if (widget.onChange != null && _mapController.cameraPosition != null) {
        if (widget.debounceChange > 0) {
          if (_debounceOnChange?.isActive ?? false) { _debounceOnChange?.cancel(); };
          _debounceOnChange = Timer(Duration(milliseconds: widget.debounceChange), () {
            _mapChange();
          });
        } else {
          _mapChange();
        }
      }
    }
  }

  void _mapChange() {
    int zoom = -1;
    if (_mapController.cameraPosition!.zoom != null) {
      zoom = _mapController.cameraPosition!.zoom!.floor();
    }
    widget.onChange!({'zoom': zoom, 'latitude': _mapController.cameraPosition!.target.latitude,
      'longitude': _mapController.cameraPosition!.target.longitude });
  }

  void onStyleLoaded() {
    _mapReady = true;
  }

  void _checkLoadPolygons() {
    if (_mapReady) {
      if (widget.polygons.length > 0) {
        _addPolygonsToMap(widget.polygons);
      }
    } else {
      Timer(Duration(milliseconds: 500), () {
        _checkLoadPolygons();
      });
    }
  }

  void _checkDrawCoordinates() {
    if (_mapReady) {
      if (widget.coordinatesDraw.length > 0) {
        _drawCoordinatesOnMap(widget.coordinatesDraw);
      }
    } else {
      Timer(Duration(milliseconds: 500), () {
        _checkDrawCoordinates();
      });
    }
  }

  void _checkUpdateLocation() {
    if (_mapReady) {
      double latitude = widget.latitude;
      double longitude = widget.longitude;
      double zoom = _mapController.cameraPosition!.zoom;
      if (!_zoomInited) {
        zoom = widget.zoom;
        _zoomInited = true;
      }
      _mapController.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(latitude, longitude),
            zoom: zoom,
          ),
        )
      );

      if (widget.markerLngLat.length > 0 && widget.markerLngLat[0] != 0 && widget.markerLngLat[1] != 0) {
        _mapController.addSymbol(
          SymbolOptions(
            geometry: LatLng(widget.markerLngLat[1], widget.markerLngLat[0]),
            iconImage: widget.markerImage,
          ),
        );
      }
    } else {
      Timer(Duration(milliseconds: 500), () {
        _checkUpdateLocation();
      });
    }
  }

  void _drawCoordinatesOnMap(var coordinates) {
    _mapboxDrawService.removeDrawings(_mapController);
    for (int ii = 0; ii < coordinates.length; ii++) {
      _mapboxDrawService.drawPolygon(coordinates[ii], _mapController, colorBorder: 'white', );
    }
  }

  void _addPolygonsToMap(var polygons, { bool animateCamera = false,
    String type = '' }) async {
    for (int pp = 0; pp < polygons.length; pp++) {
      var polygon = polygons[pp];
      String id = 'x_${_lodashService.randomString()}';
      var res = await http.get(Uri.parse(polygon['fileUrl']));
      var data = jsonDecode(res.body);
      // What does adding a source do? It does not draw it, so skip.
      //_addGeoJsonSource(id, data);
      _mapboxDrawService.drawPolygonsFromGeojson(data, _mapController, drawFill: true);
      if (polygon.containsKey('bounds')) {
        _mapController.moveCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: LatLng(polygon['bounds']['min']![1], polygon['bounds']['min']![0]),
              northeast: LatLng(polygon['bounds']['max']![1], polygon['bounds']['max']![0]),
            ),
            left: 10, right: 10, top: 10, bottom: 10,
          ),
        );
      }
    }
  }

  //void _addGeoJsonSource(String id, var sourceData) {
  //  _removeSource(id);
  //  _mapController.addGeoJsonSource(id, sourceData);
  //  if (!_drawnSourceIds.contains(id)) {
  //    _drawnSourceIds.add(id);
  //  }
  //}

  //void _removeSource(String id) {
  //  if (_drawnSourceIds.contains(id)) {
  //    _mapController.removeSource(id);
  //    _drawnSourceIds.remove(id);
  //  }
  //}

  //Map<String, dynamic> _geoJsonDataPolygon(var polygon) {
  //  return {
  //    'type': 'FeatureCollection',
  //    'features': [
  //      {
  //        'type': 'Feature',
  //        'properties': {
  //          // Required or get error.
  //          'name': polygon.name,
  //        },
  //        'geometry': {
  //          'type': 'Polygon',
  //          // coordinates are double nested for some reason.
  //          'coordinates': [ polygon.coordinates ],
  //        },
  //        // Required otherwise get error?
  //        'id': polygon.id.length > 0 ? polygon.id : 'dummy',
  //      }
  //    ],
  //  };
  //}

}
