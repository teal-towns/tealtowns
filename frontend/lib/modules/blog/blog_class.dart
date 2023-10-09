class BlogClass {
  String? id, title, slug, text, imageUrl, imageCredit, userIdCreator, createdAt;
  List<String> tags = [];
  BlogClass(this.id, this.title, this.slug, this.text, this.imageUrl, this.imageCredit, this.userIdCreator, this.createdAt,
    this.tags);
  BlogClass.fromJson(Map<String, dynamic> json) {
    this.id = json.containsKey('_id') ? json['_id'] : '';
    this.title = json.containsKey('title') ? json['title'] : '';
    this.slug = json.containsKey('slug') ? json['slug'] : '';
    this.userIdCreator = json.containsKey('userIdCreator') ? json['userIdCreator'] : '';
    this.text = json.containsKey('text') ? json['text'] : '';
    this.imageUrl = json.containsKey('imageUrl') ? json['imageUrl'] : '';
    this.imageCredit = json.containsKey('imageCredit') ? json['imageCredit'] : '';
    this.createdAt = json.containsKey('createdAt') ? json['createdAt'] : '';
    this.tags = parseTags(json['tags'] != null ? json['tags'] : []);
  }

  Map<String, dynamic> toJson() =>
    {
      'id': id,
      'title': title,
      'slug': slug,
      'userIdCreator': userIdCreator,
      'text': text,
      'imageUrl': imageUrl,
      'imageCredit': imageCredit,
      'createdAt': createdAt
    };

  List<String> parseTags(List<dynamic> tagsRaw) {
    List<String> tags = [];
    if (tagsRaw != null) {
      for (var tag in tagsRaw) {
        tags.add(tag);
      }
    }
    return tags;
  }
}
