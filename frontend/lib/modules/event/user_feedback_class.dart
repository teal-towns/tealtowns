import '../../common/parse_service.dart';

class UserFeedbackClass {
  ParseService _parseService = ParseService();

  String id = '', userId = '', forType = '', forId = '', attended = '', willJoinNextWeek = '', willInvite = '';
  int stars = 0;
  List<String> invites = [];

  UserFeedbackClass(this.id, this.userId, this.forType, this.forId, this.attended,
    this.willJoinNextWeek, this.willInvite, this.stars, this.invites);

  UserFeedbackClass.fromJson(Map<String, dynamic> json) {
    this.id = json.containsKey('_id') ? json['_id'] : json.containsKey('id') ? json['id'] : '';
    this.userId = json['userId'] ?? '';
    this.forType = json['forType'] ?? '';
    this.forId = json['forId'] ?? '';
    this.attended = json['attended'] ?? '';
    this.willJoinNextWeek = json['willJoinNextWeek'] ?? '';
    this.willInvite = json['willInvite'] ?? '';
    this.stars = _parseService.toIntNoNull(json['stars']) ?? 0;
    this.invites = json.containsKey('invites') ? _parseService.parseListString(json['invites']) : [];
  }

  Map<String, dynamic> toJson() =>
    {
      '_id': id,
      'userId': userId,
      'forType': forType,
      'forId': forId,
      'attended': attended,
      'willJoinNextWeek': willJoinNextWeek,
      'willInvite': willInvite,
      'stars': stars,
      'invites': invites,
    };
}
