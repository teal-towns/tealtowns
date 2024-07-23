import '../../common/parse_service.dart';

class UserFollowUpClass {
  ParseService _parseService = ParseService();

  String id = '', username = '', neighborhoodUName = '', forType = '', contactType = '', followUpAt = '',
    nextFollowUpAt = '';
  int nextFollowUpDone = 0, attempt = 0;

  UserFollowUpClass(this.id, this.username, this.neighborhoodUName, this.forType, this.contactType,
    this.followUpAt, this.nextFollowUpAt, this.nextFollowUpDone, this.attempt);

  UserFollowUpClass.fromJson(Map<String, dynamic> json) {
    this.id = json.containsKey('_id') ? json['_id'] : json.containsKey('id') ? json['id'] : '';
    this.username = json['username'] ?? '';
    this.neighborhoodUName = json['neighborhoodUName'] ?? '';
    this.forType = json['forType'] ?? '';
    this.contactType = json['contactType'] ?? '';
    this.followUpAt = json['followUpAt'] ?? '';
    this.nextFollowUpAt = json['nextFollowUpAt'] ?? '';
    this.nextFollowUpDone = json['nextFollowUpDone'] != null ? _parseService.toIntNoNull(json['nextFollowUpDone']) : 0;
    this.attempt = json['attempt'] != null ? _parseService.toIntNoNull(json['attempt']) : 0;
  }

  Map<String, dynamic> toJson() =>
    {
      '_id': id,
      'username': username,
      'neighborhoodUName': neighborhoodUName,
      'forType': forType,
      'contactType': contactType,
      'followUpAt': followUpAt,
      'nextFollowUpAt': nextFollowUpAt,
      'nextFollowUpDone': nextFollowUpDone,
      'attempt': attempt,
    };
}
