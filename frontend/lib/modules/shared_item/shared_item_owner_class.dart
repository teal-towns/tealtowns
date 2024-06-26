import '../../common/parse_service.dart';

class SharedItemOwnerClass {
  ParseService _parseService = ParseService();

  String id = '', sharedItemId = '', userId = '', status = '';
  double monthlyPayment = 0, totalPaid = 0, totalOwed = 0, totalPaidBack = 0;
  int generation = 0, investorOnly = 0;
  SharedItemOwnerClass(this.id, this.sharedItemId, this.userId, this.monthlyPayment, this.totalPaid,
    this.totalOwed, this.totalPaidBack, this.generation, this.investorOnly, this.status);

  SharedItemOwnerClass.fromJson(Map<String, dynamic> json) {
    this.id = json.containsKey('_id') ? json['_id'] : json.containsKey('id') ? json['id'] : '';
    this.sharedItemId = json['sharedItemId'] ?? '';
    this.userId = json['userId'] ?? '';
    this.monthlyPayment = json['monthlyPayment'] != null ? _parseService.toDoubleNoNull(json['monthlyPayment']) : 0;
    this.totalPaid = json['totalPaid'] != null ? _parseService.toDoubleNoNull(json['totalPaid']) : 0;
    this.totalOwed = json['totalOwed'] != null ? _parseService.toDoubleNoNull(json['totalOwed']) : 0;
    this.totalPaidBack = json['totalPaidBack'] != null ? _parseService.toDoubleNoNull(json['totalPaidBack']) : 0;
    this.generation = json['generation'] != null ? _parseService.toIntNoNull(json['generation']) : 0;
    this.investorOnly = json['investorOnly'] != null ? _parseService.toIntNoNull(json['investorOnly']) : 0;
    this.status = json['status'] ?? '';
  }

  Map<String, dynamic> toJson() =>
    {
      '_id': id,
      'sharedItemId': sharedItemId,
      'userId': userId,
      'monthlyPayment': monthlyPayment,
      'totalPaid': totalPaid,
      'totalOwed': totalOwed,
      'totalPaidBack': totalPaidBack,
      'generation': generation,
      'investorOnly': investorOnly,
      'status': status
    };
}
