import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';
import 'package:location/location.dart';
// import 'package:universal_html/html.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';

import '../../common/localstorage_service.dart';
import '../../common/socket_service.dart';
import './user_class.dart';
import './user_availability_class.dart';
import './user_interest_class.dart';

class CurrentUserState extends ChangeNotifier {
  SocketService _socketService = SocketService();
  LocalstorageService _localstorageService = LocalstorageService();

  UserClass? _currentUser;
  bool _isLoggedIn = false;
  LocalStorage? _localstorage = null;
  List<String> _routeIds = [];
  String _status = "done";
  List<String> _redirectUrls = [];
  List<String> _routerRedirectUrls = [];
  var _routerRedirectTimeout = null;
  Map<String, dynamic> _appData = {};
  UserAvailabilityClass _userAvailability = UserAvailabilityClass.fromJson({});
  UserInterestClass _userInterest = UserInterestClass.fromJson({});

  get isLoggedIn => _isLoggedIn;

  get currentUser => _currentUser;

  get status => _status;

  get redirectUrls => _redirectUrls;

  get routerRedirectUrls => _routerRedirectUrls;

  get appData => _appData;

  get userAvailability => _userAvailability;

  get userInterest => _userInterest;

  void init() {
    if (_routeIds.length == 0) {
      _routeIds.add(_socketService.onRoute('getUserSession', callback: (String resString) {
        var res = json.decode(resString);
        var data = res['data'];
        if (data['valid'] == 1 && data.containsKey('user')) {
          UserClass user = UserClass.fromJson(data['user']);
          if (user.id.length > 0) {
            setCurrentUser(user);
          }
          // if (data.containsKey('checkUserFeedback')) {
          //   if (data['checkUserFeedback']['missingFeedbackEventIds'].length > 0) {
          //   }
          // }
          bool redirectSet = false;
          if (data.containsKey('userInterest')) {
            SetUserInterest(UserInterestClass.fromJson(data['userInterest']));
            if (_userInterest.interests.length < 3 && !redirectSet) {
              _routerRedirectUrls.add('/user-interest-save');
              redirectSet = true;
            }
          }
          if (data.containsKey('userAvailability')) {
            SetUserAvailability(UserAvailabilityClass.fromJson(data['userAvailability']));
            int timesCount = 0;
            for (var day in _userAvailability.availableTimesByDay) {
              timesCount += day['times'].length as int;
            }
            if (timesCount < 3 && !redirectSet) {
              _routerRedirectUrls.add('/user-availability-save');
              redirectSet = true;
            }
          }
        } else {
          clearUser();
        }
        _status = "done";
      }));

      _routeIds.add(_socketService.onRoute('logout', callback: (String resString) {
        clearUser();
        _status = "done";
      }));
    }
  }

  // void OnSignUp() {
  //   AddRedirectUrl('/user-interest-save');
  // }

  void getLocalstorage() {
    if (_localstorage == null) {
      init();
      _localstorage = _localstorageService.localstorage;
    }
  }

  void SetAppData(Map<String, dynamic> appData) {
    for (String key in appData.keys) {
      _appData[key] = appData[key];
    }
    notifyListeners();
  }

  void ClearAppData() {
    _appData = {};
    notifyListeners();
  }

  void SetUserAvailability(UserAvailabilityClass userAvailability) {
    _userAvailability = userAvailability;
    notifyListeners();
  }

  void SetUserInterest(UserInterestClass userInterest) {
    _userInterest = userInterest;
    notifyListeners();
  }

  void setCurrentUser(UserClass user, {bool skipSession = false}) {
    if (skipSession && _currentUser != null) {
      user.sessionId = _currentUser!.sessionId;
    }
    _currentUser = user;
    OnSetUser(user);
    _isLoggedIn = true;
    _socketService.setAuth(user.id, user.sessionId);

    getLocalstorage();
    _localstorage?.setItem('currentUser', user.toJson());

    notifyListeners();
  }

  void OnSetUser(UserClass user) {
    // if (_mixpanel == null) {
    if (_socketService.mixpanel != null) {
      _socketService.mixpanel!.identify(user.id);
      _socketService.mixpanel!.getPeople().set("\$name", "${user.firstName} ${user.lastName}");
      _socketService.mixpanel!.getPeople().set("\$email", "${user.email}");
    }
  }

  void OnClearUser() {
    if (_socketService.mixpanel != null) {
      _socketService.mixpanel!.reset();
    }
  }

  void clearUser() {
    _currentUser = null;
    _isLoggedIn = false;
    _socketService.setAuth('', '');

    getLocalstorage();
    _localstorage?.deleteItem('currentUser');

    _routerRedirectUrls = [];
    _routerRedirectTimeout = null;

    notifyListeners();
  }

  void checkAndLogin() {
    getLocalstorage();
    Map<String, dynamic>? _localStorageUser = _localstorage?.getItem('currentUser');
    UserClass? user = _localStorageUser != null ? UserClass.fromJson(_localStorageUser) : null;
    if (user != null && user.id.length > 0 && user.sessionId.length > 0) {
      _status = "loading";
      _socketService.emit('getUserSession', {  'userId': user.id, 'sessionId': user.sessionId,
        'withCheckUserFeedback': 1, 'withUserInterest': 1, 'withUserAvailability': 1, });
      _currentUser = user;
      OnSetUser(user);
      _isLoggedIn = true;
    }
  }

  void logout() {
    if (_currentUser != null) {
      _status = "loading";
      _socketService.emit('logout', { 'userId': _currentUser!.id, 'sessionId': _currentUser!.sessionId });
    }
  }

  Future<List<dynamic>> getUserLocation() async {
    List<dynamic> _lngLat = [];
    LocalStorage _localStorage = _localstorageService.localstorage;
    List<dynamic>? _lngLatLocalStored = _localStorage.getItem('lngLat');
    if (_lngLatLocalStored != null) {
      _lngLat = _lngLatLocalStored;
    }
    else if (_currentUser != null && _currentUser?.location.coordinates != []) {
      _lngLat = _currentUser!.location.coordinates;
    } else {
      LocationData coordinates = await Location().getLocation();
      if (coordinates.latitude != null) {
        _localstorageService.localstorage.setItem('lngLat', [coordinates.longitude, coordinates.latitude]);
          _lngLat = [coordinates.longitude!, coordinates.latitude!];
      }
    }
    return _lngLat;
  }

  bool hasRole(String role) {
    if (_currentUser != null) {
      List<String> roles = _currentUser!.roles.split(",");
      if (roles.contains(role)) {
        return true;
      }
    }
    return false;
  }

  @override
  String toString() {
    return 'CurrentUserState{_currentUser: $_currentUser, _isLoggedIn: $_isLoggedIn, _routeIds: $_routeIds, _status: $_status}';
  }

  void AddRedirectUrl(String url, { bool remove = false}) {
    if (remove) {
      _redirectUrls = [];
    }
    _redirectUrls.add(url);
  }

  void ClearRedirectUrls() {
    _redirectUrls = [];
  }

  String GetRedirectUrl({ bool remove = true}) {
    if (_redirectUrls.length > 0) {
      String url = _redirectUrls[0];
      if (remove) {
        _redirectUrls.removeAt(0);
      }
      return url;
    }
    return '';
  }

  void AddRouterRedirectUrl(String url) {
    _routerRedirectUrls.add(url);
  }

  String GetRouterRedirectUrl({ bool remove = true}) {
    String currentUrl = Uri.base.toString();
    if (_routerRedirectUrls.length > 0 && (_routerRedirectTimeout == null || DateTime.now().isAfter(_routerRedirectTimeout!))) {
      _routerRedirectTimeout = DateTime.now().add(const Duration(minutes: 5));
      String url = _routerRedirectUrls[0];
      // AddRedirectUrl(currentUrl);
      if (remove) {
        _routerRedirectUrls.removeAt(0);
      }
      return url;
    }
    return '';
  }
}