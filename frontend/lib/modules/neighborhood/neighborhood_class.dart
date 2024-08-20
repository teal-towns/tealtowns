import '../../common/classes/location_class.dart';
import '../../common/parse_service.dart';

class NeighborhoodClass {
  ParseService _parseService = ParseService();

  String id = '', uName = '', title = '', timezone = '';
  LocationClass location = LocationClass.fromJson({});
  Map<String, dynamic> locationAddress = {};
  double location_DistanceKm = 0;
  Map<String, dynamic> userNeighborhood = {};

  NeighborhoodClass(this.id, this.uName, this.title, this.timezone, this.location, this.locationAddress,
    this.location_DistanceKm, this.userNeighborhood);

  NeighborhoodClass.fromJson(Map<String, dynamic> json) {
    this.id = json.containsKey('_id') ? json['_id'] : json.containsKey('id') ? json['id'] : '';
    this.uName = json['uName'] ?? '';
    this.title = json['title'] ?? '';
    this.timezone = json['timezone'] ?? '';
    this.location = LocationClass.fromJson(json['location'] ?? {});
    this.locationAddress = json['locationAddress'] ?? {};
    this.location_DistanceKm = json.containsKey('location_DistanceKm') ? _parseService.toDoubleNoNull(json['location_DistanceKm']) : 0;
    this.userNeighborhood = json['userNeighborhood'] ?? {};
  }

  Map<String, dynamic> toJson() =>
    {
      '_id': id,
      'uName': uName,
      'title': title,
      'timezone': timezone,
      'location': { 'type': 'Point', 'coordinates': location.coordinates },
      'locationAddress': locationAddress,
    };
}
