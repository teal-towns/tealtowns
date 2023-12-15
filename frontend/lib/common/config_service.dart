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
}