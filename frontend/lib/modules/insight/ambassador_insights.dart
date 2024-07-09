import 'dart:convert';
import 'package:flutter/material.dart';

import '../../common/buttons.dart';
import '../../common/date_time_service.dart';
import '../../common/parse_service.dart';
import '../../common/socket_service.dart';
import '../../common/style.dart';
import '../../app_scaffold.dart';
import '../user_auth/user_class.dart';

class AmbassadorInsights extends StatefulWidget {
  @override
  _AmbassadorInsightsState createState() => _AmbassadorInsightsState();
}

class _AmbassadorInsightsState extends State<AmbassadorInsights> {
  Buttons _buttons = Buttons();
  DateTimeService _dateTime = DateTimeService();
  ParseService _parseService = ParseService();
  List<String> _routeIds = [];
  SocketService _socketService = SocketService();
  Style _style = Style();

  int _ambassadorsSignUpCompleteCount = 0;
  List<Map<String, dynamic>> _userInsights = [];
  int _currentAmbassadorsCount = 0;
  List<UserClass> _usersNotCurrent = [];

  @override
  void initState() {
    super.initState();

    _routeIds.add(_socketService.onRoute('GetAmbassadorInsights', callback: (String resString) {
      var res = json.decode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        _usersNotCurrent = [];
        for (var i = 0; i < data['usersNotCurrent'].length; i++) {
          _usersNotCurrent.add(UserClass.fromJson(data['usersNotCurrent'][i]));
        }
        setState(() {
          _ambassadorsSignUpCompleteCount = data['ambassadorsSignUpCompleteCount'];
          _userInsights = _parseService.parseListMapStringDynamic(data['userInsights']);
          _currentAmbassadorsCount = data['currentAmbassadorsCount'];
          _usersNotCurrent = _usersNotCurrent;
        });
      }
    }));

    _socketService.emit('GetAmbassadorInsights', {});
  }

  @override
  void dispose() {
    _socketService.offRouteIds(_routeIds);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    List<Widget> colsAmbassadorSteps = [];
    List<String> stepsKeys = ['events', 'neighborhoodUName', 'locationSelect', 'userNeighborhoodSave'];
    for (var i = 0; i < _userInsights.length; i++) {
      String furthestStep = '';
      for (var j = 0; j < stepsKeys.length; j++) {
        if (_userInsights[i]['ambassadorSignUpStepsAt'].containsKey(stepsKeys[j])) {
          furthestStep = stepsKeys[j];
          break;
        }
      }
      Map<String, dynamic> user = _userInsights[i]['user'];
      colsAmbassadorSteps.add(
        Row(
          children: [
            Expanded(flex: 1, child: Text('${furthestStep}')),
            Expanded(flex: 1, child: Text('${user['username']}')),
            Expanded(flex: 1, child: Text('${user['email']}')),
          ]
        ),
      );
    }

    return AppScaffoldComponent(
      listWrapper: true,
      body: Column(
        children: [
          _style.Text1('Ambassador Insights (Last 30 Days)', size: 'large'),
          _style.SpacingH('medium'),
          _style.Text1('${_ambassadorsSignUpCompleteCount} ambassador sign ups complete'),
          _style.SpacingH('medium'),
          _style.Text1('${_userInsights.length} ambassadors sign ups INCOMPLETE'),
          _style.SpacingH('medium'),
          Row(
            children: [
              Expanded(flex: 1, child: Text('Furthest Step')),
              Expanded(flex: 1, child: Text('Username')),
              Expanded(flex: 1, child: Text('Email')),
            ]
          ),
          ...colsAmbassadorSteps,
          _style.SpacingH('xlarge'),

          _style.Text1('${_currentAmbassadorsCount} ambassadors are current'),
          _style.SpacingH('medium'),
          _style.Text1('${_usersNotCurrent.length} ambassadors are NOT current'),
          _style.SpacingH('medium'),
          ..._usersNotCurrent.map((UserClass user) {
            return Row(
              children: [
                Expanded(flex: 1, child: Text('${user.username}')),
                Expanded(flex: 1, child: Text('${user.email}')),
              ]
            );
          }),
        ]
      ) 
    );
  }
}