import 'package:mixpanel_flutter/mixpanel_flutter.dart';

class TrackInsightService {
  TrackInsightService._privateConstructor();
  static final TrackInsightService _instance = TrackInsightService._privateConstructor();
  factory TrackInsightService() {
    return _instance;
  }

  Mixpanel? _mixpanel = null;
  get mixpanel => _mixpanel;

  void SetMixpanel(Mixpanel mixpanel) {
    _mixpanel = mixpanel;
  }

  void TrackEvent(String eventName, {Map<String, dynamic>? properties = const {}}) {
    if (_mixpanel != null) {
      _mixpanel!.track(eventName, properties: properties);
    }
  }
}