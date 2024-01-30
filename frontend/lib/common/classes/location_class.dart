import '../../common/parse_service.dart';

class LocationClass {
  ParseService _parseService = ParseService();

  String type = "Point";
  List<double> coordinates = [0,0];

  LocationClass(this.type, this.coordinates);
  LocationClass.fromJson(Map<String, dynamic> json) {
    this.type = json.containsKey('type') ? json['type'] : 'Point';
    this.coordinates = (json['coordinates'] != null && json['coordinates'].length == 2) ? _parseService.doubleList(json['coordinates']) : [0,0];
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'coordinates': coordinates,
  };
}