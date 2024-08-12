import '../../common/parse_service.dart';

class UserInterestClass {
  ParseService _parseService = ParseService();

  String id = '', userId = '', username = '';
  List<String> interests = [], neighborhoodEventAvailabilityMatches = [];

  UserInterestClass(this.id, this.userId, this.username, this.interests, this.neighborhoodEventAvailabilityMatches);

  UserInterestClass.fromJson(Map<String, dynamic> json) {
    this.id = json.containsKey('_id') ? json['_id'] : json.containsKey('id') ? json['id'] : '';
    this.userId = json['userId'] ?? '';
    this.username = json['username'] ?? '';
    this.interests = json['interests'] != null ? _parseService.parseListString(json['interests']) : [];
    this.neighborhoodEventAvailabilityMatches = json['neighborhoodEventAvailabilityMatches'] != null ?
      _parseService.parseListString(json['neighborhoodEventAvailabilityMatches']) : [];
  }

  Map<String, dynamic> toJson() =>
    {
      '_id': id,
      'userId': userId,
      'username': username,
      'interests': interests,
      'neighborhoodEventAvailabilityMatches': neighborhoodEventAvailabilityMatches,
    };
}
