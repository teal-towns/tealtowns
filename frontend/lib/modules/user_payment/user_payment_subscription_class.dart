import '../../common/parse_service.dart';

class UserPaymentSubscriptionClass {
  ParseService _parseService = ParseService();

  String id = '', userId = '', recurringInterval = '', forType = '', forId = '', status = '', stripeId = '', createdAt = '', updatedAt = '';
  String forLink = '';
  double amountUSD = 0;
  int recurringIntervalCount = 1;

  UserPaymentSubscriptionClass(this.id, this.userId, this.recurringInterval, this.forType, this.forId, this.status, this.stripeId,
    this.amountUSD, this.recurringIntervalCount, this.createdAt, this.updatedAt, this.forLink);

  UserPaymentSubscriptionClass.fromJson(Map<String, dynamic> json) {
    this.id = json.containsKey('_id') ? json['_id'] : json.containsKey('id') ? json['id'] : '';
    this.userId = json['userId'] ?? '';
    this.recurringInterval = json['recurringInterval'] ?? '';
    this.forType = json['forType'] ?? '';
    this.forId = json['forId'] ?? '';
    this.status = json['status'] ?? '';
    this.stripeId = json['stripeId'] ?? '';
    this.createdAt = json['createdAt'] ?? '';
    this.updatedAt = json['updatedAt'] ?? '';
    this.amountUSD = json['amountUSD'] != null ? _parseService.toDoubleNoNull(json['amountUSD']) : 0;
    this.recurringIntervalCount = json['recurringIntervalCount'] != null ? _parseService.toIntNoNull(json['recurringIntervalCount']) : 1;
    this.forLink = json['forLink'] ?? '';
  }

}