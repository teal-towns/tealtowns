import '../../common/parse_service.dart';

class EventClass {
  ParseService _parseService = ParseService();

  String id = '', weeklyEventId = '', weeklyEventUName = '', start = '', end = '', neighborhoodUName = '';
  Map<String, dynamic> userEventsAttendeeCache = {};

  EventClass(this.id, this.weeklyEventId, this.weeklyEventUName, this.start, this.end, this.neighborhoodUName,
    this.userEventsAttendeeCache);

  EventClass.fromJson(Map<String, dynamic> json) {
    this.id = json.containsKey('_id') ? json['_id'] : json.containsKey('id') ? json['id'] : '';
    this.weeklyEventId = json['weeklyEventId'] ?? '';
    this.weeklyEventUName = json['weeklyEventUName'] ?? '';
    this.start = json['start'] ?? '';
    this.end = json['end'] ?? '';
    this.neighborhoodUName = json['neighborhoodUName'] ?? '';
    this.userEventsAttendeeCache = json.containsKey('userEventsAttendeeCache') ?
      _parseService.parseMapStringDynamic(json['userEventsAttendeeCache']) : {};
  }

  Map<String, dynamic> toJson() =>
    {
      '_id': id,
      'weeklyEventId': weeklyEventId,
      'weeklyEventUName': weeklyEventUName,
      'start': start,
      'end': end,
      'neighborhoodUName': neighborhoodUName,
    };
}
