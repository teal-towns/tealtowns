import '../../common/parse_service.dart';

class UserPaymentClass {
  ParseService _parseService = ParseService();

  String id = '', forType = '', forId = '', status = '', notes = '', createdAt = '', updatedAt = '';
  double amountUSD = 0, amountUSDPreFee = 0;

  UserPaymentClass(this.id, this.forType, this.forId, this.status, this.notes, this.amountUSD, this.amountUSDPreFee,
    this.createdAt, this.updatedAt);

  UserPaymentClass.fromJson(Map<String, dynamic> json) {
    double amountUSD = json['amountUSD'] != null ? _parseService.toDoubleNoNull(json['amountUSD']) : 0;
    this.id = json.containsKey('_id') ? json['_id'] : json.containsKey('id') ? json['id'] : '';
    this.forType = json['forType'] ?? '';
    this.forId = json['forId'] ?? '';
    this.status = json['status'] ?? '';
    this.notes = json['notes'] ?? '';
    this.amountUSD = amountUSD;
    this.amountUSDPreFee = json['amountUSDPreFee'] != null ? _parseService.toDoubleNoNull(json['amountUSDPreFee']) : amountUSD;
    this.createdAt = json['createdAt'] ?? '';
    this.updatedAt = json['updatedAt'] ?? '';
  }

}