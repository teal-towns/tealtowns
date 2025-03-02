import '../../common/classes/location_class.dart';
import '../../common/image_service.dart';
import '../../common/parse_service.dart';
import './shared_item_owner_class.dart';

class SharedItemClass {
  ParseService _parseService = ParseService();
  ImageService _imageService = ImageService();

  String id = '', uName = '', neighborhoodUName = '', title = '', description = '', currentOwnerUserId = '', currentGenerationStart = '',
    currentPurchaserUserId = '', status = '', currency = '';
  List<String> tags = [], imageUrls = [];
  LocationClass location = LocationClass.fromJson({});
  double originalPrice = 1000, currentPrice = 1000, maintenancePerYear = 50, maintenanceAvailable = 0, maxMeters = 1500, fundingRequired = 0;
  int bought = 0, generation = 0, monthsToPayBack = 0, minOwners = 2, maxOwners = 10, pledgedOwners = 0;
  // Map<String, dynamic> xOwner = {};
  double xDistanceKm = -999;
  SharedItemOwnerClass sharedItemOwner_current = SharedItemOwnerClass.fromJson({});

  SharedItemClass(this.id, this.uName, this.neighborhoodUName, this.title, this.description, this.imageUrls,
    this.currentOwnerUserId, this.currentGenerationStart, this.currentPurchaserUserId, this.tags,
    this.location, this.bought, this.originalPrice, this.currentPrice, this.currency, this.generation, this.monthsToPayBack,
    this.maintenancePerYear, this.maintenanceAvailable, this.minOwners, this.maxOwners, this.maxMeters, this.status,
    this.pledgedOwners, this.fundingRequired, this.xDistanceKm, this.sharedItemOwner_current);

  SharedItemClass.fromJson(Map<String, dynamic> json) {
    this.id = json.containsKey('_id') ? json['_id'] : json.containsKey('id') ? json['id'] : '';
    this.uName = json['uName'] ?? '';
    this.neighborhoodUName = json['neighborhoodUName'] ?? '';
    this.title = json['title'] ?? '';
    this.description = json['description'] ?? '';
    this.imageUrls = _imageService.GetUrls(_parseService.parseListString(json['imageUrls'] != null ? json['imageUrls'] : []));
    this.currentOwnerUserId = json['currentOwnerUserId'] ?? '';
    this.currentGenerationStart = json['currentGenerationStart'] ?? '';
    this.currentPurchaserUserId = json['currentPurchaserUserId'] ?? '';
    this.tags = _parseService.parseListString(json['tags'] != null ? json['tags'] : []);
    this.location = LocationClass.fromJson(json['location'] ?? {});
    this.bought = json['bought'] != null ? _parseService.toIntNoNull(json['bought']) : 0;
    this.originalPrice = json['originalPrice'] != null ? _parseService.toDoubleNoNull(json['originalPrice']) : 1000;
    this.currentPrice = json['currentPrice'] != null ? _parseService.toDoubleNoNull(json['currentPrice']) : 1000;
    this.currency = json['currency'] ?? 'USD';
    this.generation = json['generation'] != null ? _parseService.toIntNoNull(json['generation']) : 0;
    this.monthsToPayBack = json['monthsToPayBack'] != null ? _parseService.toIntNoNull(json['monthsToPayBack']) : 12;
    this.maintenancePerYear = json['maintenancePerYear'] != null ? _parseService.toDoubleNoNull(json['maintenancePerYear']) : 50;
    this.maintenanceAvailable = json['maintenanceAvailable'] != null ? _parseService.toDoubleNoNull(json['maintenanceAvailable']) : 0;
    this.minOwners = json.containsKey('minOwners') ? _parseService.toIntNoNull(json['minOwners']) : 1;
    this.maxOwners = json.containsKey('maxOwners') ? _parseService.toIntNoNull(json['maxOwners']) : 10;
    this.maxMeters = json.containsKey('maxMeters') ? _parseService.toDoubleNoNull(json['maxMeters']) : 1500;
    this.status = json['status'] ?? '';
    this.pledgedOwners = json.containsKey('pledgedOwners') ? _parseService.toIntNoNull(json['pledgedOwners']) : 0;
    this.fundingRequired = json.containsKey('fundingRequired') ? _parseService.toDoubleNoNull(json['fundingRequired']) : 0;

    // this.xOwner = json['xOwner'] != null ? json['xOwner'] : {};
    this.xDistanceKm = json.containsKey('xDistanceKm') ? _parseService.toDoubleNoNull(json['xDistanceKm']) : -999;
    this.sharedItemOwner_current = json.containsKey('sharedItemOwner_current') ?
      SharedItemOwnerClass.fromJson(json['sharedItemOwner_current']) : SharedItemOwnerClass.fromJson({});
  }

  Map<String, dynamic> toJson() =>
    {
      '_id': id,
      'uName': uName,
      'neighborhoodUName': neighborhoodUName,
      'title': title,
      'description': description,
      'imageUrls': imageUrls,
      'currentOwnerUserId': currentOwnerUserId,
      'currentGenerationStart': currentGenerationStart,
      'currentPurchaserUserId': currentPurchaserUserId,
      'tags': tags,
      'location': { 'type': 'Point', 'coordinates': location.coordinates },
      'bought': bought,
      'originalPrice': originalPrice,
      'currentPrice': currentPrice,
      'currency': currency,
      'generation': generation,
      'monthsToPayBack': monthsToPayBack,
      'maintenancePerYear': maintenancePerYear,
      'maintenanceAvailable': maintenanceAvailable,
      'minOwners': minOwners,
      'maxOwners': maxOwners,
      'maxMeters': maxMeters,
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
