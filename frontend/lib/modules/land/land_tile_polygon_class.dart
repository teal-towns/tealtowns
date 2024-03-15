import '../../common/parse_service.dart';

class LandTilePolygonClass {
  ParseService _parseService = ParseService();

  String id = '', landTileId = '', uName = '', posCenter = '', type = '', shape = '', pairsString = '',
    parentUName = '', source = '', sourceType = '', notes = '';
  List<String> vertices = [], childUNames = [];
  double squareMeters = 0, verticesBuffer = 0, averageChildDiameter = 0, confidencePercent = 0;
  List<List<double>> verticesPixels = [];
  List<double> posCenterPixels = [];

  LandTilePolygonClass(this.id, this.landTileId, this.uName, this.posCenter, this.type, this.shape, this.pairsString,
    this.parentUName, this.source, this.sourceType, this.notes, this.vertices, this.childUNames, this.squareMeters,
    this.verticesBuffer, this.averageChildDiameter, this.confidencePercent, this.verticesPixels, this.posCenterPixels);

  LandTilePolygonClass.fromJson(Map<String, dynamic> json) {
    this.id = json.containsKey('_id') ? json['_id'] : json.containsKey('id') ? json['id'] : '';
    this.landTileId = json['title'] ?? '';
    this.uName = json['uName'] ?? '';
    this.posCenter = json['posCenter'] ?? '';
    this.type = json['type'] ?? '';
    this.shape = json['shape'] ?? '';
    this.pairsString = json['pairsString'] ?? '';
    this.parentUName = json['parentUName'] ?? '';
    this.source = json['source'] ?? '';
    this.sourceType = json['sourceType'] ?? '';
    this.notes = json['notes'] ?? '';
    this.vertices = _parseService.parseListString(json['vertices'] != null ? json['vertices'] : []);
    this.childUNames = _parseService.parseListString(json['childUNames'] != null ? json['childUNames'] : []);
    this.squareMeters = json['squareMeters'] != null ? _parseService.toDoubleNoNull(json['squareMeters']) : 0;
    this.verticesBuffer = json['verticesBuffer'] != null ? _parseService.toDoubleNoNull(json['verticesBuffer']) : 0;
    this.averageChildDiameter = json['averageChildDiameter'] != null ? _parseService.toDoubleNoNull(json['averageChildDiameter']) : 0;
    this.confidencePercent = json['confidencePercent'] != null ? _parseService.toDoubleNoNull(json['confidencePercent']) : 0;

    this.verticesPixels = [];
    this.posCenterPixels = [];
  }

  Map<String, dynamic> toJson() =>
    {
      '_id': id,
      'id': id,
      'landTileId': landTileId,
      'uName': uName,
      'posCenter': posCenter,
      'type': type,
      'shape': shape,
      'pairsString': pairsString,
      'parentUName': parentUName,
      'source': source,
      'sourceType': sourceType,
      'notes': notes,
      'vertices': vertices,
      'childUNames': childUNames,
      'squareMeters': squareMeters,
      'verticesBuffer': verticesBuffer,
      'averageChildDiameter': averageChildDiameter,
      'confidencePercent': confidencePercent
    };
}
