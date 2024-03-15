import '../../common/parse_service.dart';

class LandTilePolygonService {
  LandTilePolygonService._privateConstructor();
  static final LandTilePolygonService _instance = LandTilePolygonService._privateConstructor();
  factory LandTilePolygonService() {
    return _instance;
  }

  ParseService _parseService = ParseService();

  List<List<double>> VerticesMetersToPixels(List<String> vertices, double tileXMeters, double tileYMeters,
    double tileXPixels, double tileYPixels) {
    List<List<double>> verticesXY = [];
    for (String vertex in vertices) {
      double x = _parseService.toDoubleNoNull(vertex.split(',')[0]) / tileXMeters * tileXPixels;
      double y = _parseService.toDoubleNoNull(vertex.split(',')[1]) / tileYMeters * tileYPixels;
      verticesXY.add([x, y]);
    }
    return verticesXY;
  }

  List<String> VerticesPixelsToMeters(List<List<double>> verticesPixels, double tileXMeters, double tileYMeters,
    double tileXPixels, double tileYPixels) {
    List<String> vertices = [];
    for (List<double> vertexPixel in verticesPixels) {
      // TODO - get height (elevation).
      vertices.add('${vertexPixel[0] * tileXMeters / tileXPixels},${vertexPixel[1] * tileYMeters / tileYPixels},0.0');
    }
    return vertices;
  }

  List<double> VertexMetersToPixels(String vertex, double tileXMeters, double tileYMeters,
    double tileXPixels, double tileYPixels) {
    double x = _parseService.toDoubleNoNull(vertex.split(',')[0]) / tileXMeters * tileXPixels;
    double y = _parseService.toDoubleNoNull(vertex.split(',')[1]) / tileYMeters * tileXPixels;
    return [x, y];
  }

  String VertexPixelsToMeters(List<double> vertexPixel, double tileXMeters, double tileYMeters,
    double tileXPixels, double tileYPixels) {
    // TODO - get height (elevation).
    return '${vertexPixel[0] * tileXMeters / tileXPixels},${vertexPixel[1] * tileYMeters / tileYPixels},0.0';
  }
}