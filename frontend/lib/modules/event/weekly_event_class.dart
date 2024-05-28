import '../../common/classes/location_class.dart';
import '../../common/image_service.dart';
import '../../common/parse_service.dart';
import '../user_auth/user_class.dart';

class WeeklyEventClass {
  ImageService _imageService = ImageService();
  ParseService _parseService = ParseService();

  String id = '', uName = '', title = '', description = '', startTime = '', endTime = '', timezone = '', type = '';
  List<String> adminUserIds = [], imageUrls = [];
  LocationClass location = LocationClass.fromJson({});
  int dayOfWeek = 0, hostGroupSizeDefault = 0, archived = 0;
  double rsvpDeadlineHours = 0, priceUSD = 0, hostMoneyPerPersonUSD = 0, xDistanceKm = -999;
  List<UserClass> adminUsers = [];
  String xDay = '';

  WeeklyEventClass(this.id, this.uName, this.title, this.description, this.startTime, this.endTime,
    this.timezone, this.type, this.adminUserIds,
    this.imageUrls, this.location, this.dayOfWeek, this.hostGroupSizeDefault, this.archived, this.rsvpDeadlineHours, this.priceUSD,
    this.hostMoneyPerPersonUSD, this.xDistanceKm, this.adminUsers, this.xDay);

  WeeklyEventClass.fromJson(Map<String, dynamic> json) {
    List<String> days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    this.id = json.containsKey('_id') ? json['_id'] : json.containsKey('id') ? json['id'] : '';
    this.uName = json['uName'] ?? '';
    this.title = json['title'] ?? '';
    this.description = json['description'] ?? '';
    this.startTime = json['startTime'] ?? '';
    this.endTime = json['endTime'] ?? '';
    this.timezone = json['timezone'] ?? '';
    this.type = json['type'] ?? '';
    this.adminUserIds = _parseService.parseListString(json['adminUserIds'] != null ? json['adminUserIds'] : []);
    this.imageUrls = _imageService.GetUrls(_parseService.parseListString(json['imageUrls'] != null ? json['imageUrls'] : []));
    this.location = LocationClass.fromJson(json['location'] ?? {});
    this.dayOfWeek = json['dayOfWeek'] != null ? _parseService.toIntNoNull(json['dayOfWeek']) : 0;
    this.hostGroupSizeDefault = json['hostGroupSizeDefault'] != null ? _parseService.toIntNoNull(json['hostGroupSizeDefault']) : 0;
    this.archived = json['archived'] != null ? _parseService.toIntNoNull(json['archived']) : 0;
    this.rsvpDeadlineHours = json['rsvpDeadlineHours'] != null ? _parseService.toDoubleNoNull(json['rsvpDeadlineHours']) : 0;
    this.priceUSD = json['priceUSD'] != null ? _parseService.toDoubleNoNull(json['priceUSD']) : 0;
    this.hostMoneyPerPersonUSD = json['hostMoneyPerPersonUSD'] != null ? _parseService.toDoubleNoNull(json['hostMoneyPerPersonUSD']) : 0;
    this.xDay = days[this.dayOfWeek];
    this.xDistanceKm = json.containsKey('xDistanceKm') ? _parseService.toDoubleNoNull(json['xDistanceKm']) : -999;
    this.adminUsers = json.containsKey('adminUsers') ? UserClass.parseUsers(json['adminUsers']) : [];
  }

  Map<String, dynamic> toJson() =>
    {
      '_id': id,
    //   'id': id,
      'uName': uName,
      'title': title,
      'description': description,
      'startTime': startTime,
      'endTime': endTime,
      'timezone': timezone,
      'type': type,
      'adminUserIds': adminUserIds,
      'imageUrls': imageUrls,
      'location': { 'type': 'Point', 'coordinates': location.coordinates },
      'dayOfWeek': dayOfWeek,
      'hostGroupSizeDefault': hostGroupSizeDefault,
      'archived': archived,
      'rsvpDeadlineHours': rsvpDeadlineHours,
      'priceUSD': priceUSD,
      'hostMoneyPerPersonUSD': hostMoneyPerPersonUSD,
    };
}
