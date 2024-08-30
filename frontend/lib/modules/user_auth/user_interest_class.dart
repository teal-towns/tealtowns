import '../../common/parse_service.dart';

class UserInterestClass {
  ParseService _parseService = ParseService();

  String id = '', userId = '', username = '';
  List<String> interests = [];
  List<String> hostInterests = [];
  List<String> hostInterestsPending = [];

  UserInterestClass(this.id, this.userId, this.username, this.interests, this.hostInterests, this.hostInterestsPending);

  UserInterestClass.fromJson(Map<String, dynamic> json) {
    this.id = json.containsKey('_id') ? json['_id'] : json.containsKey('id') ? json['id'] : '';
    this.userId = json['userId'] ?? '';
    this.username = json['username'] ?? '';
    this.interests = json['interests'] != null ? _parseService.parseListString(json['interests']) : [];
    this.hostInterests = json['hostInterests'] != null ? _parseService.parseListString(json['hostInterests']) : [];
    this.hostInterestsPending = json['hostInterestsPending'] != null ? _parseService.parseListString(json['hostInterestsPending']) : [];
    // this.neighborhoodEventAvailabilityMatches = json['neighborhoodEventAvailabilityMatches'] != null ?
    //   _parseService.parseListString(json['neighborhoodEventAvailabilityMatches']) : [];
  }

  Map<String, dynamic> toJson() =>
    {
      '_id': id,
      'userId': userId,
      'username': username,
      'interests': interests,
      'hostInterests': hostInterests,
      'hostInterestsPending': hostInterestsPending,
      // 'neighborhoodEventAvailabilityMatches': neighborhoodEventAvailabilityMatches,
    };
}
