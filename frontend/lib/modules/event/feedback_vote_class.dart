import '../../common/parse_service.dart';

class FeedbackVoteClass {
  ParseService _parseService = ParseService();

  String id = '', feedback = '';
  List<String> userIds = [];

  FeedbackVoteClass(this.id, this.feedback, this.userIds);

  FeedbackVoteClass.fromJson(Map<String, dynamic> json) {
    this.id = json.containsKey('_id') ? json['_id'] : json.containsKey('id') ? json['id'] : '';
    this.feedback = json['feedback'] ?? '';
    this.userIds = json.containsKey('userIds') ? _parseService.parseListString(json['userIds']) : [];
  }

  Map<String, dynamic> toJson() =>
    {
      '_id': id,
      'feedback': feedback,
      'userIds': userIds,
    };
}
