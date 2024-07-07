import '../../common/parse_service.dart';

class UserNeighborhoodWeeklyUpdateClass {
  ParseService _parseService = ParseService();

  String id = '', userId = '', neighborhoodUName = '', start = '', end = '';
  int inviteCount = 0, attendedCount = 0;
  int eventsAttendedCount = 0;

  UserNeighborhoodWeeklyUpdateClass(this.id, this.userId, this.neighborhoodUName, this.start, this.end,
    this.inviteCount, this.attendedCount, this.eventsAttendedCount);

  UserNeighborhoodWeeklyUpdateClass.fromJson(Map<String, dynamic> json) {
    this.id = json.containsKey('_id') ? json['_id'] : json.containsKey('id') ? json['id'] : '';
    this.userId = json['userId'] ?? '';
    this.neighborhoodUName = json['neighborhoodUName'] ?? '';
    this.start = json['start'] ?? '';
    this.end = json['end'] ?? '';
    this.inviteCount = json['inviteCount'] != null ? _parseService.toIntNoNull(json['inviteCount']) : 0;
    this.attendedCount = json['attendedCount'] != null ? _parseService.toIntNoNull(json['attendedCount']) : 0;
    this.eventsAttendedCount = json['eventsAttendedCount'] != null ? _parseService.toIntNoNull(json['eventsAttendedCount']) : 0;
  }

  Map<String, dynamic> toJson() =>
    {
      '_id': id,
      'userId': userId,
      'neighborhoodUName': neighborhoodUName,
      'start': start,
      'end': end,
      'inviteCount': inviteCount,
      'attendedCount': attendedCount,
    };
}
