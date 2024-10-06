import '../../common/parse_service.dart';

class MixerGameClass {
  ParseService _parseService = ParseService();

  String id = '', uName = '', neighborhoodUName = '', gameType = '', state = 'gameOver';
  List<String> hostUserIds = [];
  Map<String, dynamic> gameDetails = {};
  List<Map<String, dynamic>> players = [];

  MixerGameClass(this.id, this.uName, this.neighborhoodUName, this.gameType, this.state,
    this.hostUserIds, this.gameDetails, this.players);

  MixerGameClass.fromJson(Map<String, dynamic> json) {
    this.id = json.containsKey('_id') ? json['_id'] : json.containsKey('id') ? json['id'] : '';
    this.uName = json['uName'] ?? '';
    this.neighborhoodUName = json['neighborhoodUName'] ?? '';
    this.gameType = json['gameType'] ?? '';
    // this.eventId = json['eventId'] ?? '';
    // this.weeklyEventUName = json['weeklyEventUName'] ?? '';
    this.state = json['state'] ?? 'gamveOver';
    this.hostUserIds = _parseService.parseListString(json['hostUserIds'] != null ? json['hostUserIds'] : []);
    this.gameDetails = json['gameDetails'] ?? {};
    this.players = _parseService.parseListMapStringDynamic(json['players'] != null ? json['players'] : []);
  }

  Map<String, dynamic> toJson() =>
    {
      '_id': id,
      'uName': uName,
      'neighborhoodUName': neighborhoodUName,
      'gameType': gameType,
      // 'eventId': eventId,
      // 'weeklyEventUName': weeklyEventUName,
      'state': state,
      'hostUserIds': hostUserIds,
      'gameDetails': gameDetails,
      'players': players,
    };
}
