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

  Future<List<double>> GetLocation(BuildContext context) async {
    var currentUser = Provider.of<CurrentUserState>(context, listen: false).currentUser;
    if (currentUser.location.coordinates.length > 0) {
      return [_parseService.Precision(currentUser.location.coordinates[0], 6),
        _parseService.Precision(currentUser.location.coordinates[1], 6)];
    }
    else {
      var coordinates = await _location.getLocation();
      if (coordinates.latitude != null) {
        return [_parseService.Precision(coordinates.longitude!, 6),
          _parseService.Precision(coordinates.latitude!, 6)];
      }
    }
    return [0, 0];
  }

}