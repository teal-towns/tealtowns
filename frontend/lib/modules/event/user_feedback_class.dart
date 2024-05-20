import '../../common/parse_service.dart';

class UserFeedbackClass {
  ParseService _parseService = ParseService();

  String id = '', userId = '', forType = '', forId = '', willJoinNextWeek = '', willInvite = '';
  List<String> invites = [];

  UserFeedbackClass(this.id, this.userId, this.forType, this.forId, this.willJoinNextWeek, this.willInvite,
    this.invites);

  UserFeedbackClass.fromJson(Map<String, dynamic> json) {
    this.id = json.containsKey('_id') ? json['_id'] : json.containsKey('id') ? json['id'] : '';
    this.userId = json['userId'] ?? '';
    this.forType = json['forType'] ?? '';
    this.forId = json['forId'] ?? '';
    this.willJoinNextWeek = json['willJoinNextWeek'] ?? '';
    this.willInvite = json['willInvite'] ?? '';
    this.invites = json.containsKey('invites') ? _parseService.parseListString(json['invites']) : [];
  }

  Map<String, dynamic> toJson() =>
    {
      '_id': id,
      'userId': userId,
      'forType': forType,
      'forId': forId,
      'willJoinNextWeek': willJoinNextWeek,
      'willInvite': willInvite,
      'invites': invites,
    };
}
