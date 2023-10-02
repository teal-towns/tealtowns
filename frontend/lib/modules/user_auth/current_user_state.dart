import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';

import '../../common/localstorage_service.dart';
import '../../common/socket_service.dart';
import './user_class.dart';

class CurrentUserState extends ChangeNotifier {
  SocketService _socketService = SocketService();
  LocalstorageService _localstorageService = LocalstorageService();

  var _currentUser = null;
  bool _isLoggedIn = false;
  LocalStorage? _localstorage = null;
  List<String> _routeIds = [];
  String _status = "done";

  get isLoggedIn => _isLoggedIn;

  get currentUser => _currentUser;

  get status => _status;

  void init() {
    if (_routeIds.length == 0) {
      _routeIds.add(_socketService.onRoute('getUserSession', callback: (String resString) {
        var res = json.decode(resString);
        var data = res['data'];
        if (data['valid'] == 1 && data.containsKey('user')) {
          var user = UserClass.fromJson(data['user']);
          if (user.id.length > 0) {
            setCurrentUser(user);
          }
        }
        _status = "done";
      }));

      _routeIds.add(_socketService.onRoute('logout', callback: (String resString) {
        _status = "done";
      }));
    }
  }

  void getLocalstorage() {
    if (_localstorage == null) {
      init();
      _localstorage = _localstorageService.localstorage;
    }
  }

  void setCurrentUser(var user) {
    _currentUser = user;
    _isLoggedIn = true;
    _socketService.setAuth(user.id, user.sessionId);

    getLocalstorage();
    _localstorage?.setItem('currentUser', _currentUser.toJson());

    notifyListeners();
  }

  void clearUser() {
    _currentUser = null;
    _isLoggedIn = false;
    _socketService.setAuth('', '');

    getLocalstorage();
    _localstorage?.deleteItem('currentUser');

    notifyListeners();
  }

  void checkAndLogin() {
    getLocalstorage();
    var user = _localstorage?.getItem('currentUser');
    if (user != null) {
      _status = "loading";
      _socketService.emit('getUserSession', { 'userId': user['id'], 'sessionId': user['sessionId'] });
    }
  }

  void logout() {
    if (_currentUser != null) {
      _status = "loading";
      _socketService.emit('logout', { 'userId': _currentUser.id, 'sessionId': _currentUser.sessionId });
    }
  }

  bool hasRole(String role) {
    if (_currentUser != null) {
      List<String> roles = _currentUser.roles.split(",");
      if (roles.contains(role)) {
        return true;
      }
    }
    return false;
  }
}