import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';

import './neighborhood_class.dart';
import './user_neighborhood_class.dart';
import '../../common/localstorage_service.dart';
import '../../common/socket_service.dart';

class NeighborhoodState extends ChangeNotifier {
  SocketService _socketService = SocketService();
  LocalstorageService _localstorageService = LocalstorageService();

  LocalStorage? _localstorage = null;
  List<String> _routeIds = [];
  // String _status = "done";

  List<UserNeighborhoodClass> _userNeighborhoods = [];
  UserNeighborhoodClass? _defaultUserNeighborhood = null;

  get userNeighborhoods => _userNeighborhoods;
  get defaultUserNeighborhood => _defaultUserNeighborhood;

  void Init() {
    if (_routeIds.length == 0) {
      _routeIds.add(_socketService.onRoute('SearchUserNeighborhoods', callback: (String resString) {
        var res = json.decode(resString);
        var data = res['data'];
        if (data['valid'] == 1 && data.containsKey('userNeighborhoods')) {
          List<UserNeighborhoodClass> userNeighborhoods = [];
          for (var i = 0; i < data['userNeighborhoods'].length; i++) {
            userNeighborhoods.add(UserNeighborhoodClass.fromJson(data['userNeighborhoods'][i]));
          }
          SetUserNeighborhoods(userNeighborhoods);
        }
        // _status = "done";
      }));
    }
  }

  void GetLocalstorage() {
    if (_localstorage == null) {
      Init();
      _localstorage = _localstorageService.localstorage;
    }
  }

  void CheckAndGet(String userId, {bool notify = true}) {
    GetLocalstorage();
    List<dynamic>? _localStorageUserNeighborhoods = _localstorage?.getItem('userNeighborhoods');
    print ('neighborhoods $userId $_localStorageUserNeighborhoods');
    List<UserNeighborhoodClass> userNeighborhoods = _localStorageUserNeighborhoods != null ?
      UserNeighborhoodClass.parseList(_localStorageUserNeighborhoods) : [];
    print ('userNeighborhoods.length ${userNeighborhoods.length}');
    if (userNeighborhoods.length < 1) {
      // _status = "loading";
      _socketService.emit('SearchUserNeighborhoods', { 'userId': userId, 'withNeighborhoods': 1, });
    } else {
      SetUserNeighborhoods(userNeighborhoods, notify: notify);
    }
  }

  void SetUserNeighborhoods(List<UserNeighborhoodClass> userNeighborhoods, {bool notify = true}) {
    _userNeighborhoods = userNeighborhoods;
    for (var i = 0; i < _userNeighborhoods.length; i++) {
      if (_userNeighborhoods[i].status == 'default') {
        _defaultUserNeighborhood = _userNeighborhoods[i];
      }
    }

    GetLocalstorage();
    _localstorage?.setItem('userNeighborhoods', UserNeighborhoodClass.toJsonList(userNeighborhoods));

    if (notify) {
      notifyListeners();
    }
  }

  void ClearUserNeighborhoods({bool notify = true}) {
    _userNeighborhoods = [];
    _defaultUserNeighborhood = null;

    GetLocalstorage();
    _localstorage?.deleteItem('userNeighborhoods');

    if (notify) {
      notifyListeners();
    }
  }
}
