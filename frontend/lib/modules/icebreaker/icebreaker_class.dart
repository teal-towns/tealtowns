class IcebreakerClass {
  String id = '', icebreaker = '', details = '';

  IcebreakerClass(this.id, this.icebreaker, this.details);

  IcebreakerClass.fromJson(Map<String, dynamic> json) {
    this.id = json.containsKey('_id') ? json['_id'] : json.containsKey('id') ? json['id'] : '';
    this.icebreaker = json['icebreaker'] ?? '';
    this.details = json['details'] ?? '';
  }

  Map<String, dynamic> toJson() =>
    {
      '_id': id,
      'icebreaker': icebreaker,
      'details': details,
    };
}
