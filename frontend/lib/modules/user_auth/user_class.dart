import '../../common/classes/location_class.dart';

class UserClass {
  String id = '', email = '', firstName = '', lastName = '', status = '', username = '',
    sessionId = '', roles = '', createdAt = '';
  //List<String> roles;
  LocationClass location = LocationClass.fromJson({});
  UserClass(this.id, this.email, this.firstName, this.lastName, this.status, this.username, this.sessionId, this.roles,
    this.createdAt, this.location);
  UserClass.fromJson(Map<String, dynamic> json) {
    this.id = json.containsKey('_id') ? json['_id'] : json.containsKey('id') ? json['id'] : '';
    this.email = json.containsKey('email') ? json['email'] : '';
    this.firstName = json.containsKey('firstName') ? json['firstName'] : '';
    this.lastName = json.containsKey('lastName') ? json['lastName'] : '';
    this.status = json.containsKey('status') ? json['status'] : '';
    this.username = json.containsKey('username') ? json['username'] : '';
    this.sessionId = json.containsKey('sessionId') ? json['sessionId'] : '';
    this.roles = json.containsKey('roles') ? json['roles'] : '';
    this.createdAt = json.containsKey('createdAt') ? json['createdAt'] : '';
    this.location = LocationClass.fromJson(json.containsKey('location') ? json['location']: {});
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'firstName': firstName,
    'lastName': lastName,
    'status': status,
    'username': username,
    'sessionId': sessionId,
    'roles': roles,
    'createdAt': createdAt,
    'location': location.toJson(),
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
