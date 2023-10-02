import 'dart:math';

class LodashService {
  LodashService._privateConstructor();
  static final LodashService _instance = LodashService._privateConstructor();
  factory LodashService() {
    return _instance;
  }

  final _random = new Random();

  String randomString({ int length = 16 }) {
    String text = '';
    String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    int charsLen = chars.length;
    int counter = 0;
    int min = 0;
    while (counter < length) {
      int index = min + _random.nextInt(charsLen - min);
      text = text + chars[index];
      counter += 1;
    }
    return text;
  }
}