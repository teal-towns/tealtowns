import '../../common/classes/location_class.dart';
import '../../common/parse_service.dart';
import './shared_item_owner_class.dart';

class SharedItemClass {
  ParseService _parseService = ParseService();

  String id = '', title = '', description = '', currentOwnerUserId = '', status = '', currency = '';
  List<String> tags = [], imageUrls = [];
  LocationClass location = LocationClass.fromJson({});
  double? originalPrice, currentPrice, maintenancePerYear, maintenanceAvailable, fundingRequired;
  int generation = 0, monthsStarted = 0, monthsToPayBack = 0, minOwners = 1, maxOwners = 10, pledgedOwners = 0;
  // Map<String, dynamic> xOwner = {};
  double xDistanceKm = -999;
  SharedItemOwnerClass sharedItemOwner_current = SharedItemOwnerClass.fromJson({});

  SharedItemClass(this.id, this.title, this.description, this.imageUrls, this.currentOwnerUserId, this.tags,
    this.location, this.originalPrice, this.currentPrice, this.currency, this.generation, this.monthsStarted, this.monthsToPayBack,
    this.maintenancePerYear, this.maintenanceAvailable, this.minOwners, this.maxOwners, this.status,
    this.pledgedOwners, this.fundingRequired, this.xDistanceKm, this.sharedItemOwner_current);

  SharedItemClass.fromJson(Map<String, dynamic> json) {
    this.id = json.containsKey('_id') ? json['_id'] : json.containsKey('id') ? json['id'] : '';
    this.title = json.containsKey('title') ? json['title'] : '';
    this.description = json['description'] ?? '';
    this.imageUrls = _parseService.parseListString(json['imageUrls'] != null ? json['imageUrls'] : []);
    this.currentOwnerUserId = json['currentOwnerUserId'] ?? '';
    this.tags = _parseService.parseListString(json['tags'] != null ? json['tags'] : []);
    this.location = LocationClass.fromJson(json['location'] ?? {});
    this.originalPrice = json['originalPrice'] != null ? json['originalPrice'] : 1000;
    this.currentPrice = json['currentPrice'] != null ? json['currentPrice'] : 1000;
    this.currency = json['currency'] != null ? json['currency'] : 'USD';
    this.generation = json['generation'] != null ? json['generation'] : 0;
    this.monthsStarted = json['monthsStarted'] != null ? json['monthsStarted'] : 0;
    this.monthsToPayBack = json['monthsToPayBack'] != null ? json['monthsToPayBack'] : 12;
    this.maintenancePerYear = json['maintenancePerYear'] != null ? json['maintenancePerYear'] : 50;
    this.maintenanceAvailable = json['maintenanceAvailable'] != null ? json['maintenanceAvailable'] : 0;
    this.minOwners = json.containsKey('minOwners') ? json['minOwners'] : 1;
    this.maxOwners = json.containsKey('maxOwners') ? json['maxOwners'] : 10;
    this.status = json['status'] ?? '';
    this.pledgedOwners = json.containsKey('pledgedOwners') ? json['pledgedOwners'] : 0;
    this.fundingRequired = json.containsKey('fundingRequired') ? json['fundingRequired'] : 0;

    // this.xOwner = json['xOwner'] != null ? json['xOwner'] : {};
    this.xDistanceKm = json.containsKey('xDistanceKm') ? json['xDistanceKm'] : -999;
    this.sharedItemOwner_current = json.containsKey('sharedItemOwner_current') ?
      SharedItemOwnerClass.fromJson(json['sharedItemOwner_current']) : SharedItemOwnerClass.fromJson({});
  }

  Map<String, dynamic> toJson() =>
    {
      '_id': id,
      'id': id,
      'title': title,
      'description': description,
      'imageUrls': imageUrls,
      'currentOwnerUserId': currentOwnerUserId,
      'tags': tags,
      'location': location,
      'originalPrice': originalPrice,
      'currentPrice': currentPrice,
      'currency': currency,
      'generation': generation,
      'monthsStarted': monthsStarted,
      'monthsToPayBack': monthsToPayBack,
      'maintenancePerYear': maintenancePerYear,
      'maintenanceAvailable': maintenanceAvailable,
      'minOwners': minOwners,
      'maxOwners': maxOwners,
      'status': status,
      'pledgedOwners': pledgedOwners,
      'fundingRequired': fundingRequired,
    };

  // List<String> parseListString(List<dynamic> itemsRaw) {
  //   List<String> items = [];
  //   if (itemsRaw != null) {
  //     for (var item in itemsRaw) {
  //       items.add(item);
  //     }
  //   }
  //   return items;
  // }
}
