import '../../common/image_service.dart';
import '../../common/parse_service.dart';
import './feedback_vote_class.dart';

class EventFeedbackClass {
  ParseService _parseService = ParseService();
  ImageService _imageService = ImageService();

  String id = '', eventId = '';
  List<FeedbackVoteClass> feedbackVotes = [];
  List<FeedbackVoteClass> positiveVotes = [];
  List<String> imageUrls = [];

  EventFeedbackClass(this.id, this.eventId, this.feedbackVotes, this.positiveVotes, this.imageUrls);

  EventFeedbackClass.fromJson(Map<String, dynamic> json) {
    this.id = json.containsKey('_id') ? json['_id'] : json.containsKey('id') ? json['id'] : '';
    this.eventId = json['eventId'] ?? '';
    this.feedbackVotes = json.containsKey('feedbackVotes') ? parseFeedbackVotes(json['feedbackVotes']) : [];
    this.positiveVotes = json.containsKey('positiveVotes') ? parseFeedbackVotes(json['positiveVotes']) : [];
    this.imageUrls = _imageService.GetUrls(_parseService.parseListString(json['imageUrls'] != null ? json['imageUrls'] : []));
  }

  Map<String, dynamic> toJson() =>
    {
      '_id': id,
      'eventId': eventId,
      'feedbackVotes': feedbackVotes,
      'positiveVotes': positiveVotes,
      'imageUrls': imageUrls,
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
