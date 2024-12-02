import '../../common/classes/location_class.dart';
import '../../common/image_service.dart';
import '../../common/parse_service.dart';
import '../user_auth/user_class.dart';
import 'event_class.dart';
// import 'user_event_class.dart';

class WeeklyEventClass {
  ImageService _imageService = ImageService();
  ParseService _parseService = ParseService();

  String id = '', uName = '', neighborhoodUName = '', title = '', description = '', startTime = '', endTime = '',
    timezone = '', type = '', createdAt = '';
  List<String> adminUserIds = [], imageUrls = [], tags = [];
  LocationClass location = LocationClass.fromJson({});
  Map<String, dynamic> locationAddress = {};
  int dayOfWeek = 0, hostGroupSizeDefault = 0, archived = 0;
  double rsvpDeadlineHours = 0, priceUSD = 0, hostMoneyPerPersonUSD = 0, xDistanceKm = -999;
  List<UserClass> adminUsers = [];
  List<Map<String, dynamic>> pendingUsers = [];
  String xDay = '';
  EventClass xEvent = EventClass.fromJson({});
  // UserEventClass xUserEvent = UserEventClass.fromJson({});
  Map<String, dynamic> xUserEvent = {};

  WeeklyEventClass(this.id, this.uName, this.neighborhoodUName, this.title, this.description, this.startTime, this.endTime,
    this.timezone, this.type, this.createdAt, this.adminUserIds, this.tags,
    this.imageUrls, this.location, this.locationAddress, this.dayOfWeek, this.hostGroupSizeDefault, this.archived,
    this.rsvpDeadlineHours, this.priceUSD,
    this.hostMoneyPerPersonUSD, this.xDistanceKm, this.adminUsers, this.pendingUsers,
    this.xDay, this.xEvent, this.xUserEvent);

  WeeklyEventClass.fromJson(Map<String, dynamic> json, { bool imageUrlsReplaceLocalhost = true }) {
    List<String> days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    this.id = json.containsKey('_id') ? json['_id'] : json.containsKey('id') ? json['id'] : '';
    this.uName = json['uName'] ?? '';
    this.neighborhoodUName = json['neighborhoodUName'] ?? '';
    this.title = json['title'] ?? '';
    this.description = json['description'] ?? '';
    this.startTime = json['startTime'] ?? '';
    this.endTime = json['endTime'] ?? '';
    this.timezone = json['timezone'] ?? '';
    this.type = json['type'] ?? '';
    this.createdAt = json['createdAt'] ?? '';
    this.adminUserIds = _parseService.parseListString(json['adminUserIds'] != null ? json['adminUserIds'] : []);
    this.tags = _parseService.parseListString(json['tags'] != null ? json['tags'] : []);
    this.imageUrls = _imageService.GetUrls((_parseService.parseListString(json['imageUrls'] != null ? json['imageUrls'] : [])), replaceLocalhost: imageUrlsReplaceLocalhost);
    this.location = LocationClass.fromJson(json['location'] ?? {});
    this.locationAddress = json['locationAddress'] ?? {};
    this.dayOfWeek = json['dayOfWeek'] != null ? _parseService.toIntNoNull(json['dayOfWeek']) : 0;
    this.hostGroupSizeDefault = json['hostGroupSizeDefault'] != null ? _parseService.toIntNoNull(json['hostGroupSizeDefault']) : 0;
    this.archived = json['archived'] != null ? _parseService.toIntNoNull(json['archived']) : 0;
    this.rsvpDeadlineHours = json['rsvpDeadlineHours'] != null ? _parseService.toDoubleNoNull(json['rsvpDeadlineHours']) : 0;
    this.priceUSD = json['priceUSD'] != null ? _parseService.toDoubleNoNull(json['priceUSD']) : 0;
    this.hostMoneyPerPersonUSD = json['hostMoneyPerPersonUSD'] != null ? _parseService.toDoubleNoNull(json['hostMoneyPerPersonUSD']) : 0;
    this.xDay = days[this.dayOfWeek];
    this.xDistanceKm = json.containsKey('xDistanceKm') ? _parseService.toDoubleNoNull(json['xDistanceKm']) : -999;
    this.adminUsers = json.containsKey('adminUsers') ? UserClass.parseUsers(json['adminUsers']) : [];
    this.pendingUsers = json.containsKey('pendingUsers') ? _parseService.parseListMapStringDynamic(json['pendingUsers']) : [];
    this.xEvent = json.containsKey('xEvent') ? EventClass.fromJson(json['xEvent']) : EventClass.fromJson({});
    // this.xUserEvent = json.containsKey('xUserEvent') ? UserEventClass.fromJson(json['xUserEvent']) :
    //   UserEventClass.fromJson({});
    this.xUserEvent = json.containsKey('xUserEvent') ? _parseService.parseMapStringDynamic(json['xUserEvent']) : {};
  }

  Map<String, dynamic> toJson() =>
    {
      '_id': id,
      'uName': uName,
      'neighborhoodUName': neighborhoodUName,
      'title': title,
      'description': description,
      'startTime': startTime,
      'endTime': endTime,
      'timezone': timezone,
      'type': type,
      'tags': tags,
      'createdAt': createdAt,
      'adminUserIds': adminUserIds,
      'imageUrls': imageUrls,
      'location': { 'type': 'Point', 'coordinates': location.coordinates },
      'locationAddress': locationAddress,
      'dayOfWeek': dayOfWeek,
      'hostGroupSizeDefault': hostGroupSizeDefault,
      'archived': archived,
      'rsvpDeadlineHours': rsvpDeadlineHours,
      'priceUSD': priceUSD,
      'hostMoneyPerPersonUSD': hostMoneyPerPersonUSD,
      'pendingUsers': pendingUsers,
    };
}
