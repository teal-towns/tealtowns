class UserClass {
  String id = '', email = '', firstName = '', lastName = '', status = '', username = '',
    sessionId = '', roles = '', createdAt = '';
  //List<String> roles;
  UserClass(this.id, this.email, this.firstName, this.lastName, this.status, this.username, this.sessionId, this.roles,
    this.createdAt);
  UserClass.fromJson(Map<String, dynamic> jsonData) {
    this.id = jsonData.containsKey('_id') ? jsonData['_id'] : '';
    this.email = jsonData.containsKey('email') ? jsonData['email'] : '';
    this.firstName = jsonData.containsKey('firstName') ? jsonData['firstName'] : '';
    this.lastName = jsonData.containsKey('lastName') ? jsonData['lastName'] : '';
    this.status = jsonData.containsKey('status') ? jsonData['status'] : '';
    this.username = jsonData.containsKey('username') ? jsonData['username'] : '';
    this.sessionId = jsonData.containsKey('sessionId') ? jsonData['sessionId'] : '';
    this.roles = jsonData.containsKey('roles') ? jsonData['roles'] : '';
    this.createdAt = jsonData.containsKey('createdAt') ? jsonData['createdAt'] : '';
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
  };
}
