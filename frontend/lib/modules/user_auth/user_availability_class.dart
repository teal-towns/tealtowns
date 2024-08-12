import '../../common/parse_service.dart';

class UserAvailabilityClass {
  ParseService _parseService = ParseService();

  String id = '', userId = '', username = '';
  List<Map<String, dynamic>> availableTimesByDay = [];

  UserAvailabilityClass(this.id, this.userId, this.username, this.availableTimesByDay);

  UserAvailabilityClass.fromJson(Map<String, dynamic> json) {
    this.id = json.containsKey('_id') ? json['_id'] : json.containsKey('id') ? json['id'] : '';
    this.userId = json['userId'] ?? '';
    this.username = json['username'] ?? '';
    this.availableTimesByDay = json['availableTimesByDay'] != null ?
      _parseService.parseListMapStringDynamic(json['availableTimesByDay']) : [];
  }

  Map<String, dynamic> toJson() =>
    {
      '_id': id,
      'userId': userId,
      'username': username,
      'availableTimesByDay': availableTimesByDay,
    };
}
