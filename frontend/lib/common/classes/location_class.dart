import '../../common/parse_service.dart';

class LocationClass {
  ParseService _parseService = ParseService();

  String type = "Point";
  List<double> coordinates = [];

  LocationClass(this.type, this.coordinates);
  LocationClass.fromJson(Map<String, dynamic> json) {
    this.type = json.containsKey('type') ? json['type'] : 'Point';
    this.coordinates = json['coordinates'] != null ? _parseService.doubleList(json['coordinates']) : [];
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'coordinates': coordinates,
  };
}