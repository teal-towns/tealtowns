import '../../common/classes/location_class.dart';
import '../../common/parse_service.dart';

class NeighborhoodClass {
  ParseService _parseService = ParseService();

  String id = '', uName = '', title = '';
  LocationClass location = LocationClass.fromJson({});
  double location_DistanceKm = 0;

  NeighborhoodClass(this.id, this.uName, this.title, this.location, this.location_DistanceKm);

  NeighborhoodClass.fromJson(Map<String, dynamic> json) {
    this.id = json.containsKey('_id') ? json['_id'] : json.containsKey('id') ? json['id'] : '';
    this.uName = json['uName'] ?? '';
    this.title = json['title'] ?? '';
    this.location = LocationClass.fromJson(json['location'] ?? {});
    this.location_DistanceKm = json.containsKey('location_DistanceKm') ? _parseService.toDoubleNoNull(json['location_DistanceKm']) : 0;
  }

  Map<String, dynamic> toJson() =>
    {
      '_id': id,
      'uName': uName,
      'title': title,
      'location': { 'type': 'Point', 'coordinates': location.coordinates },
    };
}
