import '../../common/parse_service.dart';

class UserWeeklyEventClass {
  ParseService _parseService = ParseService();

  String id = '', weeklyEventId = '', userId = '';
  int attendeeCountAsk = 0;

  UserWeeklyEventClass(this.id, this.weeklyEventId, this.userId, this.attendeeCountAsk);

  UserWeeklyEventClass.fromJson(Map<String, dynamic> json) {
    this.id = json.containsKey('_id') ? json['_id'] : json.containsKey('id') ? json['id'] : '';
    this.weeklyEventId = json['weeklyEventId'] ?? '';
    this.userId = json['userId'] ?? '';
    this.attendeeCountAsk = json['attendeeCountAsk'] != null ? _parseService.toIntNoNull(json['attendeeCountAsk']) : 0;
  }

  Map<String, dynamic> toJson() =>
    {
      '_id': id,
      'weeklyEventId': weeklyEventId,
      'userId': userId,
      'attendeeCountAsk': attendeeCountAsk,
    };
}
