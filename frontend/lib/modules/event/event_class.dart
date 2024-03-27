class EventClass {
  String id = '', weeklyEventId = '', start = '';

  EventClass(this.id, this.weeklyEventId, this.start);

  EventClass.fromJson(Map<String, dynamic> json) {
    this.id = json.containsKey('_id') ? json['_id'] : json.containsKey('id') ? json['id'] : '';
    this.weeklyEventId = json['weeklyEventId'] ?? '';
    this.start = json['start'] ?? '';
  }

  Map<String, dynamic> toJson() =>
    {
      '_id': id,
      'weeklyEventId': weeklyEventId,
      'start': start,
    };
}
