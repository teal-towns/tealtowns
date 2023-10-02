import 'dart:convert';
import 'dart:math';
import 'package:web_socket_channel/web_socket_channel.dart';

class SocketService {
  SocketService._privateConstructor();
  static final SocketService _instance = SocketService._privateConstructor();
  factory SocketService() {
    return _instance;
  }

  // One of each per server.
  var _channels = {};
  var _callbacksByRoute = {};
  var _auth = {};

  void connect(urlsMap) {
    urlsMap.forEach((serverKey, url) {
      _channels[serverKey] = WebSocketChannel.connect(Uri.parse(url));

      _channels[serverKey].stream.listen((message) {
        handleMessage(message, serverKey);
      });

      _callbacksByRoute[serverKey] = {};
      _auth[serverKey] = {
        'userId': '',
        'sessionId': '',
      };
    });
  }

  void handleMessage(message, serverKey) {
    String resString = utf8.decode(message);
    var res = jsonDecode(resString);
    String resString1 = jsonEncode(res);
    if (res.containsKey('route') && _callbacksByRoute[serverKey].containsKey(res['route'])) {
      for (var id in _callbacksByRoute[serverKey][res['route']].keys) {
        _callbacksByRoute[serverKey][res['route']][id]['callback'](resString1);
      }
    }
  }

  void disconnect(String serverKey) {
    _channels[serverKey].sink.close();
  }

  void emit(String route, var data, {String serverKey = 'default'}) {
    String message = jsonEncode({
      'route': route,
      'auth': _auth[serverKey],
      'data': data,
    });
    _channels[serverKey].sink.add(utf8.encode(message));
  }

  String onRoute(String route, {Function(String)? callback, String serverKey = 'default'}) {
    if (!_callbacksByRoute[serverKey].containsKey(route)) {
      _callbacksByRoute[serverKey][route] = {};
    }
    String id = new Random().nextInt(1000000).toString();
    _callbacksByRoute[serverKey][route][id] = {
      'callback': callback,
    };
    return id;
  }

  void offRoute(String route, String id, {String serverKey = 'default'}) {
    if (_callbacksByRoute[serverKey].containsKey(route)) {
      _callbacksByRoute[serverKey][route].remove(id);
    }
  }

  void offRouteIds(List<String> routeIds, {String serverKey = 'default'}) {
    for (var ii = 0; ii < routeIds.length; ii++) {
    //routeIds.forEach((String routeId) =>
      String routeId = routeIds[ii];
      for (String route in _callbacksByRoute[serverKey].keys) {
        bool found = false;
        for (String id in _callbacksByRoute[serverKey][route].keys) {
          if (id == routeId) {
            _callbacksByRoute[serverKey][route].remove(id);
            found = true;
            break;
          }
        }
        if (found) {
            break;
        }
      }
    }
  }

  void setAuth(String userId, String sessionId, {String serverKey = 'default'}) {
    _auth[serverKey] = {};
    _auth[serverKey]['userId'] = userId;
    _auth[serverKey]['sessionId'] = sessionId;
  }
}