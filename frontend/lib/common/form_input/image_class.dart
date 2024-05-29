class ImageClass {
  String id, url, title, userIdCreator;
  ImageClass(this.id, this.url, this.title, this.userIdCreator);
  ImageClass.fromJson(Map<String, dynamic> json)
    :
      id = json['_id'],
      url = json['url'],
      title = json['title'],
      userIdCreator = json['userIdCreator']
    ;

  Map<String, dynamic> toJson() =>
    {
      '_id': id,
      'url': url,
      'title': title,
      'userIdCreator': userIdCreator,
    };
}

//class ImagesClass {
//  List<ImageClass> images;

//  //ImagesClass.fromJson(Map<String, dynamic> json)
//  //  :
//  //    id = json['_id'],
//  //    url = json['url'],
//  //    title = json['title'],
//  //    userIdCreator = json['userIdCreator'],
//  //  ;
//}
