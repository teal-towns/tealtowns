import '../../common/classes/location_class.dart';
import '../../common/parse_service.dart';

class UserClass {
  ParseService _parseService = ParseService();

  String id = '', email = '', firstName = '', lastName = '', status = '', username = '',
    sessionId = '', roles = '', createdAt = '', phoneNumber = '', phoneNumberVerificationKey = '',
    whatsappNumber = '', whatsappNumberVerificationKey = '';
  //List<String> roles;
  int emailVerified = 0, phoneNumberVerified = 0, whatsappNumberVerified = 0;
  LocationClass location = LocationClass.fromJson({});
  UserClass(this.id, this.email, this.firstName, this.lastName, this.status, this.username, this.sessionId, this.roles,
    this.createdAt, this.phoneNumber, this.phoneNumberVerificationKey,
    this.whatsappNumber, this.whatsappNumberVerificationKey,
    this.emailVerified, this.phoneNumberVerified, this.whatsappNumberVerified,
    this.location);
  UserClass.fromJson(Map<String, dynamic> json) {
    this.id = json.containsKey('_id') ? json['_id'] : json.containsKey('id') ? json['id'] : '';
    this.email = json.containsKey('email') ? json['email'] : '';
    this.firstName = json.containsKey('firstName') ? json['firstName'] : '';
    this.lastName = json.containsKey('lastName') ? json['lastName'] : '';
    this.status = json.containsKey('status') ? json['status'] : '';
    this.username = json.containsKey('username') ? json['username'] : '';
    this.sessionId = json.containsKey('sessionId') ? json['sessionId'] : '';
    String roles = '';
    if (json.containsKey('roles')) {
      if (json['roles'] is String) {
        roles = json['roles'];
      } else {
        roles = json['roles'].join(',');
      }
    }
    this.roles = roles;
    this.createdAt = json.containsKey('createdAt') ? json['createdAt'] : '';
    this.location = LocationClass.fromJson(json.containsKey('location') ? json['location']: {});
    this.phoneNumber = json['phoneNumber'] ?? '';
    this.phoneNumberVerificationKey = json['phoneNumberVerificationKey'] ?? '';
    this.phoneNumberVerified = json['phoneNumberVerified'] != null ? _parseService.toIntNoNull(json['phoneNumberVerified']) : 0;
    this.whatsappNumber = json['whatsappNumber'] ?? '';
    this.whatsappNumberVerificationKey = json['whatsappNumberVerificationKey'] ?? '';
    this.whatsappNumberVerified = json['whatsappNumberVerified'] != null ? _parseService.toIntNoNull(json['whatsappNumberVerified']) : 0;
    this.emailVerified = json['emailVerified'] != null ? _parseService.toIntNoNull(json['emailVerified']) : 0;
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'email': email,
    'firstName': firstName,
    'lastName': lastName,
    'status': status,
    'username': username,
    'sessionId': sessionId,
    'roles': roles,
    'createdAt': createdAt,
    'location': location.toJson(),
    'phoneNumber': phoneNumber,
    'phoneNumberVerificationKey': phoneNumberVerificationKey,
    'phoneNumberVerified': phoneNumberVerified,
    'whatsappNumber': whatsappNumber,
    'whatsappNumberVerificationKey': whatsappNumberVerificationKey,
    'whatsappNumberVerified': whatsappNumberVerified,
    'emailVerified': emailVerified,
  };

  static List<UserClass> parseUsers(List<dynamic> itemsRaw) {
    List<UserClass> items = [];
    if (itemsRaw != null) {
      for (var item in itemsRaw) {
        items.add(UserClass.fromJson(item));
      }
    }
    return items;
  }
}
