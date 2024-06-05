import '../../common/parse_service.dart';

class EventInsightClass {
  ParseService _parseService = ParseService();

  String id = '', eventId = '';
  List<String> viewsAt = [];

  EventInsightClass(this.id, this.eventId, this.viewsAt);

  EventInsightClass.fromJson(Map<String, dynamic> json) {
    this.id = json.containsKey('_id') ? json['_id'] : json.containsKey('id') ? json['id'] : '';
    this.eventId = json['eventId'] ?? '';
    this.viewsAt = json.containsKey('viewsAt') ? _parseService.parseListString(json['viewsAt']) : [];
  }

  Map<String, dynamic> toJson() =>
    {
      '_id': id,
      'eventId': eventId,
      'viewsAt': viewsAt,
    };
}
