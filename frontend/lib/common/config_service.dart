class ConfigService {
  ConfigService._privateConstructor();
  static final ConfigService _instance = ConfigService._privateConstructor();
  factory ConfigService() {
    return _instance;
  }

  Map<String, dynamic> _config = {};

  void SetConfig(Map<String, dynamic> config) {
    _config = config;
  }

  Map<String, dynamic> GetConfig() {
    return _config;
  }

  String GetUrl(String urlPart, { bool withScheme = true }) {
    String url = '${_config['SERVER_URL']}${urlPart}';
    String search = '://';
    int index = url.indexOf(search);
    if (!withScheme && index > 0) {
      url = url.substring(index + search.length);
    }
    return url;
  }
}