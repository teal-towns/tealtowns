class FeaturedEventPhotoClass {
  String id = '', eventId = '', imageUrl = '', weeklyEventUName = '', neighborhoodUName = '', title = '', start = '', end = '';

  FeaturedEventPhotoClass(this.id, this.eventId, this.imageUrl, this.weeklyEventUName, this.neighborhoodUName,
    this.title, this.start, this.end);

  FeaturedEventPhotoClass.fromJson(Map<String, dynamic> json) {
    this.id = json.containsKey('_id') ? json['_id'] : json.containsKey('id') ? json['id'] : '';
    this.eventId = json['eventId'] ?? '';
    this.imageUrl = json['imageUrl'] ?? '';
    this.weeklyEventUName = json['weeklyEventUName'] ?? '';
    this.neighborhoodUName = json['neighborhoodUName'] ?? '';
    this.title = json['title'] ?? '';
    this.start = json['start'] ?? '';
    this.end = json['end'] ?? '';
  }

  Map<String, dynamic> toJson() =>
    {
      '_id': id,
      'eventId': eventId,
      'imageUrl': imageUrl,
      'weeklyEventUName': weeklyEventUName,
      'neighborhoodUName': neighborhoodUName,
      'title': title,
      'start': start,
      'end': end,
    };
}
