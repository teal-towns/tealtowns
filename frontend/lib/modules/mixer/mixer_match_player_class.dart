import '../../common/parse_service.dart';

class MixerMatchPlayerClass {
  ParseService _parseService = ParseService();

  String id = '', mixerGameUName = '', userId = '', name = '', answer = '';
  // int score = 0;

  MixerMatchPlayerClass(this.id, this.mixerGameUName, this.userId, this.name, this.answer);

  MixerMatchPlayerClass.fromJson(Map<String, dynamic> json) {
    this.id = json.containsKey('_id') ? json['_id'] : json.containsKey('id') ? json['id'] : '';
    this.mixerGameUName = json['mixerGameUName'] ?? '';
    this.userId = json['userId'] ?? '';
    this.name = json['name'] ?? '';
    this.answer = json['answer'] ?? '';
    // this.score = json['score'] ?? 0;
  }

  Map<String, dynamic> toJson() =>
    {
      '_id': id,
      'mixerGameUName': mixerGameUName,
      'userId': userId,
      'name': name,
      'answer': answer,
      // 'score': score,
    };
}
