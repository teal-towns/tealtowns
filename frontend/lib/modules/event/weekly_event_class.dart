import '../../common/classes/location_class.dart';
import '../../common/parse_service.dart';
import '../user_auth/user_class.dart';

class WeeklyEventClass {
  ParseService _parseService = ParseService();

  String id = '', title = '', description = '', startTime = '', endTime = '';
  List<String> hostUserIds = [];
  LocationClass location = LocationClass.fromJson({});
  int dayOfWeek = 0;
  double xDistanceKm = -999;
  List<UserClass> hostUsers = [];
  String xDay = '';

  WeeklyEventClass(this.id, this.title, this.description, this.startTime, this.endTime, this.hostUserIds,
    this.location, this.dayOfWeek, this.xDistanceKm, this.hostUsers, this.xDay);

  WeeklyEventClass.fromJson(Map<String, dynamic> json) {
    List<String> days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    this.id = json.containsKey('_id') ? json['_id'] : json.containsKey('id') ? json['id'] : '';
    this.title = json['title'] ?? '';
    this.description = json['description'] ?? '';
    this.startTime = json['startTime'] ?? '';
    this.endTime = json['endTime'] ?? '';
    this.hostUserIds = _parseService.parseListString(json['hostUserIds'] != null ? json['hostUserIds'] : []);
    this.location = LocationClass.fromJson(json['location'] ?? {});
    this.dayOfWeek = json['dayOfWeek'] != null ? _parseService.toIntNoNull(json['dayOfWeek']) : 0;
    this.xDay = days[this.dayOfWeek];
    this.xDistanceKm = json.containsKey('xDistanceKm') ? _parseService.toDoubleNoNull(json['xDistanceKm']) : -999;
    this.hostUsers = json.containsKey('hostUsers') ? UserClass.parseUsers(json['hostUsers']) : [];
  }

  Map<String, dynamic> toJson() =>
    {
      '_id': id,
    //   'id': id,
      'title': title,
      'description': description,
      'startTime': startTime,
      'endTime': endTime,
      'hostUserIds': hostUserIds,
      'location': { 'type': 'Point', 'coordinates': location.coordinates },
      'dayOfWeek': dayOfWeek,
    };
}
