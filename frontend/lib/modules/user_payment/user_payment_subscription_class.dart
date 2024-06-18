import '../../common/parse_service.dart';

class UserPaymentSubscriptionClass {
  ParseService _parseService = ParseService();

  String id = '', userId = '', recurringInterval = '', forType = '', forId = '', status = '', createdAt = '', updatedAt = '';
  String forLink = '';
  double amountUSD = 0;
  int recurringIntervalCount = 1, quantity = 1, credits = 0;
  Map<String, dynamic> stripeIds = {};

  UserPaymentSubscriptionClass(this.id, this.userId, this.recurringInterval, this.forType, this.forId, this.status,
    this.amountUSD, this.recurringIntervalCount, this.quantity, this.credits, this.createdAt, this.updatedAt, this.forLink, this.stripeIds,);

  UserPaymentSubscriptionClass.fromJson(Map<String, dynamic> json) {
    this.id = json.containsKey('_id') ? json['_id'] : json.containsKey('id') ? json['id'] : '';
    this.userId = json['userId'] ?? '';
    this.recurringInterval = json['recurringInterval'] ?? '';
    this.forType = json['forType'] ?? '';
    this.forId = json['forId'] ?? '';
    this.status = json['status'] ?? '';
    this.stripeIds = json['stripeIds'] != null ? _parseService.parseMapStringDynamic(json['stripeIds']) : {};
    this.createdAt = json['createdAt'] ?? '';
    this.updatedAt = json['updatedAt'] ?? '';
    this.amountUSD = json['amountUSD'] != null ? _parseService.toDoubleNoNull(json['amountUSD']) : 0;
    this.recurringIntervalCount = json['recurringIntervalCount'] != null ? _parseService.toIntNoNull(json['recurringIntervalCount']) : 1;
    this.quantity = json['quantity'] != null ? _parseService.toIntNoNull(json['quantity']) : 1;
    this.credits = json['credits'] != null ? _parseService.toIntNoNull(json['credits']) : 0;
    this.forLink = json['forLink'] ?? '';
  }

}