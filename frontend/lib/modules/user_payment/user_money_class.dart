import '../../common/parse_service.dart';

class UserMoneyClass {
  ParseService _parseService = ParseService();

  String id = '', userId = '';
  double balanceUSD = 0;

  UserMoneyClass(this.id, this.userId, this.balanceUSD);

  UserMoneyClass.fromJson(Map<String, dynamic> json) {
    this.id = json.containsKey('_id') ? json['_id'] : json.containsKey('id') ? json['id'] : '';
    this.userId = json['userId'] ?? '';
    this.balanceUSD = json['balanceUSD'] != null ? _parseService.toDoubleNoNull(json['balanceUSD']) : 0;
  }

}