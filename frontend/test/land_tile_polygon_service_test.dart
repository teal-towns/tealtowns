import 'package:test/test.dart';

import '../lib/modules/land/land_tile_polygon_service.dart';

void main() {
  test('LandTilePolygonService.VerticesMetersToPixels', () {
    final service = LandTilePolygonService();
    double xMeters = 100;
    double yMeters = 50;
    double xPixels = 100;
    double yPixels = 100;
    List<String> vertices = ['0.0,0.0,0.0', '0.0,50.0,0.0', '100.0,25.0,0.0'];
    List<List<double>> pixels = [[0, 0], [0, 100], [100, 50]];
    expect(service.VerticesMetersToPixels(vertices, xMeters, yMeters, xPixels, yPixels), pixels);
  });

  test('LandTilePolygonService.VerticesPixelsToMeters', () {
    final service = LandTilePolygonService();
    double xMeters = 100;
    double yMeters = 50;
    double xPixels = 100;
    double yPixels = 100;
    List<String> vertices = ['0.0,0.0,0.0', '0.0,50.0,0.0', '100.0,25.0,0.0'];
    List<List<double>> pixels = [[0, 0], [0, 100], [100, 50]];
    expect(service.VerticesPixelsToMeters(pixels, xMeters, yMeters, xPixels, yPixels), vertices);
  });

  test('LandTilePolygonService.VertexMetersToPixels', () {
    final service = LandTilePolygonService();
    double xMeters = 100;
    double yMeters = 50;
    double xPixels = 100;
    double yPixels = 100;
    expect(service.VertexMetersToPixels('0.0,0.0,0.0', xMeters, yMeters, xPixels, yPixels), [0,0]);
    expect(service.VertexMetersToPixels('0.0,50.0,0.0', xMeters, yMeters, xPixels, yPixels), [0,100]);
    expect(service.VertexMetersToPixels('100.0,25.0,0.0', xMeters, yMeters, xPixels, yPixels), [100,50]);
  });

  test('LandTilePolygonService.VertexPixelsToMeters', () {
    final service = LandTilePolygonService();
    double xMeters = 100;
    double yMeters = 50;
    double xPixels = 100;
    double yPixels = 100;
    expect(service.VertexPixelsToMeters([0,0], xMeters, yMeters, xPixels, yPixels), '0.0,0.0,0.0');
    expect(service.VertexPixelsToMeters([0,100], xMeters, yMeters, xPixels, yPixels), '0.0,50.0,0.0');
    expect(service.VertexPixelsToMeters([100,50], xMeters, yMeters, xPixels, yPixels), '100.0,25.0,0.0');
  });
}