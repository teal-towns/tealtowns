import './config_service.dart';

class ImageService {
  ImageService._privateConstructor();
  static final ImageService _instance = ImageService._privateConstructor();
  factory ImageService() {
    return _instance;
  }

  ConfigService _configService = ConfigService();

  String GetUrl(String url, {bool replaceLocalhost = true}) {
    if (replaceLocalhost) {
      Map<String, dynamic> config = _configService.GetConfig();
      if (!url.contains(config['SERVER_URL']) &&
        (config['SERVER_URL'].contains('127.0.0.1') || config['SERVER_URL'].contains('localhost'))) {
        url = config['SERVER_URL'] + url;
      }
    }
    return url;
  }

  List<String> GetUrls(List<String> urls, {bool replaceLocalhost = true}) {
    for (int ii = 0; ii < urls.length; ii++) {
      urls[ii] = GetUrl(urls[ii], replaceLocalhost: replaceLocalhost);
    }
    return urls;
  }
}