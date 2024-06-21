import 'dart:convert';
import 'package:flutter/material.dart';

import '../../common/parse_service.dart';
import '../../common/socket_service.dart';
import '../../common/style.dart';
import '../../app_scaffold.dart';

class AppInsights extends StatefulWidget {
  @override
  _AppInsightsState createState() => _AppInsightsState();
}

class _AppInsightsState extends State<AppInsights> {
  ParseService _parseService = ParseService();
  List<String> _routeIds = [];
  SocketService _socketService = SocketService();
  Style _style = Style();

  int _uniqueEventViews = 0;
  int _eventSignUps = 0;
  int _uniqueSignUpViews = 0;
  int _userSignUps = 0;
  int _activeUsers = 0;
  int _totalUsers = 0;
  var _hoursToFirstAction = {
    'eventSignUp': -1.0,
    'neighborhoodJoin': -1.0,
  };

  @override
  void initState() {
    super.initState();

    _routeIds.add(_socketService.onRoute('GetAppInsights', callback: (String resString) {
      var res = json.decode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        _hoursToFirstAction = {
          'eventSignUp': _parseService.toDoubleNoNull(data['hoursToFirstAction']['eventSignUp']),
          'neighborhoodJoin': _parseService.toDoubleNoNull(data['hoursToFirstAction']['neighborhoodJoin']),
        };
        setState(() { _uniqueEventViews = data['uniqueEventViews']; _eventSignUps = data['eventSignUps'];
          _uniqueSignUpViews = data['uniqueSignUpViews']; _userSignUps = data['userSignUps'];
          _activeUsers = data['activeUsers']; _totalUsers = data['totalUsers'];
          _hoursToFirstAction = _hoursToFirstAction;
        });
      }
    }));

    _socketService.emit('GetAppInsights', {});
  }

  @override
  void dispose() {
    _socketService.offRouteIds(_routeIds);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double eventPercent = 100;
    if (_uniqueEventViews > 0) {
      eventPercent = (_eventSignUps / _uniqueEventViews) * 100;
    }
    double signUpPercent = 100;
    if (_uniqueSignUpViews > 0) {
      signUpPercent = (_userSignUps / _uniqueSignUpViews) * 100;
    }
    double activeUserPercent = 100;
    if (_totalUsers > 0) {
      activeUserPercent = (_activeUsers / _totalUsers) * 100;
    }
    return AppScaffoldComponent(
      listWrapper: true,
      body: Column(
        children: [
          _style.Text1('App Insights (Last 30 Days)', size: 'large'),
          _style.SpacingH('medium'),
          _style.Text1('Event Sign Ups / Unique Event Views: ${eventPercent.toStringAsFixed(2)}% (${_eventSignUps} / ${_uniqueEventViews})'),
          _style.SpacingH('medium'),
          _style.Text1('User Sign Ups / Unique Sign Up Views: ${signUpPercent.toStringAsFixed(2)}% (${_userSignUps} / ${_uniqueSignUpViews})'),
          _style.SpacingH('medium'),
          _style.Text1('Active / Total Users: ${activeUserPercent.toStringAsFixed(2)}% (${_activeUsers} / ${_totalUsers})'),
          _style.SpacingH('medium'),
          _style.Text1('Hours to First Action'),
          _style.SpacingH('medium'),
          _style.Text1('Event Sign Up: ${_hoursToFirstAction['eventSignUp']!.toStringAsFixed(2)}'),
          _style.SpacingH('medium'),
          _style.Text1('Neighborhood Join: ${_hoursToFirstAction['neighborhoodJoin']!.toStringAsFixed(2)}'),
        ]
      ) 
    );
  }
}