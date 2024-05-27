import '../../common/parse_service.dart';

class NeighborhoodGroupClass {
  ParseService _parseService = ParseService();

  String id = '', uName = '';
  List<String> neighborhoodUNames = [];

  NeighborhoodGroupClass(this.id, this.uName, this.neighborhoodUNames);

  NeighborhoodGroupClass.fromJson(Map<String, dynamic> json) {
    this.id = json.containsKey('_id') ? json['_id'] : json.containsKey('id') ? json['id'] : '';
    this.uName = json['uName'] ?? '';
    this.neighborhoodUNames = json.containsKey('neighborhoodUNames') ? _parseService.parseListString(json['neighborhoodUNames']) : [];
  }

  Map<String, dynamic> toJson() =>
    {
      '_id': id,
      'uName': uName,
      'neighborhoodUNames': neighborhoodUNames,
    };
}
