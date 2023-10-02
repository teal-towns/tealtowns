  
class LayoutService {
  LayoutService._privateConstructor();
  static final LayoutService _instance = LayoutService._privateConstructor();
  factory LayoutService() {
    return _instance;
  }

  double _headerHeight = 55;

  get headerHeight => _headerHeight;
}
