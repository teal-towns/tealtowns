import '../../common/parse_service.dart';

class UserPaymentClass {
  ParseService _parseService = ParseService();

  String id = '', forType = '', forId = '', status = '', notes = '', createdAt = '', updatedAt = '';
  double amountUSD = 0;

  UserPaymentClass(this.id, this.forType, this.forId, this.status, this.notes, this.amountUSD, this.createdAt, this.updatedAt);

  UserPaymentClass.fromJson(Map<String, dynamic> json) {
    this.id = json.containsKey('_id') ? json['_id'] : json.containsKey('id') ? json['id'] : '';
    this.forType = json['forType'] ?? '';
    this.forId = json['forId'] ?? '';
    this.status = json['status'] ?? '';
    this.notes = json['notes'] ?? '';
    this.amountUSD = json['amountUSD'] != null ? _parseService.toDoubleNoNull(json['amountUSD']) : 0;
    this.createdAt = json['createdAt'] ?? '';
    this.updatedAt = json['updatedAt'] ?? '';
  }

}