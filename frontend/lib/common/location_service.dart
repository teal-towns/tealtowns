import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';

import './localstorage_service.dart';
import './parse_service.dart';
import '../modules/user_auth/current_user_state.dart';

class LocationService {
  LocationService._privateConstructor();
  static final LocationService _instance = LocationService._privateConstructor();
  factory LocationService() {
    return _instance;
  }

  Location _location = Location();
  LocalstorageService _localstorageService = LocalstorageService();
  ParseService _parseService = ParseService();

  LocalStorage? _localstorage = null;
  // Cached version.
  List<double> _lngLat = [0, 0];

  List<double> GetLngLat() {
    if (!LocationValid(_lngLat)) {
      getLocalstorage();
      LocalStorage _localStorage = _localstorageService.localstorage;
      List<dynamic>? lngLatLocalStored = _localStorage.getItem('locationLngLat');
      if (lngLatLocalStored != null) {
        List<double> lngLat = [lngLatLocalStored[0], lngLatLocalStored[1]];
        return lngLat;
      }
    }
    return _lngLat;
  }

  void getLocalstorage() {
    if (_localstorage == null) {
      _localstorage = _localstorageService.localstorage;
    }
  }

  void SetLngLat(List<double> lngLat) {
    _lngLat = lngLat;
    getLocalstorage();
    _localstorage?.setItem('locationLngLat', [lngLat[0], lngLat[1]]);
  }

  bool LocationValid(List<double> lngLat) {
    if ((lngLat[0] == 0 && lngLat[1] == 0) || (lngLat[0] == -999 && lngLat[1] == -999)) {
      return false;
    }
    return true;
  }

  List<double> ToPrecision(List<double> lngLat) {
    return [_parseService.Precision(lngLat[0], 5), _parseService.Precision(lngLat[1], 5)];
  }

  bool IsDifferent(List<double> lngLat1, List<double> lngLat2) {
    if (ToPrecision(lngLat1) == ToPrecision(lngLat2)) {
      return false;
    }
    return true;
  }

  Future<List<double>> GetLocation(BuildContext context, {bool useUser = true, bool useCache = true}) async {
    if (useCache && LocationValid(_lngLat)) {
      return _lngLat;
    }
    var currentUser = Provider.of<CurrentUserState>(context, listen: false).currentUser;
    List<double> lngLat = [0, 0];
    if (useUser && currentUser != null && currentUser.location.coordinates.length > 0 &&
      LocationValid(currentUser.location.coordinates)) {
      lngLat = [_parseService.Precision(currentUser.location.coordinates[0], 5),
        _parseService.Precision(currentUser.location.coordinates[1], 5)];
      SetLngLat(lngLat);
    }
    else {
      var coordinates = await _location.getLocation();
      if (coordinates.latitude != null) {
        lngLat = [_parseService.Precision(coordinates.longitude!, 5),
          _parseService.Precision(coordinates.latitude!, 5)];
        SetLngLat(lngLat);
      }
    }
    return _lngLat;
  }

}