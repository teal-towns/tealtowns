import './neighborhood_class.dart';

class UserNeighborhoodClass {
  String id = '', userId = '', neighborhoodId = '', status = '';
  NeighborhoodClass neighborhood = NeighborhoodClass.fromJson({});

  UserNeighborhoodClass(this.id, this.userId, this.neighborhoodId, this.status, this.neighborhood);

  UserNeighborhoodClass.fromJson(Map<String, dynamic> json) {
    this.id = json.containsKey('_id') ? json['_id'] : json.containsKey('id') ? json['id'] : '';
    this.userId = json['userId'] ?? '';
    this.neighborhoodId = json['neighborhoodId'] ?? '';
    this.status = json['status'] ?? '';
    this.neighborhood = NeighborhoodClass.fromJson(json['neighborhood'] ?? {});
  }

  Map<String, dynamic> toJson() =>
    {
      '_id': id,
      'userId': userId,
      'neighborhoodId': neighborhoodId,
      'status': status,
    };
  
  static List<Map<String, dynamic>> toJsonList(List<UserNeighborhoodClass> items) {
    List<Map<String, dynamic>> data = [];
    for (var i = 0; i < items.length; i++) {
      Map<String, dynamic> item = items[i].toJson();
      item['neighborhood'] = items[i].neighborhood.toJson();
      data.add(item);
    }
    return data;
  }
  
  static List<UserNeighborhoodClass> parseList(List<dynamic> itemsRaw) {
    List<UserNeighborhoodClass> items = [];
    if (itemsRaw != null) {
      for (var item in itemsRaw) {
        items.add(UserNeighborhoodClass.fromJson(item));
      }
    }
    return items;
  }

}
