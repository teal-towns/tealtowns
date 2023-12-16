import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';

import './parse_service.dart';
import '../modules/user_auth/current_user_state.dart';

class LocationService {
  LocationService._privateConstructor();
  static final LocationService _instance = LocationService._privateConstructor();
  factory LocationService() {
    return _instance;
  }

  Location _location = Location();
  ParseService _parseService = ParseService();

  // Cached version.
  List<double> _lngLat = [0, 0];

  List<double> GetLngLat() {
    return _lngLat;
  }

  bool LocationValid(List<double> lngLat) {
    if ((lngLat[0] == 0 && lngLat[1] == 0) || (lngLat[0] == -999 && lngLat[1] == -999)) {
      return false;
    }
    return true;
  }

  List<double> ToPrecision(List<double> lngLat) {
    return [_parseService.Precision(lngLat[0], 6), _parseService.Precision(lngLat[1], 6)];
  }

  bool IsDifferent(List<double> lngLat1, List<double> lngLat2) {
    if (ToPrecision(lngLat1) == ToPrecision(lngLat2)) {
      return false;
    }
    return true;
  }

  Future<List<double>> GetLocation(BuildContext context) async {
    var currentUser = Provider.of<CurrentUserState>(context, listen: false).currentUser;
    if (currentUser != null && currentUser.location.coordinates.length > 0) {
      _lngLat = [_parseService.Precision(currentUser.location.coordinates[0], 6),
        _parseService.Precision(currentUser.location.coordinates[1], 6)];
    }
    else {
      var coordinates = await _location.getLocation();
      if (coordinates.latitude != null) {
        _lngLat = [_parseService.Precision(coordinates.longitude!, 6),
          _parseService.Precision(coordinates.latitude!, 6)];
      }
    }
    return _lngLat;
  }

}