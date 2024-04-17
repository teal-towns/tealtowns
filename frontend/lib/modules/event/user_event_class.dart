import '../../common/parse_service.dart';

class UserEventClass {
  ParseService _parseService = ParseService();

  String id = '', eventId = '', userId = '', hostStatus = '', attendeeStatus = '';
  int hostGroupSizeMax = 0, hostGroupSize = 0, attendeeCountAsk = 0, attendeeCount = 0;
  double creditsEarned = 0, creditsRedeemed = 0, creditsPriceUSD = 0;

  UserEventClass(this.id, this.eventId, this.userId, this.hostStatus, this.attendeeStatus,
    this.hostGroupSizeMax, this.hostGroupSize, this.attendeeCountAsk, this.attendeeCount,
    this.creditsEarned, this.creditsRedeemed, this.creditsPriceUSD);

  UserEventClass.fromJson(Map<String, dynamic> json) {
    this.id = json.containsKey('_id') ? json['_id'] : json.containsKey('id') ? json['id'] : '';
    this.eventId = json['eventId'] ?? '';
    this.userId = json['userId'] ?? '';
    this.hostStatus = json['hostStatus'] ?? '';
    this.attendeeStatus = json['attendeeStatus'] ?? '';
    this.hostGroupSizeMax = json['hostGroupSizeMax'] != null ? _parseService.toIntNoNull(json['hostGroupSizeMax']) : 0;
    this.hostGroupSize = json['hostGroupSize'] != null ? _parseService.toIntNoNull(json['hostGroupSize']) : 0;
    this.attendeeCountAsk = json['attendeeCountAsk'] != null ? _parseService.toIntNoNull(json['attendeeCountAsk']) : 0;
    this.attendeeCount = json['attendeeCount'] != null ? _parseService.toIntNoNull(json['attendeeCount']) : 0;
    this.creditsEarned = json['creditsEarned'] != null ? _parseService.toDoubleNoNull(json['creditsEarned']) : 0;
    this.creditsRedeemed = json['creditsRedeemed'] != null ? _parseService.toDoubleNoNull(json['creditsRedeemed']) : 0;
    this.creditsPriceUSD = json['creditsPriceUSD'] != null ? _parseService.toDoubleNoNull(json['creditsPriceUSD']) : 0;
  }

  Map<String, dynamic> toJson() =>
    {
      '_id': id,
      'eventId': eventId,
      'userId': userId,
      'hostStatus': hostStatus,
      'attendeeStatus': attendeeStatus,
      'hostGroupSizeMax': hostGroupSizeMax,
      'hostGroupSize': hostGroupSize,
      'attendeeCountAsk': attendeeCountAsk,
      'attendeeCount': attendeeCount,
      'creditsEarned': creditsEarned,
      'creditsRedeemed': creditsRedeemed,
      'creditsPriceUSD': creditsPriceUSD,
    };
}
