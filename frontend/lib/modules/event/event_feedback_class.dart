import './feedback_vote_class.dart';

class EventFeedbackClass {
  String id = '', eventId = '';
  List<FeedbackVoteClass> feedbackVotes = [];
  List<FeedbackVoteClass> positiveVotes = [];

  EventFeedbackClass(this.id, this.eventId, this.feedbackVotes, this.positiveVotes);

  EventFeedbackClass.fromJson(Map<String, dynamic> json) {
    this.id = json.containsKey('_id') ? json['_id'] : json.containsKey('id') ? json['id'] : '';
    this.eventId = json['eventId'] ?? '';
    this.feedbackVotes = json.containsKey('feedbackVotes') ? parseFeedbackVotes(json['feedbackVotes']) : [];
    this.positiveVotes = json.containsKey('positiveVotes') ? parseFeedbackVotes(json['positiveVotes']) : [];
  }

  Map<String, dynamic> toJson() =>
    {
      '_id': id,
      'eventId': eventId,
      'feedbackVotes': feedbackVotes,
      'positiveVotes': positiveVotes,
    };
  
  static List<FeedbackVoteClass> parseFeedbackVotes(List<dynamic> itemsRaw) {
    List<FeedbackVoteClass> items = [];
    if (itemsRaw != null) {
      for (var item in itemsRaw) {
        items.add(FeedbackVoteClass.fromJson(item));
      }
    }
    return items;
  }
}
