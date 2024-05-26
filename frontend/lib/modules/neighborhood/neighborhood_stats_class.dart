import '../../common/parse_service.dart';

class NeighborhoodStatsClass {
  ParseService _parseService = ParseService();

  String id = '', neighborhoodUName = '', start = '', end = '';
  int usersCount = 0, weeklyEventsCount = 0, uniqueEventUsersCount = 0, freeEventsCount = 0, paidEventsCount = 0,
    totalEventUsersCount = 0, totalFreeEventUsersCount = 0, totalPaidEventUsersCount = 0;
  double totalCutUSD = 0;
  List<Map<String, dynamic>> eventInfos = [];

  NeighborhoodStatsClass(this.id, this.neighborhoodUName, this.start, this.end, this.usersCount, this.weeklyEventsCount,
    this.uniqueEventUsersCount, this.freeEventsCount, this.paidEventsCount, this.totalEventUsersCount,
    this.totalFreeEventUsersCount, this.totalPaidEventUsersCount, this.totalCutUSD, this.eventInfos);

  NeighborhoodStatsClass.fromJson(Map<String, dynamic> json) {
    this.id = json.containsKey('_id') ? json['_id'] : json.containsKey('id') ? json['id'] : '';
    this.neighborhoodUName = json['neighborhoodUName'] ?? '';
    this.start = json['start'] ?? '';
    this.end = json['end'] ?? '';
    this.usersCount = json['usersCount'] ?? 0;
    this.weeklyEventsCount = json['weeklyEventsCount'] ?? 0;
    this.uniqueEventUsersCount = json['uniqueEventUsersCount'] ?? 0;
    this.freeEventsCount = json['freeEventsCount'] ?? 0;
    this.paidEventsCount = json['paidEventsCount'] ?? 0;
    this.totalEventUsersCount = json['totalEventUsersCount'] ?? 0;
    this.totalFreeEventUsersCount = json['totalFreeEventUsersCount'] ?? 0;
    this.totalPaidEventUsersCount = json['totalPaidEventUsersCount'] ?? 0;
    this.totalCutUSD = json.containsKey('totalCutUSD') ? _parseService.toDoubleNoNull(json['totalCutUSD']) : 0;
    this.eventInfos = json.containsKey('eventInfos') ? _parseService.parseListMapStringDynamic(json['eventInfos']) : [];
  }

  Map<String, dynamic> toJson() =>
    {
      '_id': id,
      'neighborhoodUName': neighborhoodUName,
      'start': start,
      'end': end,
      'usersCount': usersCount,
      'weeklyEventsCount': weeklyEventsCount,
      'uniqueEventUsersCount': uniqueEventUsersCount,
      'freeEventsCount': freeEventsCount,
      'paidEventsCount': paidEventsCount,
      'totalEventUsersCount': totalEventUsersCount,
      'totalFreeEventUsersCount': totalFreeEventUsersCount,
      'totalPaidEventUsersCount': totalPaidEventUsersCount,
      'totalCutUSD': totalCutUSD,
      'eventInfos': eventInfos
    };
}
