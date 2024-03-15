import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../../common/parse_service.dart';
import '../../common/socket_service.dart';
import './land_tile_polygon_class.dart';
import './land_tile_polygon_service.dart';

class LandTilePolygon extends StatefulWidget {
    String landTileId;
    double tileXMeters;
    double tileYMeters;
    double tileXPixels;
    double tileYPixels;
    String typesString;
    String shapesString;
    double strokeWidth;

    LandTilePolygon({ required this.landTileId, required this.tileXMeters, required this.tileYMeters,
      required this.tileXPixels, required this.tileYPixels,
      this.typesString = '', this.shapesString = '', this.strokeWidth = 5, });

@override
  _LandTilePolygonState createState() => _LandTilePolygonState();
}

class _LandTilePolygonState extends State<LandTilePolygon> {
  List<String> _routeIds = [];
  ParseService _parseService = ParseService();
  SocketService _socketService = SocketService();
  LandTilePolygonService _landTilePolygonService = LandTilePolygonService();

  List<LandTilePolygonClass> _landTilePolygons = [];
  bool _loading = true;
  String _landTileId = '';
  
  @override
  void initState() {
    super.initState();

    _routeIds.add(_socketService.onRoute('GetLandTilePolygon', callback: (String resString) {
      var res = jsonDecode(resString);
      var data = res['data'];
      if (data['valid'] == 1 && data['landTileId'] == widget.landTileId) {
        _landTilePolygons = [];
        for (var item in data['landTilePolygons']) {
          LandTilePolygonClass polygon = LandTilePolygonClass.fromJson(item);
          polygon.verticesPixels = _landTilePolygonService.VerticesMetersToPixels(polygon.vertices,
            widget.tileXMeters, widget.tileYMeters, widget.tileXPixels, widget.tileYPixels);
          polygon.posCenterPixels = _landTilePolygonService.VertexMetersToPixels(polygon.posCenter,
            widget.tileXMeters, widget.tileYMeters, widget.tileXPixels, widget.tileYPixels);
          _landTilePolygons.add(polygon);
        }
        setState(() {
          _landTilePolygons = _landTilePolygons;
        });
      }
    }));

    GetPolygons();
  }

  @override
  void dispose() {
    _socketService.offRouteIds(_routeIds,);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.landTileId != _landTileId) {
      _landTileId = widget.landTileId;
      GetPolygons();
    }
    // return SizedBox.shrink();
    return _drawPolygons(context);
  }

  void GetPolygons() {
    var data = { 'landTileId': widget.landTileId, 'typesString': widget.typesString,
      'shapesString': widget.shapesString, };
    _socketService.emit('GetLandTilePolygon', data);
  }

  Widget _drawPolygons(BuildContext context) {
    return CustomPaint(
      painter: PolygonPainter(context, _landTilePolygons, widget.strokeWidth),
    );
  }
}

class PolygonPainter extends CustomPainter {
  final BuildContext context;
  List<LandTilePolygonClass> landTilePolygons;
  double strokeWidth;
  PolygonPainter(this.context, this.landTilePolygons, this.strokeWidth);

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    // print ('oldDelegate ${oldDelegate} ${this.landTilePolygons.length}');
    // return false;
    return true;
  }

  @override
  void paint(Canvas canvas, Size size) {
    Map<String, Color> colorMap = {
      'tree': Colors.green,
      'building': Colors.brown,
    };
    for (LandTilePolygonClass polygon in landTilePolygons) {
      List<Offset> pointsCenter = [];
      Color color = colorMap[polygon.type] ?? Colors.black;
      pointsCenter.add(Offset(polygon.posCenterPixels[0], polygon.posCenterPixels[1]));
      // if (polygon.shape == 'point') {
        // points.add(Offset(polygon.verticesPixels[0][0], polygon.verticesPixels[0][1]));
      // } else {
      if (polygon.shape != 'point') {
        List<Offset> pointsTemp = [];
        for (List<double> vertex in polygon.verticesPixels) {
          pointsTemp.add(Offset(vertex[0], vertex[1]));
        }
        // Draw lines
        Paint paint = Paint()..color = color..strokeWidth = strokeWidth..strokeCap = StrokeCap.round;
        canvas.drawPoints(ui.PointMode.polygon, pointsTemp, paint);
        // Draw vertices
        paint = Paint()..color = color..strokeWidth = strokeWidth * 2;
        canvas.drawPoints(ui.PointMode.points, pointsTemp, paint);
      }
      final paint = Paint()..color = color..strokeWidth = strokeWidth * 3;
      canvas.drawPoints(ui.PointMode.points, pointsCenter, paint);
    }
  }
}
