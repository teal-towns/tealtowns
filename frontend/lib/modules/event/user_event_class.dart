import '../../common/parse_service.dart';
import './weekly_event_class.dart';

class UserEventClass {
  ParseService _parseService = ParseService();

  String id = '', eventId = '', userId = '', weeklyEventUName = '', hostStatus = '', attendeeStatus = '', eventEnd = '',
    rsvpNote = '', createdAt = '';
  int hostGroupSizeMax = 0, hostGroupSize = 0, attendeeCountAsk = 0, attendeeCount = 0, selfHostCount = 0;
  double priceUSD = 0;
  Map<String, dynamic> user = {};

  Map<String, dynamic> userFeedback = {};
  WeeklyEventClass weeklyEvent = WeeklyEventClass.fromJson({});

  UserEventClass(this.id, this.eventId, this.userId, this.weeklyEventUName, this.hostStatus, this.attendeeStatus,
    this.eventEnd, this.rsvpNote, this.createdAt,
    this.hostGroupSizeMax, this.hostGroupSize, this.attendeeCountAsk, this.attendeeCount, this.selfHostCount,
    this.priceUSD, this.user, this.userFeedback);

  UserEventClass.fromJson(Map<String, dynamic> json) {
    this.id = json.containsKey('_id') ? json['_id'] : json.containsKey('id') ? json['id'] : '';
    this.eventId = json['eventId'] ?? '';
    this.userId = json['userId'] ?? '';
    this.weeklyEventUName = json['weeklyEventUName'] ?? '';
    this.hostStatus = json['hostStatus'] ?? '';
    this.attendeeStatus = json['attendeeStatus'] ?? '';
    this.eventEnd = json['eventEnd'] ?? '';
    this.rsvpNote = json['rsvpNote'] ?? '';
    this.createdAt = json['createdAt'] ?? '';
    this.hostGroupSizeMax = json['hostGroupSizeMax'] != null ? _parseService.toIntNoNull(json['hostGroupSizeMax']) : 0;
    this.hostGroupSize = json['hostGroupSize'] != null ? _parseService.toIntNoNull(json['hostGroupSize']) : 0;
    this.attendeeCountAsk = json['attendeeCountAsk'] != null ? _parseService.toIntNoNull(json['attendeeCountAsk']) : 0;
    this.attendeeCount = json['attendeeCount'] != null ? _parseService.toIntNoNull(json['attendeeCount']) : 0;
    this.selfHostCount = json['selfHostCount'] != null ? _parseService.toIntNoNull(json['selfHostCount']) : 0;
    this.priceUSD = json['priceUSD'] != null ? _parseService.toDoubleNoNull(json['priceUSD']) : 0;
    this.user = json['user'] != null ? json['user'] : {};

    this.userFeedback = json['userFeedback'] != null ? json['userFeedback'] : {};
    this.weeklyEvent = json['weeklyEvent'] != null ? WeeklyEventClass.fromJson(json['weeklyEvent']) : WeeklyEventClass.fromJson({});
  }

  Map<String, dynamic> toJson() =>
    {
      '_id': id,
      'eventId': eventId,
      'userId': userId,
      'weeklyEventUName': weeklyEventUName,
      'hostStatus': hostStatus,
      'attendeeStatus': attendeeStatus,
      'rsvpNote': rsvpNote,
      'createdAt': createdAt,
      'hostGroupSizeMax': hostGroupSizeMax,
      'hostGroupSize': hostGroupSize,
      'attendeeCountAsk': attendeeCountAsk,
      'attendeeCount': attendeeCount,
      'selfHostCount': selfHostCount,
      'priceUSD': priceUSD,
      'eventEnd': eventEnd,
      'rsvpNote': rsvpNote,
    };
}
