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
import './user_follow_up_class.dart';

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
  Map<String, List<String>> _followUpsBySignUp = {};
  Map<String, List<String>> _followUpsByBehind = {};
  Map<String, List<String>> _followUpsByNotStarted = {};

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

    _routeIds.add(_socketService.onRoute('UnsetAmbassadorSignUpSteps', callback: (String resString) {
      var res = json.decode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        _socketService.emit('GetAmbassadorInsights', {});
      }
    }));

    _routeIds.add(_socketService.onRoute('SearchUserFollowUp', callback: (String resString) {
      var res = json.decode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        SetUserFollowUps(data['userFollowUps']);
      }
    }));

    _socketService.emit('GetAmbassadorInsights', {});
  }

  void SetUserFollowUps(var userFollowUps) {
    for (var i = 0; i < userFollowUps.length; i++) {
      UserFollowUpClass userFollowUp = UserFollowUpClass.fromJson(userFollowUps[i]);
      if (userFollowUp.forType == 'ambassadorSignUp') {
        for (int j = 0; j < _userInsights.length; j++) {
          if (_userInsights[j]['username'] == userFollowUp.username) {
            String followUp = _dateTime.Format(userFollowUp.followUpAt, 'M/d/yy HH:mm');
            if (!_followUpsBySignUp.containsKey(userFollowUp.username)) {
              _followUpsBySignUp[userFollowUp.username] = [];
            }
            _followUpsBySignUp[userFollowUp.username]!.add(followUp);
            break;
          }
        }
      } else if (userFollowUp.forType == 'ambassadorUpdate') {
        for (var item in _userNeighborhoodWeeklyUpdatesBehindByUser.entries) {
          List<Map<String, dynamic>> updates = _parseService.parseListMapStringDynamic(item.value);
          String username = updates[0]['username'];
          // String neighborhoodUName = updates[0]['neighborhoodUName'];
          // String key = username + '_' + neighborhoodUName;
          String key = username;
          if (username == userFollowUp.username) {
            String followUp = _dateTime.Format(userFollowUp.followUpAt, 'M/d/yy HH:mm');
            if (!_followUpsByBehind.containsKey(key)) {
              _followUpsByBehind[key] = [];
            }
            _followUpsByBehind[key]!.add(followUp);
            break;
          }
        }

        for (int j = 0; j < _userNeighborhoodsNotStarted.length; j++) {
          String username = _userNeighborhoodsNotStarted[j].username;
          String neighborhoodUName = _userNeighborhoodsNotStarted[j].neighborhoodUName;
          String key = username + '_' + neighborhoodUName;
          if (username == userFollowUp.username && neighborhoodUName == userFollowUp.neighborhoodUName) {
            String followUp = _dateTime.Format(userFollowUp.followUpAt, 'M/d/yy HH:mm');
            if (!_followUpsByNotStarted.containsKey(key)) {
              _followUpsByNotStarted[key] = [];
            }
            _followUpsByNotStarted[key]!.add(followUp);
            break;
          }
        }
      }
    }
    setState(() {
      _followUpsBySignUp = _followUpsBySignUp;
      _followUpsByBehind = _followUpsByBehind;
      _followUpsByNotStarted = _followUpsByNotStarted;
    });
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

    var currentUserState = Provider.of<CurrentUserState>(context, listen: false);
    bool mayRemove = currentUserState.isLoggedIn && currentUserState.currentUser.roles.contains('editAmbassador') ? true : false;

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
      Widget rowRemove = SizedBox.shrink();
      if (mayRemove) {
        rowRemove = Expanded(flex: 1, child: TextButton(child: Text('Remove'), onPressed: () {
          _socketService.emit('UnsetAmbassadorSignUpSteps', { 'username': user['username'] });
        }));
      }
      Widget rowFollowUpsAt = Expanded(flex: 1, child: TextButton(child: Text('Follow Ups'), onPressed: () {
        var data = { 'username': user['username'], 'forType': 'ambassadorSignUp', };
        _socketService.emit('SearchUserFollowUp', data);
      }));
      if (_followUpsBySignUp.containsKey(user['username'])) {
        rowFollowUpsAt = Expanded(flex: 1, child: Text(_followUpsBySignUp[user['username']]!.join(', ')));
      }
      colsAmbassadorSteps.add(
        Row(
          children: [
            Expanded(flex: 1, child: Text('${furthestStep}')),
            Expanded(flex: 1, child: Text('${furthestStepAt}')),
            Expanded(flex: 1, child: Text('${user['username']}')),
            Expanded(flex: 1, child: Text('${user['email']}')),
            rowRemove,
            rowFollowUpsAt,
          ]
        ),
      );
    }

    List<Widget> colsBehind = [];
    for (var item in _userNeighborhoodWeeklyUpdatesBehindByUser.entries) {
      List<Map<String, dynamic>> updates = _parseService.parseListMapStringDynamic(item.value);
      String username = updates[0]['username'];

      Widget followUpsAt = TextButton(child: Text('Follow Ups'), onPressed: () {
        var data = { 'username': username, 'forType': 'ambassadorUpdate', };
        _socketService.emit('SearchUserFollowUp', data);
      });
      if (_followUpsByBehind.containsKey(username)) {
        followUpsAt = Text(_followUpsByBehind[username]!.join(', '));
      }

      colsBehind += [
        _buttons.LinkInline(context, username, '/u/${username}', launchUrl: true),
        followUpsAt,
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
              // Expanded(flex: 1, child: Text('${update['inviteCount']}')),
              // Expanded(flex: 1, child: Text('${update['attendedCount']}')),
              Expanded(flex: 1, child: Text('${update['actionsComplete'].join(',')}')),
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
              // Expanded(flex: 1, child: Text('Remove')),
              Expanded(flex: 1, child: Text('Follow Ups')),
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

            String key = userNeighborhood.username + '_' + userNeighborhood.neighborhoodUName;
            Widget followUpsAt = TextButton(child: Text('Follow Ups'), onPressed: () {
              var data = { 'username': userNeighborhood.username, 'forType': 'ambassadorUpdate',
                'neighborhoodUName': userNeighborhood.neighborhoodUName, };
              _socketService.emit('SearchUserFollowUp', data);
            });
            if (_followUpsByNotStarted.containsKey(key)) {
              followUpsAt = Text(_followUpsByNotStarted[key]!.join(', '));
            }
            return Row(
              children: [
                Expanded(flex: 1, child: _buttons.LinkInline(context, userNeighborhood.username, '/u/${userNeighborhood.username}', launchUrl: true)),
                Expanded(flex: 1, child: Text('${userNeighborhood.neighborhoodUName}')),
                ...colsRemove,
                followUpsAt,
              ]
            );
          }),
        ]
      ) 
    );
  }
}