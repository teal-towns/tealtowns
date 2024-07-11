import 'dart:convert';
import 'package:flutter/material.dart';

import '../../common/buttons.dart';
import '../../common/date_time_service.dart';
import '../../common/parse_service.dart';
import '../../common/socket_service.dart';
import '../../common/style.dart';
import '../../app_scaffold.dart';

class AppInsights extends StatefulWidget {
  @override
  _AppInsightsState createState() => _AppInsightsState();
}

class _AppInsightsState extends State<AppInsights> {
  Buttons _buttons = Buttons();
  DateTimeService _dateTime = DateTimeService();
  ParseService _parseService = ParseService();
  List<String> _routeIds = [];
  SocketService _socketService = SocketService();
  Style _style = Style();

  int _uniqueEventViews = 0;
  int _eventSignUps = 0;
  int _uniqueSignUpViews = 0;
  int _userSignUps = 0;
  int _uniqueAmbassadorSignUpViews = 0;
  int _ambassadorSignUps = 0;
  int _activeUsers = 0;
  int _totalUsers = 0;
  var _hoursToFirstAction = {
    'eventSignUp': -1.0,
    'neighborhoodJoin': -1.0,
  };
  List<Map<String, dynamic>> _coreMetricsWeeks = [];
  bool _loadingCoreMetrics = true;

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
          _uniqueAmbassadorSignUpViews = data['uniqueAmbassadorSignUpViews']; _ambassadorSignUps = data['ambassadorSignUps'];
          _activeUsers = data['activeUsers']; _totalUsers = data['totalUsers'];
          _hoursToFirstAction = _hoursToFirstAction;
        });
      }
    }));

    _routeIds.add(_socketService.onRoute('GetCoreMetrics', callback: (String resString) {
      var res = json.decode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        setState(() { _coreMetricsWeeks = _parseService.parseListMapStringDynamic(data['coreMetricsWeeks']);
          _loadingCoreMetrics = false; });
      }
    }));

    _socketService.emit('GetAppInsights', {});
    _socketService.emit('GetCoreMetrics', {'pastWeeksCount': 3});
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
    double ambassadorSignUpPercent = 100;
    if (_uniqueAmbassadorSignUpViews > 0) {
      ambassadorSignUpPercent = (_ambassadorSignUps / _uniqueAmbassadorSignUpViews) * 100;
    }
    double activeUserPercent = 100;
    if (_totalUsers > 0) {
      activeUserPercent = (_activeUsers / _totalUsers) * 100;
    }

    List<Widget> colsCoreMetrics = [];
    if (_loadingCoreMetrics) {
      colsCoreMetrics = [
        _style.SpacingH('medium'),
        Column( children: [ LinearProgressIndicator() ] )
      ];
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
          _style.Text1('Ambassador Sign Ups / Unique Ambassador Sign Up Views: ${ambassadorSignUpPercent.toStringAsFixed(2)}% (${_ambassadorSignUps} / ${_uniqueAmbassadorSignUpViews})'),
          _style.SpacingH('medium'),
          _style.Text1('Active / Total Users: ${activeUserPercent.toStringAsFixed(2)}% (${_activeUsers} / ${_totalUsers})'),
          _style.SpacingH('medium'),
          _style.Text1('Hours to First Action'),
          _style.SpacingH('medium'),
          _style.Text1('Event Sign Up: ${_hoursToFirstAction['eventSignUp']!.toStringAsFixed(2)}'),
          _style.SpacingH('medium'),
          _style.Text1('Neighborhood Join: ${_hoursToFirstAction['neighborhoodJoin']!.toStringAsFixed(2)}'),
          _style.SpacingH('xlarge'),
          _style.Text1('Core Metrics', size: 'large'),
          _style.SpacingH('medium'),
          Row(
            children: [
              Expanded(flex: 1, child: Text('Week Start')),
              Expanded(flex: 1, child: Text('New Neighborhoods')),
              Expanded(flex: 1, child: Text('Active Ambassadors')),
              Expanded(flex: 1, child: Text('New Invites')),
              Expanded(flex: 1, child: Text('New Joiner')),
              Expanded(flex: 1, child: Text('Bring a Friend')),
            ]
          ),
          ...colsCoreMetrics,
          ..._coreMetricsWeeks.map((Map<String, dynamic> coreMetricsWeek) {
            String newJoinPercent = coreMetricsWeek['newInvitesCount'] > 0 ?
              (coreMetricsWeek['newEventAttendees'].length / coreMetricsWeek['newInvitesCount'] * 100).toStringAsFixed(1) : '?';
            String bringAFriendPercent = coreMetricsWeek['uniqueEventInviterUsernames'].length > 0 ?
              (coreMetricsWeek['uniqueEventAttendeeUsernames'].length / coreMetricsWeek['uniqueEventInviterUsernames'].length * 100).toStringAsFixed(1) : '?';
            String activeAmbassadorsPercent = coreMetricsWeek['totalNeighborhoodsCount'] > 0 ?
              (coreMetricsWeek['activeNeighborhoodUNames'].length / coreMetricsWeek['totalNeighborhoodsCount'] * 100).toStringAsFixed(1) : '?';
            String start = _dateTime.Format(coreMetricsWeek['start'], 'yyyy-MM-dd');
            List<Widget> cols = [
              Row(
                children: [
                  Expanded(flex: 1, child: TextButton(child: Text('${start}'), onPressed: () {
                    if (!coreMetricsWeek.containsKey('expanded')) {
                      coreMetricsWeek['expanded'] = true;
                    } else {
                      coreMetricsWeek['expanded'] = !coreMetricsWeek['expanded'];
                    }
                    setState(() { _coreMetricsWeeks = _coreMetricsWeeks; });
                  })),
                  Expanded(flex: 1, child: Text('${coreMetricsWeek['newNeighborhoods'].length}')),
                  Expanded(flex: 1, child: Text('${activeAmbassadorsPercent}% (${coreMetricsWeek['activeNeighborhoodUNames'].length} / ${ coreMetricsWeek['totalNeighborhoodsCount']})')),
                  Expanded(flex: 1, child: Text('${coreMetricsWeek['newInvitesCount']}')),
                  Expanded(flex: 1, child: Text('${newJoinPercent}% (${coreMetricsWeek['newEventAttendees'].length} / ${coreMetricsWeek['newInvitesCount']})')),
                  Expanded(flex: 1, child: Text('${bringAFriendPercent}% (${coreMetricsWeek['uniqueEventAttendeeUsernames'].length} / ${coreMetricsWeek['uniqueEventInviterUsernames'].length})')),
                ]
              )
            ];
            if (coreMetricsWeek.containsKey('expanded') && coreMetricsWeek['expanded']) {
              List<Widget> rows = [
                Expanded(flex: 1, child: Container()),
              ];
              List<Widget> colsTemp = [];

              if (coreMetricsWeek['newNeighborhoods'].length == 0) {
                rows.add(Expanded(flex: 1, child: Container()));
              } else {
                for (int i = 0; i < coreMetricsWeek['newNeighborhoods'].length; i++) {
                  colsTemp.add(_buttons.LinkInline(context, coreMetricsWeek['newNeighborhoods'][i]['uName'], '/n/${coreMetricsWeek['newNeighborhoods'][i]['uName']}', launchUrl: false));
                }
                rows.add(Expanded(flex: 1, child: Column(children: colsTemp)));
              }

              if (coreMetricsWeek['activeNeighborhoodUNames'].length == 0) {
                rows.add(Expanded(flex: 1, child: Container()));
              } else {
                colsTemp = [];
                for (int i = 0; i < coreMetricsWeek['activeNeighborhoodUNames'].length; i++) {
                  colsTemp.add(_buttons.LinkInline(context, coreMetricsWeek['activeNeighborhoodUNames'][i], '/n/${coreMetricsWeek['activeNeighborhoodUNames'][i]}', launchUrl: false));
                }
                rows.add(Expanded(flex: 1, child: Column(children: colsTemp)));
              }

              // new invites - blank
              rows.add(Expanded(flex: 1, child: Container()));

              if (coreMetricsWeek['newEventAttendees'].length == 0) {
                rows.add(Expanded(flex: 1, child: Container()));
              } else {
                colsTemp = [];
                for (int i = 0; i < coreMetricsWeek['newEventAttendees'].length; i++) {
                  colsTemp.add(_buttons.LinkInline(context, coreMetricsWeek['newEventAttendees'][i]['username'], '/u/${coreMetricsWeek['newEventAttendees'][i]['username']}', launchUrl: false));
                }
                rows.add(Expanded(flex: 1, child: Column(children: colsTemp)));
              }

              if (coreMetricsWeek['uniqueEventInviterUsernames'].length == 0) {
                rows.add(Expanded(flex: 1, child: Container()));
              } else {
                colsTemp = [];
                for (int i = 0; i < coreMetricsWeek['uniqueEventInviterUsernames'].length; i++) {
                  colsTemp.add(_buttons.LinkInline(context, coreMetricsWeek['uniqueEventInviterUsernames'][i], '/u/${coreMetricsWeek['uniqueEventInviterUsernames'][i]}', launchUrl: true));
                }
                rows.add(Expanded(flex: 1, child: Column(children: colsTemp)));
              }

              cols.add(Row(children: rows));
            }
            return Column(
              children: cols
            );
          }),
          _style.SpacingH('xlarge'),
          _buttons.Link(context, 'Ambassador Insights', '/ambassador-insights'),
          _style.SpacingH('medium'),
          _buttons.Link(context, 'Neighborhood Insights', '/neighborhood-insights'),
          _style.SpacingH('medium'),
          _buttons.Link(context, 'Weekly Events Search', '/weekly-events-search'),
          _style.SpacingH('medium'),
        ]
      ) 
    );
  }
}