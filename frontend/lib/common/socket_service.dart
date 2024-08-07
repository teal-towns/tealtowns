import 'dart:convert';
import 'dart:math';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';

class SocketService {
  SocketService._privateConstructor();
  static final SocketService _instance = SocketService._privateConstructor();
  factory SocketService() {
    return _instance;
  }

  Mixpanel? _mixpanel = null;
  get mixpanel => _mixpanel;

  // One of each per server.
  var _channels = {};
  var _callbacksByRoute = {};
  var _auth = {};
  Map<String, dynamic> _infoByServer = {};

  void connect(urlsMap) {
    urlsMap.forEach((serverKey, url) {
      _infoByServer[serverKey] = {
        'status': '',
      };
      ConnectOne(serverKey, url);
      _callbacksByRoute[serverKey] = {};
      _auth[serverKey] = {
        'userId': '',
        'sessionId': '',
      };
    });
  }

  void ConnectOne(serverKey, url) {
    if (_infoByServer[serverKey]['status'] != 'connected') {
      try {
        _channels[serverKey] = WebSocketChannel.connect(Uri.parse(url));
        _infoByServer[serverKey]['status'] = 'connected';
        print ('Socket connected to ${url}');

        _channels[serverKey].stream.listen((message) {
          handleMessage(message, serverKey);
        }, onError: (e) {
          Reconnect(serverKey, url);
        }, onDone: (() {
          Reconnect(serverKey, url);
        }));
      } catch (e) {
        Reconnect(serverKey, url);
      }
    }
  }

  void Reconnect(serverKey, url) {
    if (_infoByServer[serverKey]['status'] == 'connected') {
      print ('Socket disconnected, waiting then reconnecting..');
      _infoByServer[serverKey]['status'] = 'disconnected';
      Future.delayed(Duration(seconds: 5)).then((value) {
        ConnectOne(serverKey, url);
      });
    }
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

  String emit(String route, var data, {String serverKey = 'default'}) {
    String emitId = new Random().nextInt(1000000).toString();
    var auth1 = _auth[serverKey];
    auth1['_emitId'] = emitId;
    String message = jsonEncode({
      'route': route,
      'auth': auth1,
      'data': data,
    });
    _channels[serverKey].sink.add(utf8.encode(message));

    List<String> skipRoutes = ['GetGitSha', 'getUserSession'];
    if (_mixpanel != null && !skipRoutes.contains(route)) {
      _mixpanel!.track(route);
    }
    return emitId;
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

  void SetMixpanel(Mixpanel mixpanel) {
    _mixpanel = mixpanel;
  }
}