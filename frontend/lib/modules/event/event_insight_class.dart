import '../../common/parse_service.dart';

class EventInsightClass {
  ParseService _parseService = ParseService();

  String id = '', eventId = '';
  Map<String, List<String>> uniqueViewsAt = {};

  EventInsightClass(this.id, this.eventId, this.uniqueViewsAt);

  EventInsightClass.fromJson(Map<String, dynamic> json) {
    this.id = json.containsKey('_id') ? json['_id'] : json.containsKey('id') ? json['id'] : '';
    this.eventId = json['eventId'] ?? '';
    this.uniqueViewsAt = json.containsKey('uniqueViewsAt') ?
      _parseService.parseMapStringListString(json['uniqueViewsAt']) : {};
  }

  Map<String, dynamic> toJson() =>
    {
      '_id': id,
      'eventId': eventId,
      'uniqueViewsAt': uniqueViewsAt,
    };
}
