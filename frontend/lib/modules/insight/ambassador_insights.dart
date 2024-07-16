import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/buttons.dart';
import '../../common/date_time_service.dart';
import '../../common/parse_service.dart';
import '../../common/socket_service.dart';
import '../../common/style.dart';
import '../../app_scaffold.dart';
import '../neighborhood/user_neighborhood_class.dart';
// import '../user_auth/user_class.dart';
import '../user_auth/current_user_state.dart';

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

  List<String> _ambassadorsSignUpCompleteUsernames = [];
  List<Map<String, dynamic>> _userInsights = [];
  List<String> _onTrackAmbassadorUsernames = [];
  Map<String, dynamic> _userNeighborhoodWeeklyUpdatesBehindByUser = {};
  List<UserNeighborhoodClass> _userNeighborhoodsNotStarted = [];
  bool _loading = true;
  bool _showOnTrack = false;
  bool _showSignUpComplete = false;

  @override
  void initState() {
    super.initState();

    _routeIds.add(_socketService.onRoute('GetAmbassadorInsights', callback: (String resString) {
      var res = json.decode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        _userNeighborhoodsNotStarted = [];
        for (var i = 0; i < data['userNeighborhoodsNotStarted'].length; i++) {
          _userNeighborhoodsNotStarted.add(UserNeighborhoodClass.fromJson(data['userNeighborhoodsNotStarted'][i]));
        }
        setState(() {
          _ambassadorsSignUpCompleteUsernames = _parseService.parseListString(data['ambassadorsSignUpCompleteUsernames']);
          _userInsights = _parseService.parseListMapStringDynamic(data['userInsights']);
          _onTrackAmbassadorUsernames = _parseService.parseListString(data['onTrackAmbassadorUsernames']);
          _userNeighborhoodWeeklyUpdatesBehindByUser = _parseService.parseMapStringDynamic(data['userNeighborhoodWeeklyUpdatesBehindByUser']);
          _userNeighborhoodsNotStarted = _userNeighborhoodsNotStarted;
          _loading = false;
        });
      }
    }));

    _routeIds.add(_socketService.onRoute('RemoveUserNeighborhoodRole', callback: (String resString) {
      var res = json.decode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        _socketService.emit('GetAmbassadorInsights', {});
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
    if (_loading) {
      return AppScaffoldComponent(
        listWrapper: true,
        body: Column( children: [ LinearProgressIndicator() ] ),
      );
    }

    List<Widget> colsAmbassadorSteps = [];
    List<String> stepsKeys = ['events', 'neighborhoodUName', 'locationSelect', 'userNeighborhoodSave'];
    for (var i = 0; i < _userInsights.length; i++) {
      String furthestStep = '';
      String furthestStepAt = '';
      for (var j = 0; j < stepsKeys.length; j++) {
        if (_userInsights[i]['ambassadorSignUpStepsAt'].containsKey(stepsKeys[j])) {
          furthestStep = stepsKeys[j];
          furthestStepAt = _dateTime.Format(_userInsights[i]['ambassadorSignUpStepsAt'][stepsKeys[j]], 'yyyy-MM-dd HH:mm');
          break;
        }
      }
      Map<String, dynamic> user = _userInsights[i]['user'];
      colsAmbassadorSteps.add(
        Row(
          children: [
            Expanded(flex: 1, child: Text('${furthestStep}')),
            Expanded(flex: 1, child: Text('${furthestStepAt}')),
            Expanded(flex: 1, child: Text('${user['username']}')),
            Expanded(flex: 1, child: Text('${user['email']}')),
          ]
        ),
      );
    }

    List<Widget> colsBehind = [];
    var currentUserState = Provider.of<CurrentUserState>(context, listen: false);
    bool mayRemove = currentUserState.isLoggedIn && currentUserState.currentUser.roles.contains('editAmbassador') ? true : false;
    for (var item in _userNeighborhoodWeeklyUpdatesBehindByUser.entries) {
      List<Map<String, dynamic>> updates = _parseService.parseListMapStringDynamic(item.value);
      String username = updates[0]['username'];
      colsBehind += [
        _buttons.LinkInline(context, username, '/u/${username}', launchUrl: true),
        Row(
          children: [
            Expanded(flex: 1, child: Text('Week')),
            Expanded(flex: 1, child: Text('Neighborhood')),
            Expanded(flex: 1, child: Text('Invites')),
            Expanded(flex: 1, child: Text('Attended')),
          ]
        ),
        ...updates.map((Map<String, dynamic> update) {
          String start = _dateTime.Format(update['start'], 'y/M/d');
          String end = _dateTime.Format(update['end'], 'y/M/d');
          Widget neighborhood = Text('${update['neighborhoodUName']}');
          if (mayRemove) {
            neighborhood = Row(
              children: [
                Text('${update['neighborhoodUName']}'),
                TextButton(child: Text('Remove Ambassador'), onPressed: () {
                  var data = { 'username': username, 'neighborhoodUName': update['neighborhoodUName'],
                    'role': 'ambassador', };
                  _socketService.emit('RemoveUserNeighborhoodRole', data);
                }),
              ]
            );
          }
          return Row(
            children: [
              Expanded(flex: 1, child: Text('${start} - ${end}')),
              Expanded(flex: 1, child: neighborhood),
              Expanded(flex: 1, child: Text('${update['inviteCount']}')),
              Expanded(flex: 1, child: Text('${update['attendedCount']}')),
            ]
          );
        }),
      ];
    }

    List<Widget> colsSignUpComplete = [];
    if (_showSignUpComplete) {
      colsSignUpComplete = [
        ..._ambassadorsSignUpCompleteUsernames.map((username) => _buttons.LinkInline(context, username, '/u/${username}', launchUrl: true)),
        _style.SpacingH('medium'),
      ];
    }

    List<Widget> colsOnTrack = [];
    if (_showOnTrack) {
      colsOnTrack = [
        ..._onTrackAmbassadorUsernames.map((username) => _buttons.LinkInline(context, username, '/u/${username}', launchUrl: true)),
        _style.SpacingH('medium'),
      ];
    }

    return AppScaffoldComponent(
      listWrapper: true,
      body: Column(
        children: [
          _style.Text1('Ambassador Insights (Last 30 Days)', size: 'large'),
          _style.SpacingH('medium'),
          TextButton(child: Text('${_ambassadorsSignUpCompleteUsernames.length} ambassador sign ups complete'), onPressed: () {
            setState(() { _showSignUpComplete = !_showSignUpComplete; });
          }),
          _style.SpacingH('medium'),
          ...colsSignUpComplete,
          _style.Text1('${_userInsights.length} ambassadors sign ups INCOMPLETE'),
          _style.SpacingH('medium'),
          Row(
            children: [
              Expanded(flex: 1, child: Text('Furthest Step')),
              Expanded(flex: 1, child: Text('Furthest Step At')),
              Expanded(flex: 1, child: Text('Username')),
              Expanded(flex: 1, child: Text('Email')),
            ]
          ),
          ...colsAmbassadorSteps,
          _style.SpacingH('xlarge'),

          TextButton(child: Text('${_onTrackAmbassadorUsernames.length} ambassadors on track'), onPressed: () {
            setState(() { _showOnTrack = !_showOnTrack; });
          }),
          _style.SpacingH('medium'),
          ...colsOnTrack,
          _style.Text1('${_userNeighborhoodWeeklyUpdatesBehindByUser.length} ambassadors BEHIND'),
          _style.SpacingH('medium'),
          ...colsBehind,
          _style.SpacingH('medium'),
          _style.Text1('${_userNeighborhoodsNotStarted.length} ambassadors NOT STARTED (no updates yet)'),
          _style.SpacingH('medium'),
          ..._userNeighborhoodsNotStarted.map((UserNeighborhoodClass userNeighborhood) {
            List<Widget> colsRemove = [];
            if (mayRemove) {
              colsRemove = [
                TextButton(child: Text('Remove Ambassador'), onPressed: () {
                  var data = { 'username': userNeighborhood.username, 'neighborhoodUName': userNeighborhood.neighborhoodUName,
                    'role': 'ambassador', };
                  _socketService.emit('RemoveUserNeighborhoodRole', data);
                }),
              ];
            }
            return Row(
              children: [
                Expanded(flex: 1, child: _buttons.LinkInline(context, userNeighborhood.username, '/u/${userNeighborhood.username}', launchUrl: true)),
                Expanded(flex: 1, child: Text('${userNeighborhood.neighborhoodUName}')),
                ...colsRemove,
              ]
            );
          }),
        ]
      ) 
    );
  }
}