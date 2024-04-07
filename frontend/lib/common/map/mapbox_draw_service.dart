import 'package:mapbox_gl/mapbox_gl.dart';

import '../colors_service.dart';

class MapboxDrawService {
  MapboxDrawService._privateConstructor();
  static final MapboxDrawService _instance = MapboxDrawService._privateConstructor();
  factory MapboxDrawService() {
    return _instance;
  }

  ColorsService _colorsService = ColorsService();

  List<Line> _lines = [];
  List<Circle> _circles = [];
  List<Fill> _fills = [];

  void removeDrawings(MapboxMapController controller) {
    for (Circle circle in this._circles) {
      controller.removeCircle(circle);
    }
    for (Line line in this._lines) {
      controller.removeLine(line);
    }
    for (Fill fill in this._fills) {
      controller.removeFill(fill!);
    }
    _lines = [];
    _circles = [];
    _fills = [];
  }

  LatLng coordinateToLatLng(coordinate) {
    LatLng latLng = LatLng(
      coordinate[1],
      coordinate[0],
    );
    return latLng;
  }

  Future<Line> drawPolygonEdgeLine(List<LatLng> latLngs, MapboxMapController controller, 
    {String color = 'red', bool addToDrawings = true, }) async {
    Line line = await controller.addLine(
      LineOptions(
        lineBlur: 0,
        lineGapWidth: 0,
        lineOpacity: 1,
        lineWidth: 2,
        lineOffset: 0,
        geometry: latLngs,
        lineColor: _colorsService.colorsStr[color],
      ),
    );
    if (addToDrawings) {
      this._lines.add(line);
    }
    return line;
  }

  Future<Circle> drawPolygonCircle(LatLng latLng, MapboxMapController controller,
    {String color = 'magenta', bool addToDrawings = true, }) async {
    Circle circle = await controller.addCircle(
      CircleOptions(
        geometry: latLng,
        draggable: false,  //TODO: Lines move with vertex when it is dragged
        circleOpacity: 1,
        circleRadius: 8,
        circleBlur: 0,
        circleStrokeOpacity: 0,
        circleStrokeWidth: 0,
        circleColor: _colorsService.colorsStr[color],
        circleStrokeColor: _colorsService.colorsStr[color],
      ),
    );
    if (addToDrawings) {
      this._circles.add(circle);
    }
    return circle;
  }

  Future<Fill> drawPolygonFill(List<List<LatLng>> latLngs, MapboxMapController controller,
    { String color = 'magentaTransparent', bool addToDrawings = true, }) async {
    Fill fill = await controller.addFill(
      FillOptions(
        geometry: latLngs,
        draggable: false,  //TODO: Lines move with vertex when it is dragged
        fillOpacity: 1,
        fillColor: _colorsService.colorsStr[color],
        fillOutlineColor: _colorsService.colorsStr[color],
      ),
    );
    if (addToDrawings) {
      this._fills.add(fill);
    }
    return fill;
  }

  Future<String> drawPolygon(List<dynamic> coordinates, MapboxMapController controller,
    { bool drawFill = false, String colorBorder = 'greyDark', String colorFill = 'greyTransparent',
    bool addToDrawings = true, }) async {
    int count = 0;
    LatLng? prevLatLng = null;
    List<LatLng> latLngs = [];
    for (var coordinate in coordinates) {
      LatLng currentLatLng = coordinateToLatLng(coordinate);
      if (count > 0) {
        Line line = await drawPolygonEdgeLine([prevLatLng!, currentLatLng], controller, color: colorBorder,
          addToDrawings: addToDrawings, );
      }
      prevLatLng = currentLatLng;
      latLngs.add(currentLatLng);
      count += 1;
    }
    if (drawFill) {
      Fill fill = await drawPolygonFill([latLngs], controller, color: colorFill, addToDrawings: addToDrawings, );
    }
    return '';
  }

  Future<String> drawPolygonsFromGeojson(var geojson, MapboxMapController controller,
    { bool drawFill = false, String colorBorder = 'greyDark', String colorFill = 'greyTransparent',
    bool addToDrawings = false, }) async {
    for (int ii = 0; ii < geojson['features'].length; ii++) {
      if (geojson['features'][ii]['geometry']['type'] == 'Polygon') {
        await drawPolygon(geojson['features'][ii]['geometry']['coordinates'][0], controller, drawFill: drawFill,
          colorBorder: colorBorder, colorFill: colorFill, addToDrawings: addToDrawings, );
      }
    }
    return '';
  }
}
